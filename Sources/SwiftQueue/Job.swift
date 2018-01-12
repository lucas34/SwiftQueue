//
// Created by Lucas Nelaupe on 10/08/2017.
// Copyright (c) 2017 lucas34. All rights reserved.
//

import Foundation

/// Builder to create your job with behaviour
public final class JobBuilder {

    private var info: JobInfo

    /// Type of your job that you will receive in JobCreator.create(type)
    public init(type: String) {
        assertNotEmptyString(type)
        self.info = JobInfo(type: type)
    }

    /// Allow only 1 job at the time with this ID scheduled or running
    /// Same job scheduled with same id will result in onRemove(TaskAlreadyExist) if override = false
    /// If override = true the previous job will be canceled and the new job will be scheduled
    public func singleInstance(forId: String, override: Bool = false) -> JobBuilder {
        assertNotEmptyString(forId)
        info.uuid = forId
        info.override = override
        return self
    }

    /// Job in different groups can run in parallel
    public func group(name: String) -> JobBuilder {
        assertNotEmptyString(name)
        info.group = name
        return self
    }

    /// Delay the execution of the job.
    /// Only start the countdown when the job should run and not when scheduled
    public func delay(time: TimeInterval) -> JobBuilder {
        assert(time >= 0)
        info.delay = time
        return self
    }

    /// Job should be removed from the queue after a certain date
    public func deadline(date: Date) -> JobBuilder {
        info.deadline = date
        return self
    }

    /// Repeat job a certain number of time and with a interval between each run 
    /// count -1 by default for unlimited periodic and immediate
    @available(*, unavailable, message: "Use periodic(Limit, TimeInterval) instead")
    public func periodic(count: Int = -1, interval: TimeInterval = 0) -> JobBuilder {
        info.maxRun = count
        info.interval = interval
        return self
    }

    public func periodic(limit: Limit = .unlimited, interval: TimeInterval = 0) -> JobBuilder {
        assert(interval >= 0)
        info.maxRun = limit.intValue
        info.interval = interval
        return self
    }

    /// Connectivity constraint.
    public func internet(atLeast: NetworkType) -> JobBuilder {
        info.requireNetwork = atLeast
        return self
    }

    /// Job should be persisted. 
    public func persist(required: Bool) -> JobBuilder {
        info.isPersisted = required
        return self
    }

    /// Max number of authorised retry before the job is removed
    @available(*, unavailable, message: "Use retry(Limit) instead")
    public func retry(max: Int) -> JobBuilder {
        return self
    }

    /// Limit number of retry. Overall for the lifecycle of the SwiftQueueManager.
    /// For a periodic job, the retry count will not be reset at each period. 
    public func retry(limit: Limit) -> JobBuilder {
        info.retries = limit.intValue
        return self
    }

    /// Custom tag to mark the job
    public func addTag(tag: String) -> JobBuilder {
        assertNotEmptyString(tag)
        info.tags.insert(tag)
        return self
    }

    /// Custom parameters will be forwarded to create method
    public func with(params: [String: Any]) -> JobBuilder {
        assert(JSONSerialization.isValidJSONObject(params))
        info.params = params
        return self
    }

    internal func build(job: Job) -> SwiftQueueJob {
        return SwiftQueueJob(job: job, info: info)
    }

    /// Add job to the JobQueue
    public func schedule(manager: SwiftQueueManager) {
        let queue = manager.getQueue(name: info.group)
        guard let job = queue.createHandler(type: info.type, params: info.params) else {
            return
        }
        queue.addOperation(build(job: job))
    }
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
    func onRun(callback: JobResult)

    /// Fail has failed with the 
    /// Will only gets called if the job can be retried
    /// Not applicable for 'ConstraintError'
    /// Not application if the retry(value) is less than 2 which is the case by default
    func onRetry(error: Swift.Error) -> RetryConstraint

    /// Job is removed from the queue and will never run again
    func onRemove(result: JobCompletion)

}

/// Enum to specify a limit
public enum Limit {

    /// No limit
    case unlimited

    /// Limited to a specific number
    case limited(Int)

}
