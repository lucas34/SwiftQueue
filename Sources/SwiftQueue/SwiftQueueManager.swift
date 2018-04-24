//
// Created by Lucas Nelaupe on 18/8/17.
// Copyright (c) 2017 Lucas Nelaupe. All rights reserved.
//

import Foundation

/// Global manager to perform operations on all your queues/
/// You will have to keep this instance. We highly recommend you to store this instance in a Singleton
/// Creating and instance of this class will automatically un-serialise your jobs and schedule them
public final class SwiftQueueManager {

    private let creator: JobCreator
    private let persister: JobPersister
    private let serializer: JobInfoSerialiser

    internal let logger: SwiftQueueLogger

    private var isPaused: Bool

    private var manage = [String: SqOperationQueue]()

    internal init(params: SqManagerParams) {
        self.creator = params.creator
        self.persister = params.persister
        self.serializer = params.serializer
        self.logger = params.logger
        self.isPaused = params.isPaused

        for queueName in persister.restore() {
            manage[queueName] = SqOperationQueue(queueName, creator, persister, serializer, isPaused, params.synchronous, logger)
        }
    }

    /// Jobs queued will run again
    public func start() {
        isPaused = false
        for element in manage.values {
            element.isSuspended = false
        }
    }

    /// Avoid new job to run. Not application for current running job.
    public func pause() {
        isPaused = true
        for element in manage.values {
            element.isSuspended = true
        }
    }

    internal func getQueue(queueName: String) -> SqOperationQueue {
        return manage[queueName] ?? createQueue(queueName: queueName)
    }

    private func createQueue(queueName: String) -> SqOperationQueue {
        // At this point the queue should be totally new so it's safe to start the queue synchronously
        let queue = SqOperationQueue(queueName, creator, persister, serializer, isPaused, true, logger)
        manage[queueName] = queue
        return queue
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

}

internal class SqManagerParams {

    let creator: JobCreator

    var persister: JobPersister

    var serializer: JobInfoSerialiser

    var logger: SwiftQueueLogger

    var isPaused: Bool

    var synchronous: Bool

    init(creator: JobCreator,
         persister: JobPersister = UserDefaultsPersister(),
         serializer: JobInfoSerialiser = DecodableSerializer(),
         logger: SwiftQueueLogger = NoLogger.shared,
         isPaused: Bool = false,
         synchronous: Bool = true) {

        self.creator = creator
        self.persister = persister
        self.serializer = serializer
        self.logger = logger
        self.isPaused = isPaused
        self.synchronous = synchronous
    }

}

/// Entry point to create a `SwiftQueueManager`
public final class SwiftQueueManagerBuilder {

    private var params: SqManagerParams

    /// Creator to convert `JobInfo.type` to `Job` instance
    public init(creator: JobCreator) {
        params = SqManagerParams(creator: creator)
    }

    /// Custom way of saving `JobInfo`. Will use `UserDefaultsPersister` by default
    func set(persister: JobPersister) -> Self {
        params.persister = persister
        return self
    }

    /// Custom way of serializing `JobInfo`. Will use `DecodableSerializer` by default
    func set(serializer: JobInfoSerialiser) -> Self {
        params.serializer = serializer
        return self
    }

    /// Internal event logger. `NoLogger` by default
    /// Use `ConsoleLogger` to print to the console. This is not recommended since the print is synchronous
    /// and it can be and expensive operation. Prefer using a asynchronous logger like `SwiftyBeaver`.
    func set(logger: SwiftQueueLogger) -> Self {
        params.logger = logger
        return self
    }

    /// Start jobs directly when they are scheduled or not. `false` by default
    func set(isPaused: Bool) -> Self {
        params.isPaused = isPaused
        return self
    }

    /// Deserialize jobs synchronously after creating the `SwiftQueueManager` instance. `true` by default
    func set(synchronous: Bool) -> Self {
        params.synchronous = synchronous
        return self
    }

    /// Get an instance of `SwiftQueueManager`
    func build() -> SwiftQueueManager {
        return SwiftQueueManager(params: params)

    }

}