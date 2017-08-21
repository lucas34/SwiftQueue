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

    internal var tasksMap = [String: SwiftQueueJob]()

    private let queueName: String

    init(queueName: String, creators: [JobCreator], persister: JobPersister? = nil) {
        self.creators = creators
        self.persister = persister
        self.queueName = queueName

        super.init()

        self.name = queueName
        self.maxConcurrentOperationCount = 1

        loadSerializedTasks(name: queueName)
    }

    /**
    Deserializes tasks that were serialized (persisted)
    */
    private func loadSerializedTasks(name: String) {
        persister?.restore(queueName: name).flatMap { string -> SwiftQueueJob? in
            SwiftQueueJob(json: string, creator: creators)
        }.sorted { task, task1 in
            task.createTime < task1.createTime
        }.forEach { task in
            addOperation(task)
        }
    }

    public override func addOperation(_ ope: Operation) {
        guard let task = ope as? SwiftQueueJob else {
            // Not a job Task I don't care
            super.addOperation(ope)
            return
        }

        do {
            try Constraints.checkConstraintsOnSchedule(queue: self, operation: task)
        } catch (let error) {
            task.abort(error: error)
            return
        }

        tasksMap[task.taskID] = task

        // Serialize this operation
        if let sp = persister, let data = task.toJSONString() {
            sp.put(queueName: queueName, taskId: task.taskID, data: data)
        }
        ope.completionBlock = {
            self.taskComplete(ope)
        }
        super.addOperation(ope)
    }

    public override func cancelAllOperations() {
        operations.flatMap { operation -> SwiftQueueJob? in
            operation as? SwiftQueueJob
        }.forEach { task in
            tasksMap.removeValue(forKey: task.taskID)
            persister?.remove(queueName: queueName, taskId: task.taskID)
        }
        super.cancelAllOperations()
    }

    public func cancelOperations(tag: String) {
        operations.flatMap { operation -> SwiftQueueJob? in
            operation as? SwiftQueueJob
        }.filter { task in
            task.tags.contains(tag)
        }.forEach { task in
            tasksMap.removeValue(forKey: task.taskID)
            persister?.remove(queueName: queueName, taskId: task.taskID)
            task.cancel()
        }
    }

    func taskComplete(_ ope: Operation) {
        if let task = ope as? SwiftQueueJob {
            tasksMap.removeValue(forKey: task.taskID)

            // Remove this operation from serialization
            if let sp = persister {
                sp.remove(queueName: queueName, taskId: task.taskID)
            }

            task.taskComplete()
        }
    }

    func createHandler(type: String, params: Any?) -> Job? {
        return SwiftQueue.createHandler(creators: creators, type: type, params: params)
    }

    static func createHandler(creators: [JobCreator], type: String, params: Any?) -> Job? {
        for creator in creators {
            if let job = creator.create(type: type, params: params) {
                return job
            }
        }
        return nil
    }
}
