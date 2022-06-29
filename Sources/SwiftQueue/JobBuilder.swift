// The MIT License (MIT)
//
// Copyright (c) 2022 Lucas Nelaupe
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

    internal var info: JobInfo

    /// Type of your job that you will receive in JobCreator.create(type)
    public init(type: String) {
        assertNotEmptyString(type)
        self.info = JobInfo(type: type)
    }

    /// Create a copy of another job params
    public init(jobBuilder: JobBuilder) {
        self.info = jobBuilder.info
    }

    /// Allow only 1 job at the time with this ID scheduled or running if includeExecutingJob is true
    /// Same job scheduled with same id will result in onRemove(SwiftQueueError.duplicate) if override = false
    /// If override = true the previous job will be canceled and the new job will be scheduled
    public func singleInstance(forId: String, override: Bool = false, includeExecutingJob: Bool = true) -> Self {
        assertNotEmptyString(forId)
        info.constraints.append(UniqueUUIDConstraint(uuid: forId, override: override, includeExecutingJob: includeExecutingJob))
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
        info.constraints.append(DelayConstraint(delay: time))
        return self
    }

    /// If the job hasn't run after the date, It will be removed
    /// will call onRemove(SwiftQueueError.deadline)
    public func deadline(date: Date) -> Self {
        info.constraints.append(DeadlineConstraint(deadline: date))
        return self
    }

    /// Repeat job a certain number of time and with a interval between each run
    /// Limit of period to reproduce
    /// interval between each run. Does not affect the first iteration. Please add delay if so
    /// executor will make the job being scheduling to run in background with BackgroundTask API
    public func periodic(limit: Limit = .unlimited, interval: TimeInterval = 0) -> Self {
        assert(limit.validate)
        assert(interval >= 0)
        info.constraints.append(RepeatConstraint(maxRun: limit, interval: interval, executor: .foreground))
        return self
    }

    @available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
    public func periodic(limit: Limit = .unlimited, interval: TimeInterval = 0, executor: Executor = .foreground) -> Self {
        assert(limit.validate)
        assert(interval >= 0)
        info.constraints.append(RepeatConstraint(maxRun: limit, interval: interval, executor: executor))
        return self
    }

    /// Connectivity constraint.
    public func internet(atLeast: NetworkType) -> Self {
        assert(atLeast != .any)
        info.constraints.append(NetworkConstraint(networkType: atLeast))
        return self
    }

    private var requirePersist = false

    /// Job should be persisted.
    public func persist() -> Self {
        requirePersist = true
        return self
    }

    /// Limit number of retry. Overall for the lifecycle of the SwiftQueueManager.
    /// For a periodic job, the retry count will not be reset at each period.
    public func retry(limit: Limit) -> Self {
        assert(limit.validate)
        info.constraints.append(JobRetryConstraint(limit: limit))
        return self
    }

    /// Custom tag to mark the job
    public func addTag(tag: String) -> Self {
        if let constraint: TagConstraint = getConstraint(info.constraints) {
            constraint.insert(tag: tag)
            return self
        }

        var set = Set<String>()
        set.insert(tag)

        info.constraints.append(TagConstraint(tags: set))
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

    /// Call if job can only run when the device is charging
    public func requireCharging() -> Self {
        info.constraints.append(BatteryChargingConstraint())
        return self
    }

    /// Maximum time in second that the job is allowed to run
    public func timeout(value: TimeInterval) -> Self {
        info.constraints.append(TimeoutConstraint(timeout: value))
        return self
    }

    /// Add custom constraint. If your job is persisted, your constraint may extend CodableConstraint
    /// and should be registered with ConstraintMaker
    public func add(constraint: JobConstraint) -> Self {
        info.constraints.append(constraint)
        return self
    }

    /// Create copy of current job builder
    public func copy() -> JobBuilder {
        return JobBuilder(jobBuilder: self)
    }

    /// Get the JobInfo built
    public func build() -> JobInfo {
        return info
    }

    /// Add job to the JobQueue
    public func schedule(manager: SwiftQueueManager) {
        if requirePersist {
            let constraint: UniqueUUIDConstraint? = getConstraint(info)
            if constraint == nil {
                info.constraints.append(UniqueUUIDConstraint(uuid: UUID().uuidString, override: false, includeExecutingJob: false))
            }
            assert(JSONSerialization.isValidJSONObject(info.params))
            info.constraints.append(PersisterConstraint(serializer: manager.params.serializer, persister: manager.params.persister))
        }
        manager.enqueue(info: info)
    }

}
