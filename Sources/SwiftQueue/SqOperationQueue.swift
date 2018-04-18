//
// Created by Lucas Nelaupe on 23/1/18.
//

import Foundation

internal final class SqOperationQueue: OperationQueue {

    private let creator: JobCreator
    private let persister: JobPersister?

    private let queueName: String

    init(_ queueName: String, _ creator: JobCreator, _ persister: JobPersister? = nil, _ isPaused: Bool = false) {
        self.creator = creator
        self.persister = persister
        self.queueName = queueName

        super.init()

        self.isSuspended = isPaused
        self.name = queueName
        self.maxConcurrentOperationCount = 1

        loadSerializedTasks(name: queueName)
    }

    private func loadSerializedTasks(name: String) {
        persister?.restore(queueName: name).flatMapCompact { string -> SqOperation? in
            SqOperation(json: string, creator: creator)
        }.sorted {
            $0.info.createTime < $1.info.createTime
        }.forEach(addOperation)
    }

    override func addOperation(_ ope: Operation) {
        guard !ope.isFinished else { return }

        guard let job = ope as? SqOperation else {
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
        if job.info.isPersisted, let database = persister, let data = job.toJSONString() {
            database.put(queueName: queueName, taskId: job.info.uuid, data: data)
        }
        job.completionBlock = { [weak self] in
            self?.completed(job)
        }
        super.addOperation(job)
    }

    func cancelOperations(tag: String) {
        for case let operation as SqOperation in operations where operation.info.tags.contains(tag) {
            operation.cancel()
        }
    }

    func cancelOperations(uuid: String) {
        for case let operation as SqOperation in operations where operation.info.uuid == uuid {
            operation.cancel()
        }
    }

    private func completed(_ job: SqOperation) {
        // Remove this operation from serialization
        if job.info.isPersisted, let database = persister {
            database.remove(queueName: queueName, taskId: job.info.uuid)
        }

        job.remove()
    }

    func createHandler(type: String, params: [String: Any]?) -> Job {
        return creator.create(type: type, params: params)
    }

}
