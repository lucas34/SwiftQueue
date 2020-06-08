//
// Created by Lucas Nelaupe on 25/5/20.
//

import Foundation

internal class PersisterConstraint: SimpleConstraint {

    private let serializer: JobInfoSerializer

    private let persister: JobPersister

    init(serializer: JobInfoSerializer, persister: JobPersister) {
        self.serializer = serializer
        self.persister = persister
    }

    override func willSchedule(queue: SqOperationQueue, operation: SqOperation) throws {
        let data = try serializer.serialize(info: operation.info)
        let name = operation.name ?? ""
        let queueName = queue.name ?? ""
        assertNotEmptyString(name)
        assertNotEmptyString(queueName)
        persister.put(queueName: queueName, taskId: name, data: data)
    }

    func remove(queueName: String, taskId: String) {
        persister.remove(queueName: queueName, taskId: taskId)
    }

}
