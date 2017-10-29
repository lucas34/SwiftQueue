//
// Created by Lucas Nelaupe on 29/10/2017.
//

import Foundation

internal class DelayConstraint: JobConstraint {

    func schedule(queue: SwiftQueue, operation: SwiftQueueJob) throws {
        // Nothing to do
    }

    func run(operation: SwiftQueueJob) throws -> Bool {
        if let delay = operation.delay {
            if Date().timeIntervalSince(operation.createTime) < delay {
                runInBackgroundAfter(delay, callback: operation.run)
                return false
            }
        }
        return true
    }
}
