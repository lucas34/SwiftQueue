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

    /// Remove all tasks
    public func clearAll() {
        store.removeObject(forKey: key)
    }

}
