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

/// Info related to a single job. Those information may be serialized and persisted
/// In order to re-create the job in the future.
public struct JobInfo {

    /// Type of job to create actual `Job` instance
    let type: String

    /// Queue name
    var queueName: String

    /// Unique identifier for a job
    var uuid: String

    /// Override job when scheduling a job with same uuid
    var override: Bool

    /// Including job that are executing when scheduling with same uuid
    var includeExecutingJob: Bool

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

    /// Allow job to run in background task
    var allowBackground: Bool

    /// Number of run maximum
    var maxRun: Limit

    /// Maximum number of authorised retried
    var retries: Limit

    /// Current number of run
    var runCount: Double

    var requireCharging: Bool

    /// Current number of repetition. Transient value
    var currentRepetition: Int

    /// This value is used to influence the order in which operations are dequeued and executed
    var priority: Operation.QueuePriority

    /// The relative amount of importance for granting system resources to the operation.
    var qualityOfService: QualityOfService

    var timeout: TimeInterval?

    func buildConstraints() -> [JobConstraint] {
        var constraints = [JobConstraint]()

        constraints.append(UniqueUUIDConstraint())

        if requireCharging {
            constraints.append(BatteryChargingConstraint())
        }

        if deadline != nil {
            constraints.append(DeadlineConstraint())
        }

        if delay != nil {
            constraints.append(DelayConstraint())
        }

        if requireNetwork != NetworkType.any {
            constraints.append(NetworkConstraint())
        }

        if timeout != nil {
            constraints.append(TimeoutConstraint())
        }

        return constraints
    }

    init(type: String) {
        self.init(
                type: type,
                queueName: "GLOBAL",
                uuid: UUID().uuidString,
                override: false,
                includeExecutingJob: true,
                tags: Set<String>(),
                delay: nil,
                deadline: nil,
                requireNetwork: NetworkType.any,
                isPersisted: false,
                params: [:],
                createTime: Date(),
                interval: -1.0,
                maxRun: .limited(0),
                allowBackground: false,
                retries: .limited(0),
                runCount: 0,
                requireCharging: false,
                priority: .normal,
                qualityOfService: .utility,
                timeout: nil
        )
    }

    internal init(type: String,
                  queueName: String,
                  uuid: String,
                  override: Bool,
                  includeExecutingJob: Bool,
                  tags: Set<String>,
                  delay: TimeInterval?,
                  deadline: Date?,
                  requireNetwork: NetworkType,
                  isPersisted: Bool,
                  params: [String: Any],
                  createTime: Date,
                  interval: TimeInterval,
                  maxRun: Limit,
                  allowBackground: Bool,
                  retries: Limit,
                  runCount: Double,
                  requireCharging: Bool,
                  priority: Operation.QueuePriority,
                  qualityOfService: QualityOfService,
                  timeout: TimeInterval?
    ) {

        self.type = type
        self.queueName = queueName
        self.uuid = uuid
        self.override = override
        self.includeExecutingJob = includeExecutingJob
        self.tags = tags
        self.delay = delay
        self.deadline = deadline
        self.requireNetwork = requireNetwork
        self.isPersisted = isPersisted
        self.params = params
        self.createTime = createTime
        self.interval = interval
        self.maxRun = maxRun
        self.allowBackground = allowBackground
        self.retries = retries
        self.runCount = runCount
        self.requireCharging = requireCharging
        self.priority = priority
        self.qualityOfService = qualityOfService
        self.timeout = timeout

        /// Transient
        self.currentRepetition = 0
    }
}
