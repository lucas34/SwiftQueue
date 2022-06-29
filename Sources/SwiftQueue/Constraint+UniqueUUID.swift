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

internal final class UniqueUUIDConstraint: SimpleConstraint, CodableConstraint {

    /// Unique identifier for a job
    internal let uuid: String

    /// Override job when scheduling a job with same uuid
    /// True = Override, False = Abort job with duplicate failure
    internal let override: Bool

    /// Including job that are executing when scheduling with same uuid
    private let includeExecutingJob: Bool

    required init(uuid: String, override: Bool, includeExecutingJob: Bool) {
        self.uuid = uuid
        self.override = override
        self.includeExecutingJob = includeExecutingJob
    }

    convenience init?(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: UUIDConstraintKey.self)
        if container.contains(.uuid) && container.contains(.override) && container.contains(.includeExecutingJob) {
            try self.init(
                    uuid: container.decode(String.self, forKey: .uuid),
                    override: container.decode(Bool.self, forKey: .override),
                    includeExecutingJob: container.decode(Bool.self, forKey: .includeExecutingJob)
            )
        } else { return nil }
    }

    override func willSchedule(queue: SqOperationQueue, operation: SqOperation) throws {
        for ope in queue.operations where ope.name == uuid {
            if shouldAbort(ope: ope, operation: operation) {
                if override {
                    ope.cancel()
                    break
                } else {
                    throw SwiftQueueError.duplicate
                }
            }
        }
    }

    private func shouldAbort(ope: Operation, operation: SqOperation) -> Bool {
        return (ope.isExecuting && includeExecutingJob) || !ope.isExecuting
    }

    private enum UUIDConstraintKey: String, CodingKey {
        case uuid
        case override
        case includeExecutingJob
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: UUIDConstraintKey.self)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(override, forKey: .override)
        try container.encode(includeExecutingJob, forKey: .includeExecutingJob)
    }

}
