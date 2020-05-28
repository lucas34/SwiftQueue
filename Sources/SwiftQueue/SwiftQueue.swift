// The MIT License (MIT)
//
// Copyright (c) 2019 Lucas Nelaupe
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

    /// Remove all task
    func clearAll()

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
    case fail(Error)

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
    func onRetry(error: Error) -> RetryConstraint

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
public enum SwiftQueueError: Error {

    /// Job has been canceled
    case canceled

    /// Deadline has been reached
    case deadline

    /// Exception thrown when you try to schedule a job with a same ID as one currently scheduled
    case duplicate

    /// Job canceled inside onError. Parameter contains the origin error
    case onRetryCancel(Error)

    /// Job took too long to run
    case timeout

}

/// Enum to specify background and foreground restriction
public enum Executor: Int {

    /// Job will only run only when the app is in foreground
    case foreground = 0

    /// Job will only run only when the app is in background
    case background = 1

    /// Job can run in both background and foreground
    case any = 2

}
