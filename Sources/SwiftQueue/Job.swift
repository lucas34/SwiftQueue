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
        self.info = JobInfo(type: type)
    }

    /// Get job type
    public var type: String {
        return info.type
    }

    /// Allow only 1 job at the time with this ID scheduled or running
    /// Same job scheduled with same id will result in onRemove(TaskAlreadyExist) if override = false
    /// If override = true the previous job will be canceled and the new job will be scheduled
    public func singleInstance(forId: String, override: Bool = false) -> JobBuilder {
        info.uuid = forId
        info.override = override
        return self
    }

    /// Get uuid for single instance job
    public var uuid: String {
        return info.uuid
    }

    /// Job in different groups can run in parallel
    public func group(name: String) -> JobBuilder {
        info.group = name
        return self
    }

    /// Get job group name
    public var groupName: String {
        return info.group
    }

    /// Delay the execution of the job.
    /// Only start the countdown when the job should run and not when scheduled
    public func delay(time: TimeInterval) -> JobBuilder {
        info.delay = time
        return self
    }

    /// Get job delay time
    public var delayTime: TimeInterval {
        return info.delay ?? 0
    }

    /// Job should be removed from the queue after a certain date
    public func deadline(date: Date) -> JobBuilder {
        info.deadline = date
        return self
    }

    /// Get job dead line
    public var deadline: Date? {
        return info.deadline
    }

    /// Repeat job a certain number of time and with a interval between each run 
    /// count -1 by default for unlimited periodic and immediate
    public func periodic(count: Int = -1, interval: TimeInterval = 0) -> JobBuilder {
        info.maxRun = count
        info.interval = interval
        return self
    }

    /// Get maximum run count for periodic job
    public var maxRun: Int {
        return info.maxRun
    }

    /// Get interval for periodic job
    public var interval: TimeInterval {
        return info.interval
    }

    /// Connectivity constraint.
    public func internet(atLeast: NetworkType) -> JobBuilder {
        info.requireNetwork = atLeast
        return self
    }

    /// Get job network requirement
    public var requireNetwork: NetworkType {
        return info.requireNetwork
    }

    /// Job should be persisted. 
    public func persist(required: Bool) -> JobBuilder {
        info.isPersisted = required
        return self
    }

    /// Get whether the job should be persisted
    public var persist: Bool {
        return info.isPersisted
    }

    /// Max number of authorised retry before the job is removed
    public func retry(max: Int) -> JobBuilder {
        info.retries = max
        return self
    }

    /// Get job max retries
    public var maxRetries: Int {
        return info.retries
    }

    /// Custom tag to mark the job
    public func addTag(tag: String) -> JobBuilder {
        info.tags.insert(tag)
        return self
    }

    /// Get job tags
    public var tag: Set<String> {
        return info.tags
    }

    /// Custom parameters will be forwarded to create method
    public func with(params: [String: Any]) -> JobBuilder {
        info.params = params
        return self
    }

    /// Get job params
    public var params: [String: Any] {
        return info.params
    }

    internal func build(job: Job) -> SwiftQueueJob {
        return SwiftQueueJob(job: job, info: info)
    }

    /// Add job to the JobQueue
    public func schedule(manager: SwiftQueueManager) {
        let queue = manager.getQueue(name: info.group)
        guard let job = queue.createHandler(type: info.type, params: info.params) else {
            assertionFailure("No job creator associate to job type \(info.type)")
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
