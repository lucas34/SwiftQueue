//
// Created by Lucas Nelaupe on 10/08/2017.
// Copyright (c) 2017 lucas34. All rights reserved.
//

import Foundation

public class JobTask: Operation, JobResult {
//    static let MIN_RETRY_DELAY = 0.2
//    static let MAX_RETRY_DELAY = 60.0

    let handler: Job

    public let taskID: String
    public let jobType: String

    var tags: Set<String>
    var delay: Int
    var deadline: Date?
    var needInternet: Bool
    var isPersisted: Bool
    var params: Any?
    var createTime: Date
    var runCount: Int
    var retries: Int = 1
    var interval: Double

    internal var lastError: Swift.Error?

    var _executing: Bool = false
    var _finished: Bool = false

    public override var name: String? { get { return taskID } set { } }
    public override var isAsynchronous: Bool { return true }

    public override var isExecuting: Bool {
        get { return _executing }
        set {
            willChangeValue(forKey: "isExecuting")
            _executing = newValue
            didChangeValue(forKey: "isExecuting")
        }
    }
    public override var isFinished: Bool {
        get { return _finished }
        set {
            willChangeValue(forKey: "isFinished")
            _finished = newValue
            didChangeValue(forKey: "isFinished")
        }
    }

    internal init(job: Job, taskID: String = UUID().uuidString, jobType: String, tags: Set<String>,
                  delay: Int, deadline: Date?, needInternet: Bool, isPersisted: Bool, params: Any?,
                  createTime: Date, runCount: Int, retries: Int, interval: Double) {
        self.handler = job
        self.taskID = taskID
        self.jobType = jobType
        self.tags = tags
        self.delay = delay
        self.deadline = deadline
        self.needInternet = needInternet
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
        if let taskID        = dictionary["taskID"] as? String,
           let jobType       = dictionary["jobType"] as? String,
           let tags          = dictionary["tags"] as? [String],
           let delay         = dictionary["delay"] as? Int,
           let deadlineStr   = dictionary["deadline"] as? String?,
           let needInternet  = dictionary["needInternet"] as? Bool,
           let isPersisted   = dictionary["isPersisted"] as? Bool,
//           let params        = dictionary["params"] as? Any ?? nil,
           let createTimeStr = dictionary["createTime"] as? String,
           let runCount      = dictionary["runCount"] as? Int,
           let retries       = dictionary["retries"] as? Int,
           let interval      = dictionary["interval"] as? Double,
           let job = JobQueue.createHandler(creators: creator, jobType: jobType, params: nil) {

            let deadline   = deadlineStr.flatMap { dateFormatter.date(from: $0) }
            let createTime = dateFormatter.date(from: createTimeStr) ?? Date()

            self.init(job: job, taskID: taskID, jobType: jobType, tags: Set(tags),
                    delay: delay, deadline: deadline, needInternet: needInternet,
                    isPersisted: isPersisted, params: nil, createTime: createTime,
                    runCount: runCount, retries: retries, interval: interval)
        } else {
//            self.init(queue: queue, taskID: "", taskType: "")
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
        dict["taskID"]       = self.taskID
        dict["jobType"]      = self.jobType
        dict["tags"]         = Array(self.tags)
        dict["delay"]        = self.delay
        dict["deadline"]     = self.deadline.map { dateFormatter.string(from: $0) }
        dict["needInternet"] = self.needInternet
        dict["isPersisted"]  = self.isPersisted
        dict["params"]       = self.params
        dict["createTime"]   = dateFormatter.string(from: self.createTime)
        dict["runCount"]     = self.runCount
        dict["retries"]      = self.retries
        dict["interval"]     = self.interval
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
        isFinished = true
        handler.onCancel() // Need to be called manually since the task is actually not in the queue. So cannot call cancel()
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
            try handler.onRunJob(callback: self)
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
            if error is ConstraintError {
                // Constraint are immutable. One of the constraint canceled the job
                // Since we cannot do anything, just notify the job
                _ = handler.onError(error: error)
                // Will never run anymore
                cancel()
                return
            }

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
