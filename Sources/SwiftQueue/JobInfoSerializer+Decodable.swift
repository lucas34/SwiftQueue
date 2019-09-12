// The MIT License (MIT)
//
// Copyright (c) 2017 Lucas Nelaupe
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
        case includeExecutingJob = "includeExecutingJob"
        case queueName = "group"
        case tags = "tags"
        case delay = "delay"
        case deadline = "deadline"
        case requireNetwork = "requireNetwork"
        case isPersisted = "isPersisted"
        case params = "params"
        case createTime = "createTime"
        case interval = "runCount"
        case maxRun = "maxRun"
        case executor = "executor"
        case retries = "retries"
        case runCount = "interval"
        case requireCharging = "requireCharging"
        case priority = "priority"
        case qualityOfService = "qualityOfService"
        case timeout = "timeout"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JobInfoKeys.self)

        let priority: Int? = try container.decode(Int?.self, forKey: .priority)
        let qualityOfService: Int? = try container.decode(Int?.self, forKey: .qualityOfService)

        self.init(
                type: try container.decode(String.self, forKey: .type),
                queueName: try container.decode(String.self, forKey: .queueName),
                uuid: try container.decode(String.self, forKey: .uuid),
                override: try container.decode(Bool.self, forKey: .override),
                includeExecutingJob: try container.decode(Bool.self, forKey: .includeExecutingJob),
                tags: try container.decode(Set.self, forKey: .tags),
                delay: try container.decodeIfPresent(TimeInterval.self, forKey: .delay),
                deadline: try container.decodeIfPresent(Date.self, forKey: .deadline),
                requireNetwork: try container.decode(NetworkType.self, forKey: .requireNetwork),
                isPersisted: try container.decode(Bool.self, forKey: .isPersisted),
                params: try container.decode([String: Any].self, forKey: .params),
                createTime: try container.decode(Date.self, forKey: .createTime),
                interval: try container.decode(TimeInterval.self, forKey: .interval),
                maxRun: try container.decode(Limit.self, forKey: .maxRun),
                executor: try container.decode(Executor.self, forKey: .executor),
                retries: try container.decode(Limit.self, forKey: .retries),
                runCount: try container.decode(Double.self, forKey: .runCount),
                requireCharging: try container.decode(Bool.self, forKey: .requireCharging),
                priority: Operation.QueuePriority(fromValue: priority),
                qualityOfService: QualityOfService(fromValue: qualityOfService),
                timeout: try container.decode(TimeInterval?.self, forKey: .timeout)
        )
    }
}

extension JobInfo: Encodable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: JobInfoKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(override, forKey: .override)
        try container.encode(includeExecutingJob, forKey: .includeExecutingJob)
        try container.encode(queueName, forKey: .queueName)
        try container.encode(tags, forKey: .tags)
        try container.encode(delay, forKey: .delay)
        try container.encode(deadline, forKey: .deadline)
        try container.encode(requireNetwork, forKey: .requireNetwork)
        try container.encode(isPersisted, forKey: .isPersisted)
        try container.encode(params, forKey: .params)
        try container.encode(createTime, forKey: .createTime)
        try container.encode(interval, forKey: .interval)
        try container.encode(maxRun, forKey: .maxRun)
        try container.encode(executor, forKey: .executor)
        try container.encode(retries, forKey: .retries)
        try container.encode(runCount, forKey: .runCount)
        try container.encode(requireCharging, forKey: .requireCharging)
        try container.encode(priority.rawValue, forKey: .priority)
        try container.encode(qualityOfService.rawValue, forKey: .qualityOfService)
        try container.encode(timeout, forKey: .timeout)
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
