//
// Created by Lucas Nelaupe on 10/08/2017.
// Copyright (c) 2017 lucas34. All rights reserved.
//

import Foundation
import ReachabilitySwift

internal final class JobTask: Operation, JobResult {

    let handler: Job

    public let taskID: String
    public let jobType: String

    private let reachability = Reachability()

    let tags: Set<String>
    let delay: Int
    let deadline: Date?
    let requireNetwork: NetworkType
    let isPersisted: Bool
    let params: Any?
    let createTime: Date
    let interval: Double

    var runCount: Int
    var retries: Int

    internal var lastError: Swift.Error?

    var jobIsExecuting: Bool = false
    var jobIsFinished: Bool = false

    public override var name: String? { get { return taskID } set { } }

    public override var isExecuting: Bool {
        get { return jobIsExecuting }
        set {
            willChangeValue(forKey: "isExecuting")
            jobIsExecuting = newValue
            didChangeValue(forKey: "isExecuting")
        }
    }
    public override var isFinished: Bool {
        get { return jobIsFinished }
        set {
            willChangeValue(forKey: "isFinished")
            jobIsFinished = newValue
            didChangeValue(forKey: "isFinished")
        }
    }

    internal init(job: Job, taskID: String = UUID().uuidString, jobType: String, tags: Set<String>,
                  delay: Int, deadline: Date?, requireNetwork: NetworkType, isPersisted: Bool, params: Any?,
                  createTime: Date, runCount: Int, retries: Int, interval: Double) {
        self.handler = job
        self.taskID = taskID
        self.jobType = jobType
        self.tags = tags
        self.delay = delay
        self.deadline = deadline
        self.requireNetwork = requireNetwork
        self.isPersisted = isPersisted
        self.params = params
        self.createTime = createTime
        self.runCount = runCount
        self.retries = retries
        self.interval = interval

        super.init()

        self.queuePriority = .normal
        self.qualityOfService = .utility
    }

    private convenience init?(dictionary: [String: Any], creator: [JobCreator]) {
        let params = dictionary["params"] ?? nil
        if let taskID         = dictionary["taskID"] as? String,
           let jobType        = dictionary["jobType"] as? String,
           let tags           = dictionary["tags"] as? [String],
           let delay          = dictionary["delay"] as? Int,
           let deadlineStr    = dictionary["deadline"] as? String?,
           let requireNetwork = dictionary["requireNetwork"] as? Int,
           let isPersisted    = dictionary["isPersisted"] as? Bool,
           let createTimeStr  = dictionary["createTime"] as? String,
           let runCount       = dictionary["runCount"] as? Int,
           let retries        = dictionary["retries"] as? Int,
           let interval       = dictionary["interval"] as? Double,
           let job = SwiftQueue.createHandler(creators: creator, jobType: jobType, params: params) {

            let deadline   = deadlineStr.flatMap { dateFormatter.date(from: $0) }
            let createTime = dateFormatter.date(from: createTimeStr) ?? Date()
            let network    = NetworkType(rawValue: requireNetwork) ?? NetworkType.any

            self.init(job: job, taskID: taskID, jobType: jobType, tags: Set(tags),
                    delay: delay, deadline: deadline, requireNetwork: network,
                    isPersisted: isPersisted, params: params, createTime: createTime,
                    runCount: runCount, retries: retries, interval: interval)
        } else {
            return nil
        }
    }

/**
Initializes a JobQueueTask from JSON

- parameter json:    JSON from which the reconstruct the task
- parameter queue:   The queue that the task will execute on

- returns: A new JobQueueTask
*/
    internal convenience init?(json: String, creator: [JobCreator]) {
        do {
            if let dict = try fromJSON(json) as? [String: AnyObject] {
                self.init(dictionary: dict, creator: creator)
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }

/**
Deconstruct the task to a dictionary, used to serialize the task

- returns: A Dictionary representation of the task
*/
    private func toDictionary() -> [String: Any] {
        var dict = [String: Any]()
        dict["taskID"]         = self.taskID
        dict["jobType"]        = self.jobType
        dict["tags"]           = Array(self.tags)
        dict["delay"]          = self.delay
        dict["deadline"]       = self.deadline.map { dateFormatter.string(from: $0) }
        dict["requireNetwork"] = self.requireNetwork.rawValue
        dict["isPersisted"]    = self.isPersisted
        dict["params"]         = self.params
        dict["createTime"]     = dateFormatter.string(from: self.createTime)
        dict["runCount"]       = self.runCount
        dict["retries"]        = self.retries
        dict["interval"]       = self.interval
        return dict
    }

/**
Deconstruct the task to a JSON string, used to serialize the task

- returns: A JSON string representation of the task
*/
    public func toJSONString() -> String? {
        do {
            return try toJSON(obj: toDictionary())
        } catch {
            return nil
        }
    }

    public override func start() {
        super.start()
        isExecuting = true
        run()
    }

    public override func cancel() {
        lastError = lastError ?? Canceled()
        isFinished = true
        super.cancel()
    }

    // cancel before schedule and serialise
    internal func abort(error: Swift.Error) {
        lastError = error
        // Need to be called manually since the task is actually not in the queue. So cannot call cancel()
        handler.onCancel()
    }

    private func run() {
        if isCancelled && !isFinished {
            isFinished = true
        }
        if isFinished {
            return
        }
        // Check the constraint
        do {
            try Constraints.checkConstraintsForRun(task: self)
            switch requireNetwork {
            case .any:
                break // Continue function
            case .cellular:
                guard let reachability = reachability, !reachability.isReachable else {
                    break // Continue
                }
                reachability.whenReachable = { reachability in
                    reachability.whenReachable = nil
                    self.run()
                }
                return // Stop run function
            case .wifi:
                guard let reachability = reachability, !reachability.isReachableViaWiFi else {
                    break // Continue

                }
                reachability.whenReachable = { reachability in
                    // Change network
                    reachability.whenReachable = nil
                    self.run()
                }
                return // Stop run function
            }

            if Date().timeIntervalSince(createTime) > TimeInterval(delay) {
                try handler.onRunJob(callback: self)
            } else {
                runInBackgroundAfter(TimeInterval(interval)) {
                    self.run()
                }
            }

        } catch (let error) {
            onDone(error: error)
        }
    }

    internal func taskComplete() {
        if lastError == nil {
            handler.onComplete()
        } else {
            handler.onCancel()
        }
    }

    public func onDone(error: Swift.Error?) {
        // Check to make sure we're even executing, if not
        // just ignore the completed call
        if !isExecuting {
            return
        }

        if let error = error {
            lastError = error

            guard retries > 0 else {
                cancel()
                return
            }

            let retry = handler.onError(error: error)
            switch retry {
            case .cancel:
                cancel()
                break
            case .retry:
                retries -= 1
                run()
                break

            }
        } else {
            lastError = nil
            runCount -= 1
            if runCount <= 0 {
                isFinished = true
            } else {
                runInBackgroundAfter(TimeInterval(interval)) {
                    self.run()
                }
            }
        }
    }
}
