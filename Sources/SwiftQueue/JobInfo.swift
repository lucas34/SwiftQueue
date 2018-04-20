//
// Created by Lucas Nelaupe on 13/12/17.
//

import Foundation

struct JobInfo {

    /// Type of job to create actual `Job` instance
    let type: String

    /// Unique identifier for a job
    var uuid: String

    /// Override job when scheduling a job with same uuid
    var override: Bool

    /// Queue name
    var group: String

    /// Set of identifiers
    var tags: Set<String>

    /// Delay for the first execution of the job
    var delay: TimeInterval?

    /// Cancel the job after a certain date
    var deadline: Date?

    /// Require a certain connectivity type
    var requireNetwork: NetworkType

    /// Indicates if the job should be persisted inside a database
    var isPersisted: Bool

    /// Custom params set by the user
    var params: [String: Any]

    /// Date of the job's creation
    var createTime: Date

    /// Time between each repetition of the job
    var interval: TimeInterval

    /// Number of run maximum
    var maxRun: Limit

    /// Maximum number of authorised retried
    var retries: Limit

    /// Current number of run
    var runCount: Double

    /// Current number of repetition. Transient value
    var currentRepetition: Int

    init(type: String,
         uuid: String = UUID().uuidString,
         override: Bool = false,
         group: String = "GLOBAL",
         tags: Set<String> = Set<String>(),
         delay: TimeInterval? = nil,
         deadline: Date? = nil,
         requireNetwork: NetworkType = NetworkType.any,
         isPersisted: Bool = false,
         params: [String: Any] = [:],
         createTime: Date = Date(),
         interval: TimeInterval = -1.0,
         maxRun: Limit = .limited(0),
         retries: Limit = .limited(0),
         runCount: Double = 0) {

        self.type = type
        self.uuid = uuid
        self.override = override
        self.group = group
        self.tags = tags
        self.delay = delay
        self.deadline = deadline
        self.requireNetwork = requireNetwork
        self.isPersisted = isPersisted
        self.params = params
        self.createTime = createTime
        self.interval = interval
        self.maxRun = maxRun
        self.retries = retries
        self.runCount = runCount

        /// Transient
        self.currentRepetition = 0
    }
}

extension JobInfo {

    init(dictionary: [String: Any]) throws {
        guard let type = dictionary["type"] as? String else {
            throw SwiftQueueError.parsingError("Unable to find Job.type")
        }

        self.init(type: type)

        dictionary.assign(&self.uuid, key: "uuid")
        dictionary.assign(&self.override, key: "override")

        dictionary.assign(&self.group, key: "group")

        dictionary.assign(&self.tags, key: "tags") { (array: [String]) -> Set<String> in Set(array) }

        dictionary.assign(&self.delay, key: "delay")
        dictionary.assign(&self.deadline, key: "deadline", dateFormatter.date)

        dictionary.assign(&self.requireNetwork, key: "requireNetwork") { NetworkType(rawValue: $0) }

        dictionary.assign(&self.isPersisted, key: "isPersisted")

        dictionary.assign(&self.params, key: "params")

        dictionary.assign(&self.createTime, key: "createTime", dateFormatter.date)

        dictionary.assign(&self.interval, key: "interval")
        dictionary.assign(&self.maxRun, key: "maxRun", Limit.fromRawValue)

        dictionary.assign(&self.retries, key: "retries", Limit.fromRawValue)

        dictionary.assign(&self.runCount, key: "runCount")
    }

    func toDictionary() -> [String: Any] {
        var dict = [String: Any]()
        dict["type"]           = self.type
        dict["uuid"]           = self.uuid
        dict["override"]       = self.override
        dict["group"]          = self.group
        dict["tags"]           = Array(self.tags)
        dict["delay"]          = self.delay
        dict["deadline"]       = self.deadline.map(dateFormatter.string)
        dict["requireNetwork"] = self.requireNetwork.rawValue
        dict["isPersisted"]    = self.isPersisted
        dict["params"]         = self.params
        dict["createTime"]     = dateFormatter.string(from: self.createTime)
        dict["runCount"]       = self.runCount
        dict["maxRun"]         = self.maxRun.rawValue
        dict["retries"]        = self.retries.rawValue
        dict["interval"]       = self.interval
        return dict
    }

}

extension Dictionary where Key == String {

    func assign<A>(_ variable: inout A, key: String) {
        if let value = self[key] as? A {
            variable = value
        }
    }

    func assign<A, B>(_ variable: inout B, key: String, _ transform: (A) -> B?) {
        if let value = self[key] as? A, let transformed = transform(value) {
            variable = transformed
        }
    }

}
