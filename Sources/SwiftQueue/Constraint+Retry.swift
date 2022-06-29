// The MIT License (MIT)
//
// Copyright (c) 2022 Lucas Nelaupe
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

internal final class JobRetryConstraint: SimpleConstraint, CodableConstraint {

    /// Maximum number of authorised retried
    internal var limit: Limit

    required init(limit: Limit) {
        self.limit = limit
    }

    convenience init?(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: RetryConstraintKey.self)
        if container.contains(.retryLimit) {
            try self.init(limit: container.decode(Limit.self, forKey: .retryLimit))
        } else { return nil }
    }

    func onCompletionFail(sqOperation: SqOperation, error: Error) {
        switch limit {
        case .limited(let value):
            if value > 0 {
                sqOperation.retryJob(actual: self, retry: sqOperation.handler.onRetry(error: error), origin: error)
            } else {
                sqOperation.onTerminate()
            }
        case .unlimited:
            sqOperation.retryJob(actual: self, retry: sqOperation.handler.onRetry(error: error), origin: error)
        }
    }

    private enum RetryConstraintKey: String, CodingKey {
        case retryLimit
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RetryConstraintKey.self)
        try container.encode(limit, forKey: .retryLimit)
    }
}

fileprivate extension SqOperation {

    func retryJob(actual: JobRetryConstraint, retry: RetryConstraint, origin: Error) {

        func exponentialBackoff(initial: TimeInterval) -> TimeInterval {
            currentRepetition += 1
            return currentRepetition == 1 ? initial : initial * pow(2, Double(currentRepetition - 1))
        }

        func retryInBackgroundAfter(_ delay: TimeInterval) {
            nextRunSchedule = Date().addingTimeInterval(delay)
            dispatchQueue.runAfter(delay) { [weak actual, weak self] in
                actual?.limit.decreaseValue(by: 1)
                self?.run()
            }
        }

        switch retry {
        case .cancel:
            lastError = SwiftQueueError.onRetryCancel(origin)
            onTerminate()
        case .retry(let after):
            guard after > 0 else {
                // Retry immediately
                actual.limit.decreaseValue(by: 1)
                self.run()
                return
            }

            // Retry after time in parameter
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
