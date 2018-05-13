//
// Created by Lucas Nelaupe on 23/1/18.
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
    /// Same job scheduled with same id will result in onRemove(SwiftQueueError.duplicate) if override = false
    /// If override = true the previous job will be canceled and the new job will be scheduled
    public func singleInstance(forId: String, override: Bool = false) -> Self {
        assertNotEmptyString(forId)
        info.uuid = forId
        info.override = override
        return self
    }

    /// Job in different groups can run in parallel
    public func group(name: String) -> Self {
        assertNotEmptyString(name)
        info.group = name
        return self
    }

    /// Delay the execution of the job.
    /// Base on the job creation, when the job is supposed to run,
    /// If the delay is already pass (longer job before) it will run immediately
    /// Otherwise it will wait for the remaining time
    public func delay(time: TimeInterval) -> Self {
        assert(time >= 0)
        info.delay = time
        return self
    }

    /// If the job hasn't run after the date, It will be removed
    /// will call onRemove(SwiftQueueError.deadline)
    public func deadline(date: Date) -> Self {
        info.deadline = date
        return self
    }

    /// Repeat job a certain number of time and with a interval between each run
    /// Limit of period to reproduce
    /// interval between each run. Does not affect the first iteration. Please add delay if so
    public func periodic(limit: Limit = .unlimited, interval: TimeInterval = 0) -> Self {
        assert(limit.validate)
        assert(interval >= 0)
        info.maxRun = limit
        info.interval = interval
        return self
    }

    /// Connectivity constraint.
    public func internet(atLeast: NetworkType) -> Self {
        info.requireNetwork = atLeast
        return self
    }

    /// Job should be persisted. 
    public func persist(required: Bool) -> Self {
        info.isPersisted = required
        return self
    }

    /// Limit number of retry. Overall for the lifecycle of the SwiftQueueManager.
    /// For a periodic job, the retry count will not be reset at each period. 
    public func retry(limit: Limit) -> Self {
        assert(limit.validate)
        info.retries = limit
        return self
    }

    /// Custom tag to mark the job
    public func addTag(tag: String) -> Self {
        assertNotEmptyString(tag)
        info.tags.insert(tag)
        return self
    }

    /// Custom parameters will be forwarded to create method
    public func with(params: [String: Any]) -> Self {
        info.params = params
        return self
    }

    /// Set to `true` if the job can only run when the device is charging
    public func requireCharging(value: Bool) -> Self {
        info.requireCharging = value
        return self
    }

    internal func build(job: Job, logger: SwiftQueueLogger) -> SqOperation {
        return SqOperation(job: job, info: info, logger: logger)
    }

    /// Add job to the JobQueue
    public func schedule(manager: SwiftQueueManager) {
        if info.isPersisted {
            // Check if we will be able to serialize args
            assert(JSONSerialization.isValidJSONObject(info.params))
        }

        let queue = manager.getQueue(queueName: info.group)
        let job = queue.createHandler(type: info.type, params: info.params)

        queue.addOperation(build(job: job, logger: manager.logger))
    }
}
