//
// Created by Lucas Nelaupe on 29/10/2017.
//

import Foundation

internal class UniqueUUIDConstraint: JobConstraint {

    class TaskAlreadyExist: ConstraintError {}

    func schedule(queue: SwiftQueue, operation: SwiftQueueJob) throws {
        let exist = queue.operations.contains {
            if let op = $0 as? SwiftQueueJob {
                return op.uuid == operation.uuid
            }
            return false
        }
        if exist {
            throw TaskAlreadyExist()
        }
    }

    func run(operation: SwiftQueueJob) throws -> Bool {
        // Nothing to check
        return true
    }
}
