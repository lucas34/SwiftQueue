//
// Created by Lucas Nelaupe on 18/8/17.
// Copyright (c) 2017 Lucas Nelaupe. All rights reserved.
//

import Foundation

public final class SwiftQueueManager {

    private let creators: [JobCreator]
    private let persister: JobPersister?

    private var manage = [String: SwiftQueue]()

    public init(creators: [JobCreator], persister: JobPersister? = nil) {
        self.creators = creators
        self.persister = persister

        persister?.restore().forEach {
            createQueue(name: $0)
        }
    }

    internal func getQueue(name: String) -> SwiftQueue {
        if let queue = manage[name] {
            return queue
        } else {
            return createQueue(name: name)
        }
    }

    private func createQueue(name: String) -> SwiftQueue {
        let queue = SwiftQueue(queueName: name, creators: creators, persister: persister)
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
