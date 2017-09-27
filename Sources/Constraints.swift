//
// Created by Lucas Nelaupe on 10/08/2017.
// Copyright (c) 2017 lucas34. All rights reserved.
//

import Foundation

internal class JobConstraint {

    func schedule(queue: SwiftQueue, operation: SwiftQueueJob) throws {

    }

    func run(operation: SwiftQueueJob) throws {

    }

}

public class ConstraintError: Swift.Error {}
public class Canceled: Swift.Error {}

internal class DeadlineConstraint: JobConstraint {

    class DeadlineError: ConstraintError {}

    override func schedule(queue: SwiftQueue, operation: SwiftQueueJob) throws {
        try check(operation: operation)
    }

    override func run(operation: SwiftQueueJob) throws {
        try check(operation: operation)
    }

    private func check(operation: SwiftQueueJob) throws {
        if let deadline = operation.deadline, deadline < Date() {
            throw DeadlineError()
        }
    }
}

internal class UniqueUUIDConstraint: JobConstraint {

    class TaskAlreadyExist: ConstraintError {}

    override func schedule(queue: SwiftQueue, operation: SwiftQueueJob) throws {
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
}

internal class Constraints {

    private static var constrains: [JobConstraint] = [DeadlineConstraint(),
                                                      UniqueUUIDConstraint()]

    public static func checkConstraintsForRun(job: SwiftQueueJob) throws {
        for constraint in Constraints.constrains {
            try constraint.run(operation: job)
        }
    }

    public static func checkConstraintsOnSchedule(queue: SwiftQueue, operation: SwiftQueueJob) throws {
        for constraint in Constraints.constrains {
            try constraint.schedule(queue: queue, operation: operation)
        }
    }

}
