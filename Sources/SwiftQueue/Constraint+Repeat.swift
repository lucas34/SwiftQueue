//
// Created by Lucas Nelaupe on 29/5/20.
//

import Foundation

internal final class RepeatConstraint {

    static func run(operation: SqOperation) -> Bool {
        switch operation.info.executor {
        case .background:
            return false
        case .foreground:
            return true
        case.any:
            return true
        }
    }

    static func completionSuccess(sqOperation: SqOperation) {

        if case .limited(let limit) = sqOperation.info.maxRun {
            // Reached run limit
            guard sqOperation.info.runCount + 1 < limit else {
                sqOperation.onTerminate()
                return
            }
        }

        guard sqOperation.info.interval > 0 else {
            // Run immediately
            sqOperation.info.runCount += 1
            sqOperation.run()
            return
        }

        // Schedule run after interval
        sqOperation.nextRunSchedule = Date().addingTimeInterval(sqOperation.info.interval)
        sqOperation.dispatchQueue.runAfter(sqOperation.info.interval, callback: { [weak sqOperation] in
            sqOperation?.info.runCount += 1
            sqOperation?.run()
        })
    }

}

/// Enum to specify background and foreground restriction
public enum Executor: Int {

    /// Job will only run only when the app is in foreground
    case foreground = 0

    /// Job will only run only when the app is in background
    case background = 1

    /// Job can run in both background and foreground
    case any = 2

}

internal extension Executor {

    static func fromRawValue(value: Int) -> Executor {
        assert(value == 0 || value == 1 || value == 2)
        switch value {
        case 1:
            return Executor.background
        case 2:
            return Executor.any
        default:
            return Executor.foreground
        }
    }

}