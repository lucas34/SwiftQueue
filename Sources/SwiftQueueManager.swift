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

    public init(creators: [JobCreator], persister: JobPersister? = nil) {
        self.creators = creators
        self.persister = persister

        persister?.restore().forEach {
            manage[$0] = SwiftQueue(queueName: $0, creators: creators, persister: persister, isPaused: isPaused)
        }
        start()
    }

    public func start() {
        isPaused = false
        manage.values.forEach { element in
            element.start()
        }
    }

    public func pause() {
        isPaused = true
        manage.values.forEach { element in
            element.pause()
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

    public func cancelAllOperations() {
        manage.values.forEach { element in
            element.cancelAllOperations()
        }
    }

    public func cancelOperations(tag: String) {
        manage.values.forEach { element in
            element.cancelOperations(tag: tag)
        }
    }

}
