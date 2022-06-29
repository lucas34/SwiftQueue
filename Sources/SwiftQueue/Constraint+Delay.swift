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

internal final class DelayConstraint: SimpleConstraint, CodableConstraint {

    /// Delay for the first execution of the job
    internal let delay: TimeInterval

    required init(delay: TimeInterval) {
        self.delay = delay
    }

    convenience init?(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DelayConstraintKey.self)
        if container.contains(.delay) {
            try self.init(delay: container.decode(TimeInterval.self, forKey: .delay))
        } else { return nil }
    }

    override func run(operation: SqOperation) -> Bool {
        let epoch = Date().timeIntervalSince(operation.info.createTime)
        guard epoch < delay else {
            // Epoch already greater than delay
            return true
        }

        let time: Double = abs(epoch - delay)

        operation.nextRunSchedule = Date().addingTimeInterval(time)
        operation.dispatchQueue.runAfter(time, callback: { [weak operation] in
            // If the operation in already deInit, it may have been canceled
            // It's safe to ignore the nil check
            // This is mostly to prevent job retention when cancelling operation with delay
            operation?.run()
        })

        operation.logger.log(.verbose, jobId: operation.name, message: "Job delayed by \(time)s")
        return false
    }

    private enum DelayConstraintKey: String, CodingKey {
        case delay
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DelayConstraintKey.self)
        try container.encode(delay, forKey: .delay)
    }

}
