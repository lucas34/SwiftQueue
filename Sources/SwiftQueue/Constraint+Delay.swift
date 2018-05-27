//
// Created by Lucas Nelaupe on 29/10/2017.
//

import Foundation

internal final class DelayConstraint: JobConstraint {

    func willSchedule(queue: SqOperationQueue, operation: SqOperation) throws {
        // Nothing to do
    }

    func willRun(operation: SqOperation) throws {
        // Nothing to do
    }

    func run(operation: SqOperation) -> Bool {
        guard let delay = operation.info.delay else {
            // No delay run immediately
            return true
        }

        let epoch = Date().timeIntervalSince(operation.info.createTime)
        guard epoch < delay else {
            // Epoch already greater than delay
            return true
        }

        let time: Double = abs(epoch - delay)

        runInBackgroundAfter(time, callback: { [weak operation] in
            // If the operation in already deInit, it may have been canceled
            // It's safe to ignore the nil check
            // This is mostly to prevent job retention when cancelling operation with delay
            operation?.run()
        })

        operation.logger.log(.verbose, jobId: operation.info.uuid, message: "Job delayed by \(time)s")
        return false
    }
}
