// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import Foundation

internal final class DeadlineConstraint: JobConstraint {

    func willSchedule(queue: SqOperationQueue, operation: SqOperation) throws {
        try check(operation: operation)
    }

    func willRun(operation: SqOperation) throws {
        try check(operation: operation)
    }

    func run(operation: SqOperation) -> Bool {
        guard let delay = operation.info.deadline else {
            return true
        }

        operation.dispatchQueue.runAfter(delay.timeIntervalSince(Date()), callback: { [weak operation] in
            guard let ope = operation else { return }
            guard !ope.isFinished else { return }

            ope.cancel(with: SwiftQueueError.deadline)
        })
        return true
    }

    private func check(operation: SqOperation) throws {
        if let deadline = operation.info.deadline, deadline < Date() {
            throw SwiftQueueError.deadline
        }
    }
}
