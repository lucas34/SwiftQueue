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

    init(queueName: String, creators: [JobCreator], persister: JobPersister? = nil, isPaused: Bool = false) {
        self.creators = creators
        self.persister = persister
        self.queueName = queueName

        super.init()

        self.isSuspended = isPaused
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
            try job.willScheduleJob(queue: self)
        } catch let error {
            job.abort(error: error)
            return
        }

        // Serialize this operation
        if job.isPersisted, let sp = persister, let data = job.toJSONString() {
            sp.put(queueName: queueName, taskId: job.uuid, data: data)
        }
        job.completionBlock = { [weak self] in
            self?.completed(job)
        }
        super.addOperation(ope)
    }

    public func cancelOperations(tag: String) {
        operations.flatMap { operation -> SwiftQueueJob? in
            operation as? SwiftQueueJob
        }.filter {
            $0.tags.contains(tag)
        }.forEach {
            $0.cancel()
        }
    }

    func completed(_ job: SwiftQueueJob) {
        // Remove this operation from serialization
        if job.isPersisted, let sp = persister {
            sp.remove(queueName: queueName, taskId: job.uuid)
        }

        job.completed()
    }

    func createHandler(type: String, params: Any?) -> Job? {
        return SwiftQueue.createHandler(creators: creators, type: type, params: params)
    }

    static func createHandler(creators: [JobCreator], type: String, params: Any?) -> Job? {
        return creators.flatMap {
            $0.create(type: type, params: params)
        }.first
    }
}
