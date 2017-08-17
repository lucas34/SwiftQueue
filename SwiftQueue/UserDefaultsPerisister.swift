//
// Created by Lucas Nelaupe on 16/8/17.
// Copyright (c) 2017 Lucas Nelaupe. All rights reserved.
//

import UIKit
import Foundation

public class UserDefaultsPersister: JobPersister {

    public func restore(queueName: String) -> [String] {
        let store = UserDefaults(suiteName: queueName)
        return store?.dictionaryRepresentation().values.flatMap {
            return $0 as? String
        } ?? []
    }

    public func put(queueName: String, taskId: String, data: String) {
        let store = UserDefaults(suiteName: queueName)
        store?.setValue(data, forKey: taskId)
    }

    public func remove(queueName: String, taskId: String) {
        let store = UserDefaults(suiteName: queueName)
        store?.removeObject(forKey: taskId)
    }
}
