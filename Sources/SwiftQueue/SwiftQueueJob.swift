//
// Created by Lucas Nelaupe on 10/08/2017.
// Copyright (c) 2017 lucas34. All rights reserved.
//

import Foundation

internal final class SwiftQueueJob: Operation, JobResult {

    let handler: Job
    var info: JobInfo

    let constraints: [JobConstraint]

    var lastError: Swift.Error?

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

    internal init(job: Job, info: JobInfo) {
        self.handler = job
        self.info = info

        self.constraints = [
            DeadlineConstraint(),
            DelayConstraint(),
            UniqueUUIDConstraint(),
            NetworkConstraint()
        ]

        super.init()

        self.queuePriority = .normal
        self.qualityOfService = .utility

    }

    override func start() {
        super.start()
        isExecuting = true
        run()
    }

    override func cancel() {
        lastError = Canceled()
        onTerminate()
        super.cancel()
    }

    private func onTerminate() {
        if isExecuting {
            isFinished = true
        }
    }

    // cancel before schedule and serialise
    internal func abort(error: Swift.Error) {
        lastError = error
        // Need to be called manually since the task is actually not in the queue. So cannot call cancel()
        handler.onRemove(result: .fail(error))
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
            // Will never run again
            lastError = error
            onTerminate()
        }

        guard self.checkIfJobCanRunNow() else {
            // Constraint fail.
            // Constraint will call run when it's ready
            return
        }

        handler.onRun(callback: self)
    }

    internal func remove() {
        let result = lastError.map(JobCompletion.fail) ?? JobCompletion.success
        handler.onRemove(result: result)
    }

    func done(_ result: JobCompletion) {
        switch result {
        case .success:
            completionSuccess()
        case .fail(let error):
            completionFail(error: error)
        }
    }

    private func completionFail(error: Swift.Error) {
        lastError = error

        switch info.retries {
        case .limited(let value):
            if value > 0 {
                retryJob(retry: handler.onRetry(error: error))
            } else {
                onTerminate()
            }
            break
        case .unlimited:
            retryJob(retry: handler.onRetry(error: error))
        }
    }

    private func retryJob(retry: RetryConstraint) {
        switch retry {
        case .cancel:
            cancel()
        case .retry(let after):
            guard after > 0 else {
                // Retry immediately
                info.retries.decreaseValue(by: 1)
                self.run()
                return
            }

            // Retry after time in parameter
            runInBackgroundAfter(after) { [weak self] in
                self?.info.retries.decreaseValue(by: 1)
                self?.run()
            }
        case .exponential(let initial):
            info.currentRepetition += 1
            let delay = info.currentRepetition == 1 ? initial : initial * pow(2, Double(info.currentRepetition - 1))
            runInBackgroundAfter(delay) { [weak self] in
                self?.info.retries.decreaseValue(by: 1)
                self?.run()
            }
        }
    }

    private func completionSuccess() {
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

extension SwiftQueueJob {

    convenience init?(dictionary: [String: Any], creator: [JobCreator]) {
        guard let info = try? JobInfo(dictionary: dictionary) else {
            assertionFailure("Unable to un-serialise job")
            return nil
        }

        guard let job = SwiftQueue.createHandler(creators: creator, type: info!.type, params: info!.params) else {
            return nil
        }

        self.init(job: job, info: info!)
    }

    convenience init?(json: String, creator: [JobCreator]) {
        let dict = fromJSON(json) as? [String: Any] ?? [:]
        self.init(dictionary: dict, creator: creator)
    }

    func toJSONString() -> String? {
        return toJSON(info.toDictionary())
    }

}

extension SwiftQueueJob {

    func willScheduleJob(queue: SwiftQueue) throws {
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
        for constraint in self.constraints {
            if !constraint.run(operation: self) {
                return false
            }
        }
        return true
    }

}
