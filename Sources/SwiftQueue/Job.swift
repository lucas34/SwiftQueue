//
// Created by Lucas Nelaupe on 10/08/2017.
// Copyright (c) 2017 lucas34. All rights reserved.
//

import Foundation

public final class JobBuilder {

    private let type: String

    private var uuid: String =  UUID().uuidString
    private var group: String = "GLOBAL"
    private var tags = Set<String>()
    private var delay: TimeInterval?
    private var deadline: Date?
    private var requireNetwork: NetworkType = NetworkType.any
    private var isPersisted: Bool = false
    private var params: [String: Any]?
    private var createTime: Date = Date()
    private var maxRun: Int = 1
    private var retries: Int = 0
    private var interval: TimeInterval = -1.0

    public init(type: String) {
        self.type = type
    }

    public func singleInstance(forId: String) -> JobBuilder {
        self.uuid = forId
        return self
    }

    public func group(name: String) -> JobBuilder {
        self.group = name
        return self
    }

    public func delay(inSecond: Int) -> JobBuilder {
        delay = TimeInterval(inSecond)
        return self
    }

    public func delay(time: TimeInterval) -> JobBuilder {
        delay = time
        return self
    }

    public func deadline(date: Date) -> JobBuilder {
        deadline = date
        return self
    }

    public func periodic(count: Int = -1, interval: TimeInterval = 0) -> JobBuilder {
        maxRun = count
        self.interval = interval
        return self
    }

    public func internet(atLeast: NetworkType) -> JobBuilder {
        requireNetwork = atLeast
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

    public func with(params: [String: Any]) -> JobBuilder {
        self.params = params
        return self
    }

    internal func build(job: Job) -> SwiftQueueJob {
        return SwiftQueueJob(job: job, uuid: uuid, type: type, group: group, tags: tags,
                delay: delay, deadline: deadline, requireNetwork: requireNetwork, isPersisted: isPersisted,
                params: params, createTime: createTime, runCount: 0, maxRun: maxRun,
                retries: retries, interval: interval)
    }

    public func schedule(manager: SwiftQueueManager) {
        let queue = manager.getQueue(name: group)
        guard let job = queue.createHandler(type: type, params: params) else {
            assertionFailure("No job creator associate to job type \(type)")
            return
        }
        queue.addOperation(build(job: job))
    }
}

public protocol JobResult {

    func onDone(error: Swift.Error?)

}

public enum RetryConstraint {
    case retry(delay: TimeInterval)
    case cancel
    case exponential(initial: TimeInterval)
}

public protocol Job {

    func onRun(callback: JobResult)

    func onRetry(error: Swift.Error) -> RetryConstraint

    func onRemove(error: Swift.Error?)

}

public class Canceled: Swift.Error {}
