//
// Created by Lucas Nelaupe on 29/10/2017.
//

import Foundation

internal final class UniqueUUIDConstraint: JobConstraint {

    func willSchedule(queue: SqOperationQueue, operation: SqOperation) throws {
        for ope in queue.operations where ope.name == operation.info.uuid {
            if operation.info.override {
                ope.cancel()
            } else {
                throw SwiftQueueError.duplicate
            }
        }
    }

    func willRun(operation: SqOperation) throws {
        // Nothing to check
    }

    func run(operation: SqOperation) -> Bool {
        // Nothing to check
        return true
    }
}
