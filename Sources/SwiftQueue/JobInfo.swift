// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

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

    //// Including job that are executing when scheduling with same uuid
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
                retries: .limited(0),
                runCount: 0,
                requireCharging: false,
                priority: .normal,
                qualityOfService: .utility
        )
    }

    init(type: String,
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
         retries: Limit,
         runCount: Double,
         requireCharging: Bool,
         priority: Operation.QueuePriority,
         qualityOfService: QualityOfService
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
        self.retries = retries
        self.runCount = runCount
        self.requireCharging = requireCharging
        self.priority = priority
        self.qualityOfService = qualityOfService

        /// Transient
        self.currentRepetition = 0
    }
}
