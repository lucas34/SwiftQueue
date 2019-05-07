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

/// Global manager to perform operations on all your queues/
/// You will have to keep this instance. We highly recommend you to store this instance in a Singleton
/// Creating and instance of this class will automatically un-serialize your jobs and schedule them
public final class SwiftQueueManager {

    private let jobCreator: JobCreator
    private let queueCreator: QueueCreator
    private let persister: JobPersister
    private let serializer: JobInfoSerializer

    internal let logger: SwiftQueueLogger
    internal let listener: JobListener?

    /// Allow jobs in queue to be executed.
    public var isSuspended: Bool {
        didSet {
            for element in manage.values {
                element.isSuspended = isSuspended
            }
        }
    }

    private var manage = [String: SqOperationQueue]()

    internal init(params: SqManagerParams) {
        self.jobCreator = params.jobCreator
        self.queueCreator = params.queueCreator
        self.persister = params.persister
        self.serializer = params.serializer
        self.logger = params.logger
        self.listener = params.listener
        self.isSuspended = params.isSuspended

        for queueName in persister.restore() {
            _ = createQueue(queueName: queueName, initInBackground: params.initInBackground)
        }
    }

    internal func getQueue(queueName: String) -> SqOperationQueue {
        return manage[queueName] ?? createQueue(queueName: queueName, initInBackground: false)
    }

    private func createQueue(queueName: String, initInBackground: Bool) -> SqOperationQueue {
        let operationQueue = SqOperationQueue(queueCreator.create(queueName: queueName), jobCreator, persister, serializer, isSuspended, initInBackground, logger, listener)
        manage[queueName] = operationQueue
        return operationQueue
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

internal class SqManagerParams {

    let jobCreator: JobCreator

    let queueCreator: QueueCreator

    var persister: JobPersister

    var serializer: JobInfoSerializer

    var logger: SwiftQueueLogger

    var listener: JobListener?

    var isSuspended: Bool

    var initInBackground: Bool

    init(jobCreator: JobCreator,
         queueCreator: QueueCreator,
         persister: JobPersister = UserDefaultsPersister(),
         serializer: JobInfoSerializer = DecodableSerializer(),
         logger: SwiftQueueLogger = NoLogger.shared,
         listener: JobListener? = nil,
         isSuspended: Bool = false,
         initInBackground: Bool = false) {

        self.jobCreator = jobCreator
        self.queueCreator = queueCreator
        self.persister = persister
        self.serializer = serializer
        self.logger = logger
        self.listener = listener
        self.isSuspended = isSuspended
        self.initInBackground = initInBackground
    }

}

/// Entry point to create a `SwiftQueueManager`
public final class SwiftQueueManagerBuilder {

    private var params: SqManagerParams

    /// Creator to convert `JobInfo.type` to `Job` instance
    public init(creator: JobCreator, queueCreator: QueueCreator = BasicQueueCreator()) {
        params = SqManagerParams(jobCreator: creator, queueCreator: queueCreator)
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
        params.isSuspended = isSuspended
        return self
    }

    /// Deserialize jobs synchronously after creating the `SwiftQueueManager` instance. `true` by default
    @available(*, deprecated, renamed: "initInBackground")
    public func set(synchronous: Bool) -> Self {
        params.initInBackground = !synchronous
        return self
    }

    /// Deserialize jobs synchronously after creating the `SwiftQueueManager` instance. `true` by default
    public func set(initInBackground: Bool) -> Self {
        params.initInBackground = initInBackground
        return self
    }

    /// Listen for job
    public func set(listener: JobListener) -> Self {
        params.listener = listener
        return self
    }

    /// Get an instance of `SwiftQueueManager`
    public func build() -> SwiftQueueManager {
        return SwiftQueueManager(params: params)
    }

}
