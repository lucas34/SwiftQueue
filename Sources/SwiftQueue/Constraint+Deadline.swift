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

internal final class DeadlineConstraint: JobConstraint, CodableConstraint {

    /// Cancel the job after a certain date
    internal let deadline: Date

    required init(deadline: Date) {
        self.deadline = deadline
    }

    convenience init?(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DeadlineConstraintKey.self)
        if container.contains(.deadline) {
            try self.init(deadline: container.decode(Date.self, forKey: .deadline))
        } else { return nil }
    }

    func willSchedule(queue: SqOperationQueue, operation: SqOperation) throws {
        try check()
    }

    func willRun(operation: SqOperation) throws {
        try check()
    }

    func run(operation: SqOperation) -> Bool {
        operation.dispatchQueue.runAfter(deadline.timeIntervalSinceNow, callback: { [weak operation] in
            if operation?.isFinished != false {
                operation?.cancel(with: SwiftQueueError.deadline)
            }
        })
        return true
    }

    private func check() throws {
        if deadline < Date() {
            throw SwiftQueueError.deadline
        }
    }

    private enum DeadlineConstraintKey: String, CodingKey {
        case deadline
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DeadlineConstraintKey.self)
        try container.encode(deadline, forKey: .deadline)
    }

}
