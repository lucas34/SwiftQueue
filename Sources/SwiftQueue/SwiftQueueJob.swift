//
// Created by Lucas Nelaupe on 10/08/2017.
// Copyright (c) 2017 lucas34. All rights reserved.
//

import Foundation

internal final class SwiftQueueJob: Operation, JobResult {

    let handler: Job

    public let uuid: String
    public let type: String
    public let group: String

    let tags: Set<String>
    let delay: TimeInterval?
    let deadline: Date?
    let requireNetwork: NetworkType
    let isPersisted: Bool
    let params: Any?
    let createTime: Date
    let interval: TimeInterval

    let constraints: [JobConstraint]

    var runCount: Int
    var maxRun: Int
    var retries: Int

    internal var lastError: Swift.Error?

    public override var name: String? { get { return uuid } set { } }

    private var jobIsExecuting: Bool = false
    public override var isExecuting: Bool {
        get { return jobIsExecuting }
        set {
            willChangeValue(forKey: "isExecuting")
            jobIsExecuting = newValue
            didChangeValue(forKey: "isExecuting")
        }
    }

    private var jobIsFinished: Bool = false
    public override var isFinished: Bool {
        get { return jobIsFinished }
        set {
            willChangeValue(forKey: "isFinished")
            jobIsFinished = newValue
            didChangeValue(forKey: "isFinished")
        }
    }

    internal init(job: Job, uuid: String = UUID().uuidString, type: String, group: String, tags: Set<String>,
                  delay: TimeInterval?, deadline: Date?, requireNetwork: NetworkType, isPersisted: Bool, params: Any?,
                  createTime: Date, runCount: Int, maxRun: Int, retries: Int, interval: Double) {
        self.handler = job
        self.uuid = uuid
        self.type = type
        self.group = group
        self.tags = tags
        self.delay = delay
        self.deadline = deadline
        self.requireNetwork = requireNetwork
        self.isPersisted = isPersisted
        self.params = params
        self.createTime = createTime
        self.runCount = runCount
        self.maxRun = maxRun
        self.retries = retries
        self.interval = interval

        self.constraints = [
            DeadlineConstraint(),
            DelayConstraint(),
            UniqueUUIDConstraint(),
            NetworkConstraint()
        ]

        super.init()

        self.queuePriority = .normal
        self.qualityOfService = .utility

    }

    override func start() {
        super.start()
        isExecuting = true
        run()
    }

    override func cancel() {
        lastError = Canceled()
        onTerminate()
        super.cancel()
    }

    private func onTerminate() {
        if isExecuting {
            isFinished = true
        }
    }

    // cancel before schedule and serialise
    internal func abort(error: Swift.Error) {
        lastError = error
        // Need to be called manually since the task is actually not in the queue. So cannot call cancel()
        handler.onRemove(error: error)
    }

    internal func run() {
        if isCancelled && !isFinished {
            isFinished = true
        }
        if isFinished {
            return
        }

        do {
            try self.willRunJob()
        } catch (let error) {
            // Will never run again
            lastError = error
            onTerminate()
        }

        guard self.checkIfJobCanRunNow() else {
            // Constraint fail.
            // Constraint will call run when it's ready
            return
        }

        do {
            try handler.onRun(callback: self)
        } catch (let error) {
            onDone(error: error)
        }
    }

    internal func completed() {
        handler.onRemove(error: lastError)
    }

    public func onDone(error: Swift.Error?) {
        if let error = error {
            lastError = error

            guard retries > 0 else {
                onTerminate()
                return
            }

            let retry = handler.onRetry(error: error)
            switch retry {
            case .cancel:
                cancel()
            case .retry(let after):
                retries -= 1
                if after > 0 {
                    runInBackgroundAfter(after, callback: self.run)
                } else {
                    self.run()
                }
            case .exponential(let initial):
                let decimal: NSDecimalNumber = NSDecimalNumber(decimal: Decimal(initial) * pow(2, max(0, runCount - 1)))
                runInBackgroundAfter(TimeInterval(decimal)) {
                    self.retries -= 1
                    self.run()
                }
            }
        } else {
            lastError = nil
            runCount += 1
            if maxRun >= 0 && runCount >= maxRun {
                onTerminate()
            } else {
                if interval > 0 {
                    runInBackgroundAfter(interval, callback: self.run)
                } else {
                    self.run()
                }
            }
        }
    }
}

extension SwiftQueueJob {

    convenience init?(dictionary: [String: Any], creator: [JobCreator]) {
        let params = dictionary["params"]
        if let uuid            = dictionary["uuid"] as? String,
           let type           = dictionary["type"] as? String,
           let group          = dictionary["group"] as? String,
           let tags           = dictionary["tags"] as? [String],
           let delay          = dictionary["delay"] as? TimeInterval?,
           let deadlineStr    = dictionary["deadline"] as? String?,
           let requireNetwork = dictionary["requireNetwork"] as? Int,
           let isPersisted    = dictionary["isPersisted"] as? Bool,
           let createTimeStr  = dictionary["createTime"] as? String,
           let runCount       = dictionary["runCount"] as? Int,
           let maxRun         = dictionary["maxRun"] as? Int,
           let retries        = dictionary["retries"] as? Int,
           let interval       = dictionary["interval"] as? TimeInterval,
           let job = SwiftQueue.createHandler(creators: creator, type: type, params: params) {

            let deadline   = deadlineStr.flatMap(dateFormatter.date)
            let createTime = dateFormatter.date(from: createTimeStr) ?? Date()
            let network    = NetworkType(rawValue: requireNetwork) ?? NetworkType.any

            self.init(job: job, uuid: uuid, type: type, group: group, tags: Set(tags),
                    delay: delay, deadline: deadline, requireNetwork: network,
                    isPersisted: isPersisted, params: params, createTime: createTime,
                    runCount: runCount, maxRun: maxRun, retries: retries, interval: interval)
        } else {
            return nil
        }
    }

    convenience init?(json: String, creator: [JobCreator]) {
        let dict = fromJSON(json) as? [String: Any] ?? [:]
        self.init(dictionary: dict, creator: creator)
    }

    func toDictionary() -> [String: Any] {
        var dict = [String: Any]()
        dict["uuid"]           = self.uuid
        dict["type"]           = self.type
        dict["group"]          = self.group
        dict["tags"]           = Array(self.tags)
        dict["delay"]          = self.delay
        dict["deadline"]       = self.deadline.map(dateFormatter.string)
        dict["requireNetwork"] = self.requireNetwork.rawValue
        dict["isPersisted"]    = self.isPersisted
        dict["params"]         = self.params
        dict["createTime"]     = dateFormatter.string(from: self.createTime)
        dict["runCount"]       = self.runCount
        dict["maxRun"]         = self.maxRun
        dict["retries"]        = self.retries
        dict["interval"]       = self.interval
        return dict
    }

    func toJSONString() -> String? {
        return toJSON(toDictionary())
    }

}

extension SwiftQueueJob {

    func willScheduleJob(queue: SwiftQueue) throws {
        for constraint in self.constraints {
            try constraint.willSchedule(queue: queue, operation: self)
        }
    }

    func willRunJob() throws {
        for constraint in self.constraints {
            try constraint.willRun(operation: self)
        }
    }

    func checkIfJobCanRunNow() -> Bool {
        for constraint in self.constraints {
            if !constraint.run(operation: self) {
                return false
            }
        }
        return true
    }

}
