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

/// Protocol to create instance of your job
public protocol JobCreator {

    /// method called when a job has be to instantiate
    /// Type as specified in JobBuilder.init(type) and params as JobBuilder.with(params)
    func create(type: String, params: [String: Any]?) -> Job

}

public protocol QueueCreator {

    func create(queueName: String) -> Queue

}

/// Method to implement to have a custom persister
public protocol JobPersister {

    /// Return an array of QueueName persisted
    func restore() -> [String]

    /// Restore all job in a single queue
    func restore(queueName: String) -> [String]

    /// Add a single job to a single queue with custom params
    func put(queueName: String, taskId: String, data: String)

    /// Remove a single job for a single queue
    func remove(queueName: String, taskId: String)

}

/// Class to serialize and deserialize `JobInfo`
public protocol JobInfoSerializer {

    /// Convert `JobInfo` into a representable string
    func serialize(info: JobInfo) throws -> String

    /// Convert back a string to a `JobInfo`
    func deserialize(json: String) throws -> JobInfo

}

/// Callback to give result in synchronous or asynchronous job
public protocol JobResult {

    /// Method callback to notify the completion of your 
    func done(_ result: JobCompletion)

}

/// Enum to define possible Job completion values
public enum JobCompletion {

    /// Job completed successfully
    case success

    /// Job completed with error
    case fail(Swift.Error)

}

/// Protocol to implement to run a job
public protocol Job {

    /// Perform your operation
    /// Will be called in background thread
    func onRun(callback: JobResult)

    /// Fail has failed with the 
    /// Will only gets called if the job can be retried
    /// Not applicable for 'ConstraintError'
    /// Not application if the retry(value) is less than 2 which is the case by default
    /// Will be called in background thread
    func onRetry(error: Swift.Error) -> RetryConstraint

    /// Job is removed from the queue and will never run again
    /// May be called in background or main thread
    func onRemove(result: JobCompletion)

}

public protocol Queue {

    var name: String { get }

    var maxConcurrent: Int { get }

}

public enum BasicQueue {
    case synchronous
    case concurrent
    case custom(String)
}

public class BasicQueueCreator: QueueCreator {

    public init() {}

    public func create(queueName: String) -> Queue {
        switch queueName {
        case "GLOBAL": return BasicQueue.synchronous
        case "MULTIPLE": return BasicQueue.concurrent
        default: return BasicQueue.custom(queueName)
        }
    }

}

extension BasicQueue: Queue {

    public var name: String {
        switch self {
        case .synchronous : return "GLOBAL"
        case .concurrent : return "MULTIPLE"
        case .custom(let variable) : return variable
        }
    }

    public var maxConcurrent: Int {
        switch self {
        case .synchronous : return 1
        case .concurrent : return 2
        case .custom : return 1
        }
    }

}

/// Listen from job status
public protocol JobListener {

    /// Job will start executing
    func onBeforeRun(job: JobInfo)

    /// Job completed execution
    func onAfterRun(job: JobInfo, result: JobCompletion)

    /// Job is removed from the queue and will not run anymore
    func onTerminated(job: JobInfo, result: JobCompletion)

}

/// Enum to specify a limit
public enum Limit {

    /// No limit
    case unlimited

    /// Limited to a specific number
    case limited(Double)

}

/// Generic class for any constraint violation
public enum SwiftQueueError: Swift.Error {

    /// Job has been canceled
    case canceled

    /// Deadline has been reached
    case deadline

    /// Exception thrown when you try to schedule a job with a same ID as one currently scheduled
    case duplicate

    /// Job canceled inside onError. Parameter contains the origin error
    case onRetryCancel(Error)

}

