// The MIT License (MIT)
//
// Copyright (c) 2019 Lucas Nelaupe
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

/// Using Key value serializer to match with V1 behavior
public class V1Serializer: JobInfoSerializer {

    internal let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z"
        return formatter
    }()

    func toJSON(_ obj: [String: Any]) throws -> String {
        assert(JSONSerialization.isValidJSONObject(obj))
        let data = try JSONSerialization.data(withJSONObject: obj)
        return try String.fromUTF8(data: data)
    }

    public func serialize(info: JobInfo) throws -> String {
        try toJSON(info.toDictionary(dateFormatter))
    }

    func fromJSON(_ json: String) throws -> Any {
        try JSONSerialization.jsonObject(with: json.utf8Data())
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
        try jobInfo.bind(dictionary: dictionary, dateFormatter)
        return jobInfo
    }

}

internal extension JobInfo {

    func toDictionary(_ dateFormatter: DateFormatter) -> [String: Any] {
        var dict = [String: Any]()
        dict[JobInfoKeys.type.stringValue]                = self.type
        dict[JobInfoKeys.uuid.stringValue]                = self.uuid
        dict[JobInfoKeys.override.stringValue]            = self.override
        dict[JobInfoKeys.includeExecutingJob.stringValue] = self.includeExecutingJob
        dict[JobInfoKeys.queueName.stringValue]           = self.queueName
        dict[JobInfoKeys.tags.stringValue]                = Array(self.tags)
        dict[JobInfoKeys.delay.stringValue]               = self.delay
        dict[JobInfoKeys.deadline.stringValue]            = self.deadline.map(dateFormatter.string)
        dict[JobInfoKeys.requireNetwork.stringValue]      = self.requireNetwork.rawValue
        dict[JobInfoKeys.isPersisted.stringValue]         = self.isPersisted
        dict[JobInfoKeys.params.stringValue]              = self.params
        dict[JobInfoKeys.createTime.stringValue]          = dateFormatter.string(from: self.createTime)
        dict[JobInfoKeys.runCount.stringValue]            = self.runCount
        dict[JobInfoKeys.executor.stringValue]            = self.executor.rawValue
        dict[JobInfoKeys.maxRun.stringValue]              = self.maxRun.rawValue
        dict[JobInfoKeys.retries.stringValue]             = self.retries.rawValue
        dict[JobInfoKeys.interval.stringValue]            = self.interval
        dict[JobInfoKeys.requireCharging.stringValue]     = self.requireCharging
        dict[JobInfoKeys.priority.stringValue]            = self.priority.rawValue
        dict[JobInfoKeys.qualityOfService.stringValue]    = self.qualityOfService.rawValue
        return dict
    }

    mutating func bind(dictionary: [String: Any], _ dateFormatter: DateFormatter) throws {
        dictionary.assign(JobInfoKeys.uuid.stringValue, &self.uuid)
        dictionary.assign(JobInfoKeys.override.stringValue, &self.override)
        dictionary.assign(JobInfoKeys.includeExecutingJob.stringValue, &self.includeExecutingJob)
        dictionary.assign(JobInfoKeys.queueName.stringValue, &self.queueName)
        dictionary.assign(JobInfoKeys.tags.stringValue, &self.tags) { (array: [String]) -> Set<String> in Set(array) }
        dictionary.assign(JobInfoKeys.delay.stringValue, &self.delay)
        dictionary.assign(JobInfoKeys.deadline.stringValue, &self.deadline, dateFormatter.date)
        dictionary.assign(JobInfoKeys.requireNetwork.stringValue, &self.requireNetwork, NetworkType.init)
        dictionary.assign(JobInfoKeys.isPersisted.stringValue, &self.isPersisted)
        dictionary.assign(JobInfoKeys.params.stringValue, &self.params)
        dictionary.assign(JobInfoKeys.createTime.stringValue, &self.createTime, dateFormatter.date)
        dictionary.assign(JobInfoKeys.interval.stringValue, &self.interval)
        dictionary.assign(JobInfoKeys.maxRun.stringValue, &self.maxRun, Limit.fromRawValue)
        dictionary.assign(JobInfoKeys.executor.stringValue, &self.executor, Executor.fromRawValue)
        dictionary.assign(JobInfoKeys.retries.stringValue, &self.retries, Limit.fromRawValue)
        dictionary.assign(JobInfoKeys.runCount.stringValue, &self.runCount)
        dictionary.assign(JobInfoKeys.requireCharging.stringValue, &self.requireCharging)
        dictionary.assign(JobInfoKeys.priority.stringValue, &self.priority, Operation.QueuePriority.init)
        dictionary.assign(JobInfoKeys.qualityOfService.stringValue, &self.qualityOfService, QualityOfService.init)
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
