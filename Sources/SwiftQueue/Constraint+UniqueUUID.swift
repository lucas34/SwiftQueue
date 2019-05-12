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

internal final class UniqueUUIDConstraint: JobConstraint {

    func willSchedule(queue: SqOperationQueue, operation: SqOperation) throws {
        for ope in queue.operations where ope.name == operation.info.uuid {
            if shouldAbort(ope: ope, operation: operation) {
                if operation.info.override {
                    ope.cancel()
                    break
                } else {
                    throw SwiftQueueError.duplicate
                }
            }
        }
    }

    private func shouldAbort(ope: Operation, operation: SqOperation) -> Bool {
        return (ope.isExecuting && operation.info.includeExecutingJob) || !ope.isExecuting
    }

    func willRun(operation: SqOperation) throws {
        // Nothing to check
    }

    func run(operation: SqOperation) -> Bool {
        // Nothing to check
        return true
    }
}
