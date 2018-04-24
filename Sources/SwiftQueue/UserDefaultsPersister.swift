//
// Created by Lucas Nelaupe on 16/8/17.
// Copyright (c) 2017 Lucas Nelaupe. All rights reserved.
//

import Foundation

/// Persist jobs in UserDefaults
public class UserDefaultsPersister: JobPersister {

    private let store = UserDefaults()
    private let key: String

    /// Create a Job persister with a custom key
    public init(key: String = "SwiftQueueInfo") {
        self.key = key
    }

    // Structure as follow
    // [group:[id:data]]
    public func restore() -> [String] {
        let values: [String: Any] = store.value(forKey: key) as? [String: Any] ?? [:]
        return Array(values.keys)
    }

    /// Restore jobs for a single queue
    /// Returns an array of String. serialized job
    public func restore(queueName: String) -> [String] {
        let values: [String: [String: String]] = store.value(forKey: key) as? [String: [String: String]] ?? [:]
        let tasks: [String: String] = values[queueName] ?? [:]
        return Array(tasks.values)
    }

    /// Insert a job to a specific queue
    public func put(queueName: String, taskId: String, data: String) {
        var values: [String: [String: String]] = store.value(forKey: key) as? [String: [String: String]] ?? [:]
        if values[queueName] != nil {
            values[queueName]?[taskId] = data
        } else {
            values[queueName] = [taskId: data]
        }
        store.setValue(values, forKey: key)
    }

    /// Remove a specific task from a queue
    public func remove(queueName: String, taskId: String) {
        var values: [String: [String: String]]? = store.value(forKey: key) as? [String: [String: String]]
        values?[queueName]?.removeValue(forKey: taskId)
        store.setValue(values, forKey: key)
    }

}
