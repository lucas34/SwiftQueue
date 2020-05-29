// The MIT License (MIT)
//
// Copyright (c) 2019 Lucas Nelaupe
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
