//
// Created by Lucas Nelaupe on 10/08/2017.
// Copyright (c) 2017 lucas34. All rights reserved.
//

import Foundation

public protocol JobCreator {

    func create(jobType: String, params: Any?) -> Job?

}

public protocol JobPersister {

    func restore(queueName: String) -> [String]

    func put(taskId: String, data: String)

    func remove(taskId: String)

}

public final class SwiftQueue: OperationQueue {

    private let creators: [JobCreator]
    private let persister: JobPersister?

    internal var tasksMap = [String: JobTask]()

    public init(queueName: String = UUID().uuidString, creators: [JobCreator]? = nil, persister: JobPersister? = nil) {
        self.creators = creators ?? []
        self.persister = persister

        super.init()

        self.name = queueName
        self.maxConcurrentOperationCount = 1

        loadSerializedTasks(name: queueName)
    }

    /**
    Deserializes tasks that were serialized (persisted)
    */
    private func loadSerializedTasks(name: String) {
        persister?.restore(queueName: name).flatMap { string -> JobTask? in
            JobTask(json: string, creator: creators)
        }.sorted { task, task1 in
            task.createTime < task1.createTime
        }.forEach { task in
            addOperation(task)
        }
    }

    /**
    Adds a JobTask to the queue and serializes it

    - parameter op: A JobTask to execute on the queue
    */
    public override func addOperation(_ ope: Operation) {
        guard let task = ope as? JobTask else {
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
            sp.put(taskId: task.taskID, data: data)
        }
        ope.completionBlock = {
            self.taskComplete(ope)
        }
        super.addOperation(ope)
    }

    public override func cancelAllOperations() {
        operations.flatMap { operation -> JobTask? in
            operation as? JobTask
        }.forEach { task in
            persister?.remove(taskId: task.taskID)
        }
        super.cancelAllOperations()
    }

    public func cancelOperation(tag: String) {
        operations.flatMap { operation -> JobTask? in
            operation as? JobTask
        }.filter { task in
            task.tags.contains(tag)
        }.forEach { task in
            persister?.remove(taskId: task.taskID)
            task.cancel()
        }
    }

    func taskComplete(_ ope: Operation) {
        if let task = ope as? JobTask {
            tasksMap.removeValue(forKey: task.taskID)

            // Remove this operation from serialization
            if let sp = persister {
                sp.remove(taskId: task.taskID)
            }

            task.taskComplete()
        }
    }

    func createHandler(jobType: String, params: Any?) -> Job? {
        return SwiftQueue.createHandler(creators: creators, jobType: jobType, params: params)
    }

    static func createHandler(creators: [JobCreator], jobType: String, params: Any?) -> Job? {
        for creator in creators {
            if let job = creator.create(jobType: jobType, params: params) {
                return job
            }
        }
        return nil
    }
}
