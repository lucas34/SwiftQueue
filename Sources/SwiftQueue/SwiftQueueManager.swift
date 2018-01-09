//
// Created by Lucas Nelaupe on 18/8/17.
// Copyright (c) 2017 Lucas Nelaupe. All rights reserved.
//

import Foundation

public final class SwiftQueueManager {

    private let creators: [JobCreator]
    private let persister: JobPersister?

    private var manage = [String: SwiftQueue]()

    private var isPaused = true

    /// Create a new QueueManager with creators to instantiate Job
    public init(creators: [JobCreator], persister: JobPersister? = nil) {
        self.creators = creators
        self.persister = persister

        persister?.restore().forEach {
            manage[$0] = SwiftQueue(queueName: $0, creators: creators, persister: persister, isPaused: isPaused)
        }
        start()
    }

    /// Jobs queued will run again
    public func start() {
        isPaused = false
        manage.values.forEach { element in
            element.isSuspended = false
        }
    }

    /// Avoid new job to run. Not application for current running job.
    public func pause() {
        isPaused = true
        manage.values.forEach { element in
            element.isSuspended = true
        }
    }

    internal func getQueue(name: String) -> SwiftQueue {
        return manage[name] ?? createQueue(name: name)
    }

    private func createQueue(name: String) -> SwiftQueue {
        let queue = SwiftQueue(queueName: name, creators: creators, persister: persister, isPaused: isPaused)
        manage[name] = queue
        return queue
    }

    /// All operations in all queues will be removed
    public func cancelAllOperations() {
        manage.values.forEach { element in
            element.cancelAllOperations()
        }
    }

    /// All operations with this tag in all queues will be removed
    public func cancelOperations(tag: String) {
        manage.values.forEach { element in
            element.cancelOperations(tag: tag)
        }
    }

    /// All operations with this uuid in all queues will be removed
    public func cancelOperations(uuid: String) {
        manage.values.forEach { element in
            element.cancelOperations(uuid: uuid)
        }
    }

    /// Blocks the current thread until all of the receiver’s queued and executing operations finish executing.
    public func waitUntilAllOperationsAreFinished() {
        manage.values.forEach { element in
            element.waitUntilAllOperationsAreFinished()
        }
    }

    /// Peek queue information for diagnostic and logging purpose
    public func peekQueue(group: String) -> QueueInfo {
        let queue = getQueue(name: group)
        return QueueInfo(name: group, queueCount: queue.operationCount, isSuspended: queue.isSuspended)
    }
}
