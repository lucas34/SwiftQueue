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

extension JobInfo: Decodable {

    enum JobInfoKeys: String, CodingKey {
        case type = "type"
        case uuid = "uuid"
        case override = "override"
        case group = "group"
        case tags = "tags"
        case delay = "delay"
        case deadline = "deadline"
        case requireNetwork = "requireNetwork"
        case isPersisted = "isPersisted"
        case params = "params"
        case createTime = "createTime"
        case interval = "runCount"
        case maxRun = "maxRun"
        case retries = "retries"
        case runCount = "interval"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JobInfoKeys.self)

        let type: String = try container.decode(String.self, forKey: .type)
        let uuid: String = try container.decode(String.self, forKey: .uuid)
        let override: Bool = try container.decode(Bool.self, forKey: .override)
        let group: String = try container.decode(String.self, forKey: .group)
        let tags: Set<String> = try container.decode(Set.self, forKey: .tags)
        let delay: TimeInterval? = try container.decodeIfPresent(TimeInterval.self, forKey: .delay)
        let deadline: Date? = try container.decodeIfPresent(Date.self, forKey: .deadline)
        let requireNetwork: NetworkType = try container.decode(NetworkType.self, forKey: .requireNetwork)
        let isPersisted: Bool = try container.decode(Bool.self, forKey: .isPersisted)
        let params: [String: Any] = try container.decode([String: Any].self, forKey: .params)
        let createTime: Date = try container.decode(Date.self, forKey: .createTime)
        let interval: TimeInterval = try container.decode(TimeInterval.self, forKey: .interval)
        let maxRun: Limit = try container.decode(Limit.self, forKey: .maxRun)
        let retries: Limit = try container.decode(Limit.self, forKey: .retries)
        let runCount: Double = try container.decode(Double.self, forKey: .runCount)

        self.init(
                type: type,
                uuid: uuid,
                override: override,
                group: group,
                tags: tags,
                delay: delay,
                deadline: deadline,
                requireNetwork: requireNetwork,
                isPersisted: isPersisted,
                params: params,
                createTime: createTime,
                interval: interval,
                maxRun: maxRun,
                retries: retries,
                runCount: runCount)
    }
}

extension JobInfo: Encodable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: JobInfoKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(override, forKey: .override)
        try container.encode(group, forKey: .group)
        try container.encode(tags, forKey: .tags)
        try container.encode(delay, forKey: .delay)
        try container.encode(deadline, forKey: .deadline)
        try container.encode(requireNetwork, forKey: .requireNetwork)
        try container.encode(isPersisted, forKey: .isPersisted)
        try container.encode(params, forKey: .params)
        try container.encode(createTime, forKey: .createTime)
        try container.encode(interval, forKey: .interval)
        try container.encode(maxRun, forKey: .maxRun)
        try container.encode(retries, forKey: .retries)
        try container.encode(runCount, forKey: .runCount)
    }
}

extension KeyedDecodingContainer {

    public func decode(_ type: Data.Type, forKey key: KeyedDecodingContainer.Key) throws -> Data {
        let json = try self.decode(String.self, forKey: key)
        guard let data = json.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [key],
                    debugDescription: "Unable to convert string to utf-8")
            )
        }
        return data
    }

    public func decode(_ type: [String: Any].Type, forKey key: KeyedDecodingContainer.Key) throws -> [String: Any] {
        let data = try self.decode(Data.self, forKey: key)
        guard let dict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [key],
                    debugDescription: "Decoded value is not a dictionary")
            )
        }
        return dict
    }

}

extension KeyedEncodingContainer {

    public mutating func encode(_ value: [String: Any], forKey key: KeyedEncodingContainer.Key) throws {
        let jsonData = try JSONSerialization.data(withJSONObject: value)
        guard let utf8 = String(data: jsonData, encoding: .utf8) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [key],
                    debugDescription: "The given data was not valid JSON.")
            )
        }
        try self.encode(utf8, forKey: key)
    }

}

extension JobInfo {

    init?(dictionary: [String: Any]) {
        guard let type = dictionary["type"] as? String else {
            return nil
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
