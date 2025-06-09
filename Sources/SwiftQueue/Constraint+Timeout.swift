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

internal final class TimeoutConstraint: SimpleConstraint, CodableConstraint {

    /// Auto cancel job if not completed after this time
    internal let timeout: TimeInterval

    required init(timeout: TimeInterval) {
        self.timeout = timeout
    }

    convenience init?(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: TimeoutConstraintKey.self)
        if container.contains(.timeout) {
            try self.init(timeout: container.decode(TimeInterval.self, forKey: .timeout))
        } else { return nil }
    }

    override func run(operation: SqOperation) -> Bool {
        operation.dispatchQueue.runAfter(timeout) { [weak operation] in
            guard let operation else { return }
            if operation.isExecuting && !operation.isFinished {
                operation.cancel(with: SwiftQueueError.timeout)
            }
        }

        return true
    }

    private enum TimeoutConstraintKey: String, CodingKey {
        case timeout
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: TimeoutConstraintKey.self)
        try container.encode(timeout, forKey: .timeout)
    }

}
