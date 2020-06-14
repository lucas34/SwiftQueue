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

/// Info related to a single job. Those information may be serialized and persisted
/// In order to re-create the job in the future.
public struct JobInfo {

    /// Type of job to create actual `Job` instance
    public let type: String

    /// Queue name
    public var queueName: String

    /// Custom params set by the user
    public var params: [String: Any]

    /// This value is used to influence the order in which operations are dequeued and executed
    public var priority: Operation.QueuePriority

    /// The relative amount of importance for granting system resources to the operation.
    public var qualityOfService: QualityOfService

    /// Date of the job's creation
    public let createTime: Date

    internal var constraints: [JobConstraint]

    mutating func setupConstraints(_ maker: ConstraintMaker, from decoder: Decoder) throws {
        constraints = try maker.make(from: decoder)
    }

    init(type: String) {
        self.init(
                type: type,
                queueName: "GLOBAL",
                createTime: Date(),
                priority: .normal,
                qualityOfService: .utility,
                params: [:],
                constraints: []
        )
    }

    init(type: String,
         queueName: String,
         createTime: Date,
         priority: Operation.QueuePriority,
         qualityOfService: QualityOfService,
         params: [String: Any],
         constraints: [JobConstraint]
    ) {
        self.type = type
        self.queueName = queueName
        self.createTime = createTime
        self.priority = priority
        self.qualityOfService = qualityOfService
        self.params = params
        self.constraints = constraints
    }
}

extension JobInfo: Codable {

    internal enum JobInfoKeys: String, CodingKey {
        case type
        case queueName
        case params
        case priority
        case qualityOfService
        case createTime
        case constraints
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JobInfoKeys.self)

        let type = try container.decode(String.self, forKey: .type)
        let queueName = try container.decode(String.self, forKey: .queueName)
        let params: [String: Any] = try container.decode([String: Any].self, forKey: .params)
        let priority: Int = try container.decode(Int.self, forKey: .priority)
        let qualityOfService: Int = try container.decode(Int.self, forKey: .qualityOfService)
        let createTime = try container.decode(Date.self, forKey: .createTime)
        let constraintMaker = decoder.userInfo[.constraintMaker] as? ConstraintMaker ?? DefaultConstraintMaker()

        try self.init(
                type: type,
                queueName: queueName,
                createTime: createTime,
                priority: Operation.QueuePriority(fromValue: priority),
                qualityOfService: QualityOfService(fromValue: qualityOfService),
                params: params,
                constraints: constraintMaker.make(from: decoder)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: JobInfoKeys.self)

        try container.encode(type, forKey: .type)
        try container.encode(queueName, forKey: .queueName)
        try container.encode(params, forKey: .params)
        try container.encode(priority.rawValue, forKey: .priority)
        try container.encode(qualityOfService.rawValue, forKey: .qualityOfService)
        try container.encode(createTime, forKey: .createTime)
        for case let constraint as CodableConstraint in constraints {
            try constraint.encode(to: encoder)
        }
    }
}
