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
        if let delay = operation.info.delay {
            if Date().timeIntervalSince(operation.info.createTime) < delay {
                runInBackgroundAfter(delay, callback: { [weak operation = operation] in
                    // If the operation in already deInit, it may have been canceled
                    // It's safe to ignore the nil check
                    // This is mostly to prevent job retention when cancelling operation with delay
                    operation?.run()
                })
                return false
            }
        }
        return true
    }
}
