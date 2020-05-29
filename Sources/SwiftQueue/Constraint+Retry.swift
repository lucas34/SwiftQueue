//
// Created by Lucas Nelaupe on 29/5/20.
//

import Foundation

class JobRetryConstraint {

    static func onCompletionFail(sqOperation: SqOperation, error: Error) {
        switch sqOperation.info.retries {
        case .limited(let value):
            if value > 0 {
                sqOperation.retryJob(retry: sqOperation.handler.onRetry(error: error), origin: error)
            } else {
                sqOperation.onTerminate()
            }
        case .unlimited:
            sqOperation.retryJob(retry: sqOperation.handler.onRetry(error: error), origin: error)
        }
    }

}

fileprivate extension SqOperation {

    func retryJob(retry: RetryConstraint, origin: Error) {

        func exponentialBackoff(initial: TimeInterval) -> TimeInterval {
            currentRepetition += 1
            return currentRepetition == 1 ? initial : initial * pow(2, Double(currentRepetition - 1))
        }

        func retryInBackgroundAfter(_ delay: TimeInterval) {
            nextRunSchedule = Date().addingTimeInterval(delay)
            dispatchQueue.runAfter(delay) { [weak self] in
                self?.info.retries.decreaseValue(by: 1)
                self?.run()
            }
        }

        switch retry {
        case .cancel:
            lastError = SwiftQueueError.onRetryCancel(origin)
            onTerminate()
        case .retry(let after):
            guard after > 0 else { // Retry immediately
                info.retries.decreaseValue(by: 1)
                self.run()
                return
            }
            
            retryInBackgroundAfter(after)
        case .exponential(let initial):
            retryInBackgroundAfter(exponentialBackoff(initial: initial))
        case .exponentialWithLimit(let initial, let maxDelay):
            retryInBackgroundAfter(min(maxDelay, exponentialBackoff(initial: initial)))
        }
    }

}

/// Behaviour for retrying the job
public enum RetryConstraint {
    /// Retry after a certain time. If set to 0 it will retry immediately
    case retry(delay: TimeInterval)
    /// Will not retry, onRemoved will be called immediately
    case cancel
    /// Exponential back-off
    case exponential(initial: TimeInterval)
    /// Exponential back-off with max delay
    case exponentialWithLimit(initial: TimeInterval, maxDelay: TimeInterval)
}