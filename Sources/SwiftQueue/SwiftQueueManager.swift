//
// Created by Lucas Nelaupe on 18/8/17.
// Copyright (c) 2017 Lucas Nelaupe. All rights reserved.
//

import Foundation

/// Global manager to perform operations on all your queues/
/// You will have to keep this instance. We highly recommend you to store this instance in a Singleton
/// Creating and instance of this class will automatically un-serialize your jobs and schedule them
public final class SwiftQueueManager {

    private let creator: JobCreator
    private let persister: JobPersister
    private let serializer: JobInfoSerializer

    internal let logger: SwiftQueueLogger

    private var isPaused: Bool

    private var manage = [String: SqOperationQueue]()

    /// Create a new QueueManager with creators to instantiate Job
    /// Synchronous indicate that serialized task will be added synchronously.
    /// This can be a time consuming operation.
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

    var serializer: JobInfoSerializer

    var logger: SwiftQueueLogger

    var isPaused: Bool

    var synchronous: Bool

    init(creator: JobCreator,
         persister: JobPersister = UserDefaultsPersister(),
         serializer: JobInfoSerializer = DecodableSerializer(),
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

public final class SwiftQueueManagerBuilder {

    private var params: SqManagerParams

    public init(creator: JobCreator) {
        params = SqManagerParams(creator: creator)
    }

    func set(persister: JobPersister) -> Self {
        params.persister = persister
        return self
    }

    func set(serializer: JobInfoSerializer) -> Self {
        params.serializer = serializer
        return self
    }

    func set(logger: SwiftQueueLogger) -> Self {
        params.logger = logger
        return self
    }

    func set(isPaused: Bool) -> Self {
        params.isPaused = isPaused
        return self
    }

    func set(synchronous: Bool) -> Self {
        params.synchronous = synchronous
        return self
    }

    func build() -> SwiftQueueManager {
        return SwiftQueueManager(params: params)

    }

}