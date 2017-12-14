//
// Created by Lucas Nelaupe on 29/10/2017.
//

import Foundation

/// Exception thrown when a deadline is reached
public class DeadlineError: ConstraintError {}

internal class DeadlineConstraint: JobConstraint {

    func willSchedule(queue: SwiftQueue, operation: SwiftQueueJob) throws {
        try check(operation: operation)
    }

    func willRun(operation: SwiftQueueJob) throws {
        try check(operation: operation)
    }

    func run(operation: SwiftQueueJob) -> Bool {
        if let delay = operation.info.deadline {
            runInBackgroundAfter(delay.timeIntervalSince(Date()), callback: { [weak operation = operation] in
                operation?.run()
            })
        }
        return true
    }

    private func check(operation: SwiftQueueJob) throws {
        if let deadline = operation.info.deadline, deadline < Date() {
            throw DeadlineError()
        }
    }
}
