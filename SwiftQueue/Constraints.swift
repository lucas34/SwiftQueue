//
// Created by Lucas Nelaupe on 10/08/2017.
// Copyright (c) 2017 lucas34. All rights reserved.
//


import Foundation

internal class JobConstraint {

    func schedule(queue: JobQueue, operation: JobTask) throws {

    }

    func run(operation: JobTask) throws {

    }

}

public class ConstraintError: Swift.Error {}
public class Canceled: Swift.Error {}

internal class DeadlineConstraint: JobConstraint {

    class DeadlineError: ConstraintError {}

    override func schedule(queue: JobQueue, operation: JobTask) throws {
        try check(operation: operation)
    }

    override func run(operation: JobTask) throws {
        try check(operation: operation)
    }

    private func check(operation: JobTask) throws {
        if let deadline = operation.deadline, deadline < Date() {
            throw DeadlineError()
        }
    }
}

internal class UniqueUUIDConstraint: JobConstraint {

    class TaskAlreadyExist: ConstraintError {}

    override func schedule(queue: JobQueue, operation: JobTask) throws {
        if queue.tasksMap[operation.taskID] != nil {
            throw TaskAlreadyExist()
        }
    }
}

internal class Constraints {

    private static var constrains: [JobConstraint] = [DeadlineConstraint(),
                                                      UniqueUUIDConstraint()]

    public static func checkConstraintsForRun(task: JobTask) throws {
        for constraint in Constraints.constrains {
            try constraint.run(operation: task)
        }
    }

    public static func checkConstraintsOnSchedule(queue: JobQueue, operation: JobTask) throws {
        for constraint in Constraints.constrains {
            try constraint.schedule(queue: queue, operation: operation)
        }
    }

}
