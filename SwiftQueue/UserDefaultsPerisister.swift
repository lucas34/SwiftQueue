//
// Created by Lucas Nelaupe on 16/8/17.
// Copyright (c) 2017 Lucas Nelaupe. All rights reserved.
//

import UIKit
import Foundation

public class UserDefaultsPersister: JobPersister {
    
    private let key = "SwiftQueueInfo"

    // Structure as follow
    // [group:[id:data]]
    public func restore() -> [String] {
        let store = UserDefaults()
        let values: [String: Any] = store.value(forKey: key) as? [String: Any] ?? [:]
        return Array(values.keys)
    }

    public func restore(queueName: String) -> [String] {
        let store = UserDefaults()
        let values: [String: [String: String]] = store.value(forKey: key) as? [String: [String: String]] ?? [:]
        let tasks: [String: String] = values[queueName] ?? [:]
        return Array(tasks.values)
    }

    public func put(queueName: String, taskId: String, data: String) {
        let store = UserDefaults()
        var values: [String: [String: String]] = store.value(forKey: key) as? [String: [String: String]] ?? [:]
        if values[queueName] != nil {
            values[queueName]?[taskId] = data
        } else {
            values[queueName] = [taskId: data]
        }
        store.setValue(values, forKey: key)
        store.synchronize()
    }

    public func remove(queueName: String, taskId: String) {
        let store = UserDefaults()
        var values: [String: [String: String]] = store.value(forKey: key) as? [String: [String: String]] ?? [:]
        values[queueName]?.removeValue(forKey: taskId)
        store.setValue(values, forKey: key)
        store.synchronize()
    }

}
