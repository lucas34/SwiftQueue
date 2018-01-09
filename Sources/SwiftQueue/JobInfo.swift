//
// Created by Lucas Nelaupe on 13/12/17.
//

import Foundation

struct JobInfo {

    let type: String

    var uuid: String =  UUID().uuidString
    var override = false

    var group: String = "GLOBAL"
    var tags = Set<String>()
    var delay: TimeInterval?
    var deadline: Date?
    var requireNetwork: NetworkType = NetworkType.any
    var isPersisted: Bool = false
    var params: [String: Any] = [:]
    var createTime: Date = Date()
    var interval: TimeInterval = -1.0

    var runCount: Int = 0
    var maxRun: Int = 0
    var retries: Int = 0
    var currentRepetition: Int = 0

    init(type: String) {
        self.type = type
    }

    init?(dictionary: [String: Any]) {
        guard let type           = dictionary["type"] as? String,
              let uuid           = dictionary["uuid"] as? String,
              let override       = dictionary["override"] as? Bool,
              let group          = dictionary["group"] as? String,
              let tags           = dictionary["tags"] as? [String],
              let delay          = dictionary["delay"] as? TimeInterval?,
              let deadlineStr    = dictionary["deadline"] as? String?,
              let requireNetwork = dictionary["requireNetwork"] as? Int,
              let isPersisted    = dictionary["isPersisted"] as? Bool,
              let params         = dictionary["params"] as? [String: Any],
              let createTimeStr  = dictionary["createTime"] as? String,
              let runCount       = dictionary["runCount"] as? Int,
              let maxRun         = dictionary["maxRun"] as? Int,
              let retries        = dictionary["retries"] as? Int,
              let interval       = dictionary["interval"] as? TimeInterval else {
            return nil
        }

        let deadline   = deadlineStr.flatMap(dateFormatter.date)
        let createTime = dateFormatter.date(from: createTimeStr) ?? Date()
        let network    = NetworkType(rawValue: requireNetwork) ?? NetworkType.any

        self.type = type
        self.uuid = uuid
        self.override = override
        self.group = group
        self.tags = Set(tags)
        self.delay = delay
        self.deadline = deadline
        self.requireNetwork = network
        self.isPersisted = isPersisted
        self.params = params
        self.createTime = createTime
        self.interval = interval
        self.runCount = runCount
        self.maxRun = maxRun
        self.retries = retries
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
        dict["maxRun"]         = self.maxRun
        dict["retries"]        = self.retries
        dict["interval"]       = self.interval
        return dict
    }

}
