//
// Created by Lucas Nelaupe on 29/10/2017.
//

import Foundation

internal class DelayConstraint: JobConstraint {

    func willSchedule(queue: SwiftQueue, operation: SwiftQueueJob) throws {
        // Nothing to do
    }

    func willRun(operation: SwiftQueueJob) throws {
        // Nothing to do
    }

    func run(operation: SwiftQueueJob) -> Bool {
        if let delay = operation.delay {
            if Date().timeIntervalSince(operation.createTime) < delay {
                runInBackgroundAfter(delay, callback: operation.run)
                return false
            }
        }
        return true
    }
}
