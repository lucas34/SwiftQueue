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
    var maxRun: Limit = .limited(0)

    var retries: Limit = .limited(0)

    var runCount: Int = 0
    var currentRepetition: Int = 0 // Do not serialize

    init(type: String) {
        self.type = type
    }

    init?(dictionary: [String: Any]) throws {
        guard let type = dictionary["type"] as? String else {
            assertionFailure("Unable to retrieve Job type")
            return nil
        }

        self.type = type

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
        dictionary.assign(&self.maxRun, key: "maxRun", Limit.fromIntValue)

        dictionary.assign(&self.retries, key: "retries", Limit.fromIntValue)

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
        dict["maxRun"]         = self.maxRun.intValue
        dict["retries"]        = self.retries.intValue
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
