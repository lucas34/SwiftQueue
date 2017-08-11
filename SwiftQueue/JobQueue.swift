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

    func put(info: JobTask)

    func remove(uuid: String)

    func remove(tag: String)

}

internal protocol JobTicker {

    func next()

    func cancel(operation: JobTask)

}

public final class JobQueue: OperationQueue {

    private let creators: [JobCreator]
    private let persister: JobPersister?

    internal var tasksMap = [String: JobTask]()

    public var tasks: [JobTask] {
        let array = operations

        var output = [JobTask]()
        output.reserveCapacity(array.count)

        for obj in array {
            if let cast = obj as? JobTask {
                output.append(cast)
            }
        }

        return output
    }

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
            task.createTime < task1.createTime // TODO test
        }.forEach { task in
            addOperation(task)
        }
    }

    /**
    Adds a JobTask to the queue and serializes it

    - parameter op: A JobTask to execute on the queue
    */
    override public func addOperation(_ ope: Operation) {
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
        if let sp = persister {
            sp.put(info: task)
        }
        ope.completionBlock = {
            self.taskComplete(ope)
        }
        super.addOperation(ope)
    }

    func taskComplete(_ op: Operation) {
        if let task = op as? JobTask {
            tasksMap.removeValue(forKey: task.taskID)

            // Remove this operation from serialization
            if let sp = persister {
                sp.remove(uuid: task.taskID)
            }

            task.taskComplete()
        }
    }

    func createHandler(jobType: String, params: Any?) -> Job? {
        return JobQueue.createHandler(creators: creators, jobType: jobType, params: params)
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
