//
// Created by Lucas Nelaupe on 10/08/2017.
// Copyright (c) 2017 lucas34. All rights reserved.
//

import Foundation

/// Protocol to create instance of your job
public protocol JobCreator {

    /// method called when a job has be to instantiate
    /// Type as specified in JobBuilder.init(type) and params as JobBuilder.with(params)
    func create(type: String, params: [String: Any]?) -> Job

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
