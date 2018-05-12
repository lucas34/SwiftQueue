//
// Created by Lucas Nelaupe on 26/4/18.
//

import Foundation

/// `JSONEncoder` and `JSONDecoder` to serialize JobInfo
public class DecodableSerializer: JobInfoSerializer {

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// Init decodable with custom `JSONEncoder` and `JSONDecoder`
    public init(encoder: JSONEncoder = JSONEncoder(), decoder: JSONDecoder = JSONDecoder()) {
        self.encoder = encoder
        self.decoder = decoder
    }

    public func serialize(info: JobInfo) throws -> String {
        let encoded = try encoder.encode(info)
        guard let string = String(data: encoded, encoding: .utf8) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unable to convert decoded data to utf-8")
            )
        }
        return string
    }

    public func deserialize(json: String) throws -> JobInfo {
        guard let data = json.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unable to convert decoded data to utf-8")
            )
        }
        return try decoder.decode(JobInfo.self, from: data)
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
        case requireCharging = "requireCharging"
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
        let requireCharging: Bool = try container.decode(Bool.self, forKey: .requireCharging)

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
                runCount: runCount,
                requireCharging: requireCharging)
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
        try container.encode(requireCharging, forKey: .requireCharging)
    }
}

internal extension KeyedDecodingContainer {

    func decode(_ type: Data.Type, forKey key: KeyedDecodingContainer.Key) throws -> Data {
        let json = try self.decode(String.self, forKey: key)
        guard let data = json.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [key],
                    debugDescription: "Unable to convert string to utf-8")
            )
        }
        return data
    }

    func decode(_ type: [String: Any].Type, forKey key: KeyedDecodingContainer.Key) throws -> [String: Any] {
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

internal extension KeyedEncodingContainer {

    mutating func encode(_ value: [String: Any], forKey key: KeyedEncodingContainer.Key) throws {
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
