// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import Foundation

internal final class SqOperation: Operation {

    let handler: Job

    var info: JobInfo

    let constraints: [JobConstraint]

    var lastError: Swift.Error?

    let logger: SwiftQueueLogger

    let listener: JobListener?

    override var name: String? { get { return info.uuid } set { } }

    private var jobIsExecuting: Bool = false
    override var isExecuting: Bool {
        get { return jobIsExecuting }
        set {
            willChangeValue(forKey: "isExecuting")
            jobIsExecuting = newValue
            didChangeValue(forKey: "isExecuting")
        }
    }

    private var jobIsFinished: Bool = false
    override var isFinished: Bool {
        get { return jobIsFinished }
        set {
            willChangeValue(forKey: "isFinished")
            jobIsFinished = newValue
            didChangeValue(forKey: "isFinished")
        }
    }

    internal init(job: Job, info: JobInfo, logger: SwiftQueueLogger, listener: JobListener?) {
        self.handler = job
        self.info = info
        self.logger = logger
        self.listener = listener

        self.constraints = [
            DeadlineConstraint(),
            DelayConstraint(),
            UniqueUUIDConstraint(),
            NetworkConstraint(),
            BatteryChargingConstraint()
        ]

        super.init()

        self.queuePriority = .normal
        self.qualityOfService = .utility

    }

    override func start() {
        super.start()
        logger.log(.verbose, jobId: info.uuid, message: "Job has been started by the system")
        isExecuting = true
        run()
    }

    override func cancel() {
        self.cancel(with: SwiftQueueError.canceled)
    }

    func cancel(with: Swift.Error) {
        logger.log(.verbose, jobId: info.uuid, message: "Job has been canceled")
        lastError = with
        onTerminate()
        super.cancel()
    }

    func onTerminate() {
        logger.log(.verbose, jobId: info.uuid, message: "Job will not run anymore")
        if isExecuting {
            isFinished = true
        }
    }

    // cancel before schedule and serialize
    internal func abort(error: Swift.Error) {
        logger.log(.verbose, jobId: info.uuid, message: "Job has not been scheduled due to \(error.localizedDescription)")
        lastError = error
        // Need to be called manually since the task is actually not in the queue. So cannot call cancel()
        handler.onRemove(result: .fail(error))
        listener?.onTerminated(job: info, result: .fail(error))
    }

    internal func run() {
        if isCancelled && !isFinished {
            isFinished = true
        }
        if isFinished {
            return
        }

        do {
            try self.willRunJob()
        } catch let error {
            logger.log(.warning, jobId: info.uuid, message: "Job cannot run due to \(error.localizedDescription)")
            // Will never run again
            cancel(with: error)
            return
        }

        guard self.checkIfJobCanRunNow() else {
            // Constraint fail.
            // Constraint will call run when it's ready
            logger.log(.verbose, jobId: info.uuid, message: "Job cannot run now. Execution is postponed")
            return
        }

        logger.log(.verbose, jobId: info.uuid, message: "Job is running")
        listener?.onBeforeRun(job: info)
        handler.onRun(callback: self)
    }

    internal func remove() {
        let result = lastError.map(JobCompletion.fail) ?? JobCompletion.success
        logger.log(.verbose, jobId: info.uuid, message: "Job is removed from the queue result=\(result)")
        handler.onRemove(result: result)
        listener?.onTerminated(job: info, result: result)
    }

}

extension SqOperation: JobResult {

    func done(_ result: JobCompletion) {
        guard !isFinished else { return }

        listener?.onAfterRun(job: info, result: result)

        switch result {
        case .success:
            completionSuccess()
        case .fail(let error):
            completionFail(error: error)
        }
    }

    private func completionFail(error: Swift.Error) {
        logger.log(.warning, jobId: info.uuid, message: "Job completed with error \(error.localizedDescription)")
        lastError = error

        switch info.retries {
        case .limited(let value):
            if value > 0 {
                retryJob(retry: handler.onRetry(error: error), origin: error)
            } else {
                onTerminate()
            }
        case .unlimited:
            retryJob(retry: handler.onRetry(error: error), origin: error)
        }
    }

    private func retryJob(retry: RetryConstraint, origin: Error) {

        func exponentialBackoff(initial: TimeInterval) -> TimeInterval {
            info.currentRepetition += 1
            return info.currentRepetition == 1 ? initial : initial * pow(2, Double(info.currentRepetition - 1))
        }

        switch retry {
        case .cancel:
            lastError = SwiftQueueError.onRetryCancel(origin)
            onTerminate()
        case .retry(let after):
            guard after > 0 else {
                // Retry immediately
                info.retries.decreaseValue(by: 1)
                self.run()
                return
            }

            // Retry after time in parameter
            retryInBackgroundAfter(after)
        case .exponential(let initial):
            retryInBackgroundAfter(exponentialBackoff(initial: initial))
        case .exponentialWithLimit(let initial, let maxDelay):
            retryInBackgroundAfter(min(maxDelay, exponentialBackoff(initial: initial)))
        }
    }

    private func completionSuccess() {
        logger.log(.verbose, jobId: info.uuid, message: "Job completed successfully")
        lastError = nil
        info.currentRepetition = 0

        if case .limited(let limit) = info.maxRun {
            // Reached run limit
            guard info.runCount + 1 < limit else {
                onTerminate()
                return
            }
        }

        guard info.interval > 0 else {
            // Run immediately
            info.runCount += 1
            self.run()
            return
        }

        // Schedule run after interval
        runInBackgroundAfter(info.interval, callback: { [weak self] in
            self?.info.runCount += 1
            self?.run()
        })
    }

}

extension SqOperation {

    func willScheduleJob(queue: SqOperationQueue) throws {
        for constraint in self.constraints {
            try constraint.willSchedule(queue: queue, operation: self)
        }
    }

    func willRunJob() throws {
        for constraint in self.constraints {
            try constraint.willRun(operation: self)
        }
    }

    func checkIfJobCanRunNow() -> Bool {
        for constraint in self.constraints where constraint.run(operation: self) == false {
            return false
        }
        return true
    }

}

extension SqOperation {

    fileprivate func retryInBackgroundAfter(_ delay: TimeInterval) {
        runInBackgroundAfter(delay) { [weak self] in
            self?.info.retries.decreaseValue(by: 1)
            self?.run()
        }
    }

}
