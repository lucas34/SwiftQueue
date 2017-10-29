//
// Created by Lucas Nelaupe on 29/10/2017.
//

import Foundation

internal class DeadlineConstraint: JobConstraint {

    class DeadlineError: ConstraintError {}

    func schedule(queue: SwiftQueue, operation: SwiftQueueJob) throws {
        try check(operation: operation)
    }

    func run(operation: SwiftQueueJob) throws -> Bool {
        try check(operation: operation)
        return true
    }

    private func check(operation: SwiftQueueJob) throws {
        if let deadline = operation.deadline, deadline < Date() {
            throw DeadlineError()
        }
    }
}
