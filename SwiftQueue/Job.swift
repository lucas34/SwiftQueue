//
// Created by Lucas Nelaupe on 10/08/2017.
// Copyright (c) 2017 lucas34. All rights reserved.
//

import Foundation

public final class JobBuilder {

    private let taskID: String
    private let jobType: String

    private var tags = Set<String>()
    private var delay: Int = 0
    private var deadline: Date?
    private var needInternet: Bool = false
    private var isPersisted: Bool = false
    private var params: Any?
    private var createTime: Date = Date()
    private var runCount: Int = 1
    private var retries: Int = 0
    private var interval: Double = -1.0

    public init(taskID: String = UUID().uuidString, jobType: String) {
        self.taskID = taskID
        self.jobType = jobType
    }

    public func delay(inSecond: Int) -> JobBuilder {
        delay = inSecond
        return self
    }

    public func deadline(date: Date) -> JobBuilder {
        deadline = date
        return self
    }

    public func periodic(count: Int = Int.max, interval: Double = 0) -> JobBuilder {
        runCount = count
        self.interval = interval
        return self
    }

    public func internet(required: Bool) -> JobBuilder {
        needInternet = required
        return self
    }

    public func persist(required: Bool) -> JobBuilder {
        isPersisted = required
        return self
    }

    public func retry(max: Int) -> JobBuilder {
        retries = max
        return self
    }

    public func addTag(tag: String) -> JobBuilder {
        tags.insert(tag)
        return self
    }

    public func with(params: Any) -> JobBuilder {
        self.params = params
        return self
    }

    internal func build(job: Job) -> JobTask {
        return JobTask(job: job, taskID: taskID, jobType: jobType, tags: tags,
                delay: delay, deadline: deadline, needInternet: needInternet, isPersisted: isPersisted, params: params,
                createTime: createTime, runCount: runCount, retries: retries, interval: interval)
    }

    public func schedule(queue: SwiftQueue) {
        guard let job = queue.createHandler(jobType: jobType, params: params) else {
            print("WARN: Not job creator associate to job type \(jobType)") // log maybe
            return
        }
        queue.addOperation(build(job: job))
    }
}

public protocol JobResult {

    func onDone(error: Swift.Error?)

}

public enum RetryConstraint {
    case retry
    case cancel
}

public protocol Job {

    func onRunJob(callback: JobResult) throws

    func onError(error: Swift.Error) -> RetryConstraint

    func onComplete() // Job removed

    func onCancel() // Job removed
}
