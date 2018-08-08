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
