//
// Created by Lucas Nelaupe on 10/08/2017.
// Copyright (c) 2017 lucas34. All rights reserved.
//

import Foundation
#if os(iOS) || os(macOS) || os(tvOS)
import Reachability
#endif

internal final class SwiftQueueJob: Operation, JobResult {

    let handler: Job

    public let uuid: String
    public let type: String
    public let group: String

#if os(iOS) || os(macOS) || os(tvOS)
    private let reachability: Reachability?
#endif

    let tags: Set<String>
    let delay: Int
    let deadline: Date?
    let requireNetwork: NetworkType
    let isPersisted: Bool
    let params: Any?
    let createTime: Date
    let interval: TimeInterval

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
                  delay: Int, deadline: Date?, requireNetwork: NetworkType, isPersisted: Bool, params: Any?,
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

#if os(iOS) || os(macOS) || os(tvOS)
        self.reachability = requireNetwork.rawValue > NetworkType.any.rawValue ? Reachability() : nil
#endif

        super.init()

        self.queuePriority = .normal
        self.qualityOfService = .utility

#if os(iOS) || os(macOS) || os(tvOS)
        try? reachability?.startNotifier()
#endif
    }

#if os(iOS) || os(macOS) || os(tvOS)
    deinit {
        reachability?.stopNotifier()
    }
#endif

    internal convenience init?(json: String, creator: [JobCreator]) {
        let dict = fromJSON(json) as? [String: Any] ?? [:]
        self.init(dictionary: dict, creator: creator)
    }

    public func toJSONString() -> String? {
        return toJSON(toDictionary())
    }

    public override func start() {
        super.start()
        isExecuting = true
        run()
    }

    public override func cancel() {
        lastError = lastError ?? Canceled()
        if isExecuting {
            isFinished = true
        }
        super.cancel()
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

        // Check the constraint
        do {
            try Constraints.checkConstraintsForRun(job: self)
            guard networkIsReady() else {
                return
            }

            if Date().timeIntervalSince(createTime) > TimeInterval(delay) {
                try handler.onRun(callback: self)
            } else {
                runInBackgroundAfter(TimeInterval(interval)) {
                    self.run()
                }
            }

        } catch (let error) {
            onDone(error: error)
        }
    }

    internal func networkIsReady() -> Bool {
#if os(iOS) || os(macOS) || os(tvOS)
        func checkIsReachable() -> Bool {
            guard let reachability = reachability else {
                return true
            }
            switch requireNetwork {
            case .any:
                return true
            case .cellular:
                return reachability.isReachable
            case .wifi:
                return reachability.isReachableViaWiFi
            }
        }

        func waitForNetwork() {
            reachability?.whenReachable = { reachability in
                // Change network
                reachability.whenReachable = nil
                self.run()
            }
        }

        guard checkIsReachable() else {
            waitForNetwork()
            return false
        }
#endif
        return true
    }

    internal func completed() {
        handler.onRemove(error: lastError)
    }

    public func onDone(error: Swift.Error?) {
        if let error = error {
            lastError = error

            guard retries > 0 else {
                cancel()
                return
            }

            let retry = handler.onRetry(error: error)
            switch retry {
            case .cancel:
                cancel()
            case .retry(let delay):
                retries -= 1
                runInBackgroundAfter(delay) {
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
                isFinished = true
            } else {
                runInBackgroundAfter(interval) {
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
           let delay          = dictionary["delay"] as? Int,
           let deadlineStr    = dictionary["deadline"] as? String?,
           let requireNetwork = dictionary["requireNetwork"] as? Int,
           let isPersisted    = dictionary["isPersisted"] as? Bool,
           let createTimeStr  = dictionary["createTime"] as? String,
           let runCount       = dictionary["runCount"] as? Int,
           let maxRun         = dictionary["maxRun"] as? Int,
           let retries        = dictionary["retries"] as? Int,
           let interval       = dictionary["interval"] as? TimeInterval,
           let job = SwiftQueue.createHandler(creators: creator, type: type, params: params) {

            let deadline   = deadlineStr.flatMap { dateFormatter.date(from: $0) }
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

    func toDictionary() -> [String: Any] {
        var dict = [String: Any]()
        dict["uuid"]           = self.uuid
        dict["type"]           = self.type
        dict["group"]          = self.group
        dict["tags"]           = Array(self.tags)
        dict["delay"]          = self.delay
        dict["deadline"]       = self.deadline.map { dateFormatter.string(from: $0) }
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

}
