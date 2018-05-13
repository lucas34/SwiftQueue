//
// Created by Lucas Nelaupe on 13/12/17.
//

import Foundation

/// Info related to a single job. Those information may be serialized and persisted
/// In order to re-create the job in the future.
public struct JobInfo {

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

    var requireCharging: Bool

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
         runCount: Double = 0,
         requireCharging: Bool = false) {

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
        self.requireCharging = requireCharging

        /// Transient
        self.currentRepetition = 0
    }
}
