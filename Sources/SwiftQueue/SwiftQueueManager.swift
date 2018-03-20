//
// Created by Lucas Nelaupe on 18/8/17.
// Copyright (c) 2017 Lucas Nelaupe. All rights reserved.
//

import Foundation

/// Global manager to perform operations on all your queues/
/// You will have to keep this instance. We highly recommend you to store this instance in a Singleton
/// Creating and instance of this class will automatically un-serialise your jobs and schedule them 
public final class SwiftQueueManager {

    private let creators: [JobCreator]
    private let persister: JobPersister?

    private var manage = [String: SqOperationQueue]()

    private var isPaused = true

    /// Create a new QueueManager with creators to instantiate Job
    public init(creators: [JobCreator], persister: JobPersister? = nil) {
        self.creators = creators
        self.persister = persister

        if let data = persister {
            for queueName in data.restore() {
                manage[queueName] = SqOperationQueue(queueName, creators, persister, isPaused)
            }
        }
        start()
    }

    public convenience init(creator: JobCreator, persister: JobPersister? = nil) {
        self.init(creators: [creator], persister: persister)
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
        let queue = SqOperationQueue(queueName, creators, persister, isPaused)
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
