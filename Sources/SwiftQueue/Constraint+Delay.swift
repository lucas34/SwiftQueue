// The MIT License (MIT)
//
// Copyright (c) 2017 Lucas Nelaupe
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

        operation.dispatchQueue.runAfter(time, callback: { [weak operation] in
            // If the operation in already deInit, it may have been canceled
            // It's safe to ignore the nil check
            // This is mostly to prevent job retention when cancelling operation with delay
            operation?.run()
        })

        operation.logger.log(.verbose, jobId: operation.info.uuid, message: "Job delayed by \(time)s")
        return false
    }
}
