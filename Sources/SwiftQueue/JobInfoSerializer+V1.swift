//
// Created by Lucas Nelaupe on 26/4/18.
//

import Foundation

/// Using Key value serializer to match with V1 behavior
public class V1Serializer: JobInfoSerializer {

    func toJSON(_ obj: [String: Any]) throws -> String? {
        assert(JSONSerialization.isValidJSONObject(obj))
        let jsonData = try JSONSerialization.data(withJSONObject: obj)
        return String(data: jsonData, encoding: .utf8)
    }

    public func serialize(info: JobInfo) throws -> String {
        guard let json = try toJSON(info.toDictionary()) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [],
                    debugDescription: "The given data was not valid JSON.")
            )
        }
        return json
    }

    func fromJSON(_ json: String) throws -> Any {
        guard let data = json.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unable to convert string to utf-8")
            )
        }

        return try JSONSerialization.jsonObject(with: data, options: .allowFragments)
    }

    public func deserialize(json: String) throws -> JobInfo {
        guard let dictionary = try fromJSON(json) as? [String: Any] else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Decoded value is not a dictionary")
            )
        }

        guard let type = dictionary["type"] as? String else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unable to retrieve job type")
            )
        }

        var jobInfo = JobInfo(type: type)
        try jobInfo.bind(dictionary: dictionary)
        return jobInfo
    }

}

internal extension JobInfo {

    func toDictionary() -> [String: Any] {
        var dict = [String: Any]()
        dict[JobInfoKeys.type.stringValue]            = self.type
        dict[JobInfoKeys.uuid.stringValue]            = self.uuid
        dict[JobInfoKeys.override.stringValue]        = self.override
        dict[JobInfoKeys.group.stringValue]           = self.group
        dict[JobInfoKeys.tags.stringValue]            = Array(self.tags)
        dict[JobInfoKeys.delay.stringValue]           = self.delay
        dict[JobInfoKeys.deadline.stringValue]        = self.deadline.map(dateFormatter.string)
        dict[JobInfoKeys.requireNetwork.stringValue]  = self.requireNetwork.rawValue
        dict[JobInfoKeys.isPersisted.stringValue]     = self.isPersisted
        dict[JobInfoKeys.params.stringValue]          = self.params
        dict[JobInfoKeys.createTime.stringValue]      = dateFormatter.string(from: self.createTime)
        dict[JobInfoKeys.runCount.stringValue]        = self.runCount
        dict[JobInfoKeys.maxRun.stringValue]          = self.maxRun.rawValue
        dict[JobInfoKeys.retries.stringValue]         = self.retries.rawValue
        dict[JobInfoKeys.interval.stringValue]        = self.interval
        dict[JobInfoKeys.requireCharging.stringValue] = self.requireCharging
        return dict
    }

    mutating func bind(dictionary: [String: Any]) throws {
        dictionary.assign(JobInfoKeys.uuid.stringValue, &self.uuid)
        dictionary.assign(JobInfoKeys.override.stringValue, &self.override)
        dictionary.assign(JobInfoKeys.group.stringValue, &self.group)
        dictionary.assign(JobInfoKeys.tags.stringValue, &self.tags) { (array: [String]) -> Set<String> in Set(array) }
        dictionary.assign(JobInfoKeys.delay.stringValue, &self.delay)
        dictionary.assign(JobInfoKeys.deadline.stringValue, &self.deadline, dateFormatter.date)
        dictionary.assign(JobInfoKeys.requireNetwork.stringValue, &self.requireNetwork) { NetworkType(rawValue: $0) }
        dictionary.assign(JobInfoKeys.isPersisted.stringValue, &self.isPersisted)
        dictionary.assign(JobInfoKeys.params.stringValue, &self.params)
        dictionary.assign(JobInfoKeys.createTime.stringValue, &self.createTime, dateFormatter.date)
        dictionary.assign(JobInfoKeys.interval.stringValue, &self.interval)
        dictionary.assign(JobInfoKeys.maxRun.stringValue, &self.maxRun, Limit.fromRawValue)
        dictionary.assign(JobInfoKeys.retries.stringValue, &self.retries, Limit.fromRawValue)
        dictionary.assign(JobInfoKeys.runCount.stringValue, &self.runCount)
        dictionary.assign(JobInfoKeys.requireCharging.stringValue, &self.requireCharging)
    }
}

internal extension Dictionary where Key == String {

    func assign<A>(_ key: String, _ variable: inout A) {
        if let value = self[key] as? A {
            variable = value
        }
    }

    func assign<A, B>(_ key: String, _ variable: inout B, _ transform: (A) -> B?) {
        if let value = self[key] as? A, let transformed = transform(value) {
            variable = transformed
        }
    }

}

internal extension Limit {

    static func fromRawValue(value: Double) -> Limit {
        return value < 0 ? Limit.unlimited : Limit.limited(value)
    }

    var rawValue: Double {
        switch self {
        case .unlimited:
            return -1
        case .limited(let val):
            return val
        }
    }
}

internal let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z"
    return formatter
}()
