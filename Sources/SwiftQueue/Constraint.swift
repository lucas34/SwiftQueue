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

internal protocol JobConstraint {

    /**
        - Operation will be added to the queue
        Raise exception if the job cannot run
    */
    func willSchedule(queue: SqOperationQueue, operation: SqOperation) throws

    /**
        - Operation will run
        Raise exception if the job cannot run anymore
    */
    func willRun(operation: SqOperation) throws

    /**
        - Operation will run
        Return false if the job cannot run immediately
    */
    func run(operation: SqOperation) -> Bool

}

/// Behaviour for retrying the job
public enum RetryConstraint {
    /// Retry after a certain time. If set to 0 it will retry immediately
    case retry(delay: TimeInterval)
    /// Will not retry, onRemoved will be called immediately
    case cancel
    /// Exponential back-off
    case exponential(initial: TimeInterval)
}

internal class DefaultNoConstraint: JobConstraint {

    func willSchedule(queue: SqOperationQueue, operation: SqOperation) throws {}

    func willRun(operation: SqOperation) throws {}

    func run(operation: SqOperation) -> Bool { return true }

}
