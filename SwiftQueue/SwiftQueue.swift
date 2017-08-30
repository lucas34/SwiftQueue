//
// Created by Lucas Nelaupe on 10/08/2017.
// Copyright (c) 2017 lucas34. All rights reserved.
//

import Foundation

public protocol JobCreator {

    func create(type: String, params: Any?) -> Job?

}

public protocol JobPersister {

    func restore() -> [String]

    func restore(queueName: String) -> [String]

    func put(queueName: String, taskId: String, data: String)

    func remove(queueName: String, taskId: String)

}

internal final class SwiftQueue: OperationQueue {

    private let creators: [JobCreator]
    private let persister: JobPersister?

    private let queueName: String

    internal var isPaused: Bool

    init(queueName: String, creators: [JobCreator], persister: JobPersister? = nil, isPaused: Bool = false) {
        self.creators = creators
        self.persister = persister
        self.queueName = queueName

        self.isPaused = isPaused

        super.init()

        self.name = queueName
        self.maxConcurrentOperationCount = 1

        loadSerializedTasks(name: queueName)
    }

    private func loadSerializedTasks(name: String) {
        persister?.restore(queueName: name).flatMap { string -> SwiftQueueJob? in
            SwiftQueueJob(json: string, creator: creators)
        }.sorted {
            $0.createTime < $1.createTime
        }.forEach(addOperation)
    }

    public override func addOperation(_ ope: Operation) {
        guard let job = ope as? SwiftQueueJob else {
            // Not a job Task I don't care
            super.addOperation(ope)
            return
        }

        do {
            try Constraints.checkConstraintsOnSchedule(queue: self, operation: job)
        } catch (let error) {
            job.abort(error: error)
            return
        }

        // Serialize this operation
        if job.isPersisted, let sp = persister, let data = job.toJSONString() {
            sp.put(queueName: queueName, taskId: job.uuid, data: data)
        }
        ope.completionBlock = {
            self.completed(ope)
        }
        super.addOperation(ope)
    }

    public override func cancelAllOperations() {
        operations.flatMap { operation -> SwiftQueueJob? in
            operation as? SwiftQueueJob
        }.filter { job in
            job.isPersisted
        }.forEach {
            persister?.remove(queueName: queueName, taskId: $0.uuid)
        }
        super.cancelAllOperations()
    }

    public func cancelOperations(tag: String) {
        operations.flatMap { operation -> SwiftQueueJob? in
            operation as? SwiftQueueJob
        }.filter {
            $0.tags.contains(tag)
        }.forEach {
            if $0.isPersisted {
                persister?.remove(queueName: queueName, taskId: $0.uuid)
            }
            $0.cancel()
        }
    }

    func completed(_ ope: Operation) {
        if let job = ope as? SwiftQueueJob {
            // Remove this operation from serialization
            if job.isPersisted, let sp = persister {
                sp.remove(queueName: queueName, taskId: job.uuid)
            }

            job.completed()
        }
    }

    func createHandler(type: String, params: Any?) -> Job? {
        return SwiftQueue.createHandler(creators: creators, type: type, params: params)
    }

    func start() {
        isPaused = false
        updatePauseStatue()
    }

    func pause() {
        isPaused = true
        updatePauseStatue()
    }

    private func updatePauseStatue() {
        operations.flatMap { operation -> SwiftQueueJob? in
            operation as? SwiftQueueJob
        }.forEach {
            $0.isPaused = isPaused
        }
    }

    static func createHandler(creators: [JobCreator], type: String, params: Any?) -> Job? {
        return creators.flatMap {
            $0.create(type: type, params: params)
        }.first
    }
}
