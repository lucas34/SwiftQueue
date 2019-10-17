// The MIT License (MIT)
//
// Copyright (c) 2017 Lucas Nelaupe
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import Dispatch

/// Global manager to perform operations on all your queues/
/// You will have to keep this instance. We highly recommend you to store this instance in a Singleton
/// Creating and instance of this class will automatically un-serialize your jobs and schedule them
public final class SwiftQueueManager {

    internal let params: SqManagerParams

    /// Allow jobs in queue to be executed.
    public var isSuspended: Bool {
        didSet {
            for element in manage.values {
                element.isSuspended = isSuspended
            }
        }
    }

    private var manage = [String: SqOperationQueue]()

    internal init(params: SqManagerParams, isSuspended: Bool) {
        self.params = params
        self.isSuspended = isSuspended

        for queueName in params.persister.restore() {
            _ = createQueue(queueName: queueName, initInBackground: params.initInBackground)
        }
    }

    internal func getQueue(queueName: String) -> SqOperationQueue {
        return manage[queueName] ?? createQueue(queueName: queueName, initInBackground: false)
    }

    private func createQueue(queueName: String, initInBackground: Bool) -> SqOperationQueue {
        let operationQueue = SqOperationQueue(params, params.queueCreator.create(queueName: queueName), isSuspended)
        manage[queueName] = operationQueue
        return operationQueue
    }

    /// Schedule a job to the queue
    public func enqueue(info: JobInfo) {
        let queue = getQueue(queueName: info.queueName)
        let job = queue.createHandler(type: info.type, params: info.params)

        let operation = SqOperation(job: job,
                info: info,
                logger: params.logger,
                listener: params.listener,
                dispatchQueue: params.dispatchQueue
        )

        queue.addOperation(operation)
    }

    /// All operations persisted in all queues will be removed
    public func removeAllPersistedOperations() {
        for element in manage.values {
            guard let queueName = element.name else {
                continue
            }

            let queue = getQueue(queueName: queueName)
            queue.removePersistedJobs()
        }
    }

    /// All operations in all queues will be removed
    public func cancelAllOperations() {
        for element in manage.values {
            element.cancelAllOperations()
        }
    }

    /// All operations with this tag in all queues will be removed
    public func cancelOperations(tag: String) {
        assertNotEmptyString(tag)
        for element in manage.values {
            element.cancelOperations(tag: tag)
        }
    }

    /// All operations with this uuid in all queues will be removed
    public func cancelOperations(uuid: String) {
        assertNotEmptyString(uuid)
        for element in manage.values {
            element.cancelOperations(uuid: uuid)
        }
    }

    /// Blocks the current thread until all of the receiver’s queued and executing operations finish executing.
    public func waitUntilAllOperationsAreFinished() {
        for element in manage.values {
            element.waitUntilAllOperationsAreFinished()
        }
    }

    /// number of queue
    public func queueCount() -> Int {
        return manage.values.count
    }

    /// number of jobs for all queues
    public func jobCount() -> Int {
        var count = 0
        for element in manage.values {
            count += element.operationCount
        }
        return count
    }
}

internal extension SwiftQueueManager {

    func getAllAllowBackgroundOperation() -> [SqOperation] {
        return manage.values
                .flatMap { $0.operations }
                .compactMap { $0 as? SqOperation }
                .filter { $0.info.executor.rawValue > 0 }
    }

    func getOperation(forUUID: String) -> SqOperation? {
        for queue: SqOperationQueue in manage.values {
            for operation in queue.operations where operation.name == forUUID {
                return operation as? SqOperation
            }
        }
        return nil
    }
}

internal struct SqManagerParams {

    let jobCreator: JobCreator

    let queueCreator: QueueCreator

    var persister: JobPersister

    var serializer: JobInfoSerializer

    var logger: SwiftQueueLogger

    var listener: [JobListener]? = []

    var dispatchQueue: DispatchQueue

    var initInBackground: Bool

    init(jobCreator: JobCreator,
         queueCreator: QueueCreator,
         persister: JobPersister = UserDefaultsPersister(),
         serializer: JobInfoSerializer = DecodableSerializer(),
         logger: SwiftQueueLogger = NoLogger.shared,
         listener: [JobListener]? = [],
         initInBackground: Bool = false,
         dispatchQueue: DispatchQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.utility)
    ) {
        self.jobCreator = jobCreator
        self.queueCreator = queueCreator
        self.persister = persister
        self.serializer = serializer
        self.logger = logger
        self.listener = listener
        self.initInBackground = initInBackground
        self.dispatchQueue = dispatchQueue
    }

}

/// Entry point to create a `SwiftQueueManager`
public final class SwiftQueueManagerBuilder {

    private var params: SqManagerParams
    private var isSuspended: Bool = false

    /// Creator to convert `JobInfo.type` to `Job` instance
    public init(creator: JobCreator, queueCreator: QueueCreator = BasicQueueCreator()) {
        params = SqManagerParams(jobCreator: creator, queueCreator: queueCreator, listener: [])
    }

    /// Custom way of saving `JobInfo`. Will use `UserDefaultsPersister` by default
    public func set(persister: JobPersister) -> Self {
        params.persister = persister
        return self
    }

    /// Custom way of serializing `JobInfo`. Will use `DecodableSerializer` by default
    public func set(serializer: JobInfoSerializer) -> Self {
        params.serializer = serializer
        return self
    }

    /// Internal event logger. `NoLogger` by default
    /// Use `ConsoleLogger` to print to the console. This is not recommended since the print is synchronous
    /// and it can be and expensive operation. Prefer using a asynchronous logger like `SwiftyBeaver`.
    public func set(logger: SwiftQueueLogger) -> Self {
        params.logger = logger
        return self
    }

    /// Start jobs directly when they are scheduled or not. `false` by default
    public func set(isSuspended: Bool) -> Self {
        self.isSuspended = isSuspended
        return self
    }

    /// Deserialize jobs synchronously after creating the `SwiftQueueManager` instance. `true` by default
    public func set(initInBackground: Bool) -> Self {
        params.initInBackground = initInBackground
        return self
    }

    /// Listen for job
    public func append(listener: JobListener) -> Self {
        params.listener?.append(listener)
        return self
    }

    public func set(dispatchQueue: DispatchQueue) -> Self {
        params.dispatchQueue = dispatchQueue
        return self
    }

    /// Get an instance of `SwiftQueueManager`
    public func build() -> SwiftQueueManager {
        return SwiftQueueManager(params: params, isSuspended: isSuspended)
    }

}
