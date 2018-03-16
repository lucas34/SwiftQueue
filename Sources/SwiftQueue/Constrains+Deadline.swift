//
// Created by Lucas Nelaupe on 29/10/2017.
//

import Foundation

internal final class DeadlineConstraint: JobConstraint {

    func willSchedule(queue: SqOperationQueue, operation: SqOperation) throws {
        try check(operation: operation)
    }

    func willRun(operation: SqOperation) throws {
        try check(operation: operation)
    }

    func run(operation: SqOperation) -> Bool {
        if let delay = operation.info.deadline {
            runInBackgroundAfter(delay.timeIntervalSince(Date()), callback: { [weak operation] in
                operation?.run()
            })
        }
        return true
    }

    private func check(operation: SqOperation) throws {
        if let deadline = operation.info.deadline, deadline < Date() {
            throw SwiftQueueError.deadline
        }
    }
}
