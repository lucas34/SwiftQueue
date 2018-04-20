//
// Created by Lucas Nelaupe on 23/1/18.
//

import Foundation

internal final class SqOperationQueue: OperationQueue {

    private let creator: JobCreator
    private let persister: JobPersister?

    private let queueName: String

    private let trigger: TriggerOperation

    private let logger: SwiftQueueLogger

    init(_ queueName: String, _ creator: JobCreator, _ persister: JobPersister? = nil, _ isPaused: Bool = false, synchronous: Bool, logger: SwiftQueueLogger) {
        self.creator = creator
        self.persister = persister
        self.queueName = queueName
        self.logger = logger

        self.trigger = TriggerOperation()

        super.init()

        self.isSuspended = isPaused
        self.name = queueName
        self.maxConcurrentOperationCount = 1

        if synchronous {
            self.loadSerializedTasks(name: queueName)
        } else {
            DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async { () -> Void in
                self.loadSerializedTasks(name: queueName)
            }
        }
    }

    private func loadSerializedTasks(name: String) {
        persister?.restore(queueName: name).compactMap { string -> SqOperation? in
            return SqOperation(json: string, creator: creator, logger: logger)
        }.sorted { operation, operation2 in
            operation.info.createTime < operation2.info.createTime
        }.forEach { operation in
            self.addOperationInternal(operation, wait: false)
        }
        super.addOperation(trigger)
    }

    override func addOperation(_ ope: Operation) {
        self.addOperationInternal(ope, wait: true)
    }

    private func addOperationInternal(_ ope: Operation, wait: Bool) {
        guard !ope.isFinished else { return }

        if wait {
            ope.addDependency(trigger)
        }

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

internal class TriggerOperation: Operation {}
