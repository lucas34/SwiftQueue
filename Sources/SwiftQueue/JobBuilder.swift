// The MIT License (MIT)
//
// Copyright (c) 2017 Lucas Nelaupe
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

/// Builder to create your job with behaviour
public final class JobBuilder {

    private var info: JobInfo

    /// Type of your job that you will receive in JobCreator.create(type)
    public init(type: String) {
        assertNotEmptyString(type)
        self.info = JobInfo(type: type)
    }

    /// Allow only 1 job at the time with this ID scheduled or running if includeExecutingJob is true
    /// Same job scheduled with same id will result in onRemove(SwiftQueueError.duplicate) if override = false
    /// If override = true the previous job will be canceled and the new job will be scheduled
    public func singleInstance(forId: String, override: Bool = false, includeExecutingJob: Bool = true) -> Self {
        assertNotEmptyString(forId)
        info.uuid = forId
        info.override = override
        info.includeExecutingJob = includeExecutingJob
        return self
    }

    /// Job in different groups can run in parallel
    @available(*, deprecated, renamed: "parallel")
    public func group(name: String) -> Self {
        assertNotEmptyString(name)
        info.queueName = name
        return self
    }

    /// Job in different groups can run in parallel
    public func parallel(queueName: String) -> Self {
        assertNotEmptyString(queueName)
        info.queueName = queueName
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
    public func periodic(limit: Limit = .unlimited, interval: TimeInterval = 0, allowBackground: Bool = false) -> Self {
        assert(limit.validate)
        assert(interval >= 0)
        info.maxRun = limit
        info.interval = interval
        info.allowBackground = allowBackground
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

    /// Set priority of the job. May affect execution order
    public func priority(priority: Operation.QueuePriority) -> Self {
        info.priority = priority
        return self
    }

    /// Set quality of service to define importance of the job system wise
    public func service(quality: QualityOfService) -> Self {
        info.qualityOfService = quality
        return self
    }

    /// Set to `true` if the job can only run when the device is charging
    public func requireCharging(value: Bool) -> Self {
        info.requireCharging = value
        return self
    }

    /// Maximum time in second that the job is allowed to run
    public func timeout(value: TimeInterval) -> Self {
        info.timeout = value
        return self
    }

    /// Get the JobInfo built
    public func build() -> JobInfo {
        return info
    }

    /// Add job to the JobQueue
    public func schedule(manager: SwiftQueueManager) {
        if info.isPersisted {
            // Check if we will be able to serialize args
            assert(JSONSerialization.isValidJSONObject(info.params))
        }

        manager.enqueue(info: info)
    }
}
