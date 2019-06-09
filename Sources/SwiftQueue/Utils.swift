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
import Dispatch

internal extension DispatchQueue {

    func runAfter(_ seconds: TimeInterval, callback: @escaping () -> Void) {
        let delta = DispatchTime.now() + seconds
        asyncAfter(deadline: delta, execute: callback)
    }

}

func assertNotEmptyString(_ string: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) {
    assert(!string().isEmpty, file: file, line: line)
}

internal extension Limit {

    var validate: Bool {
        switch self {
        case .unlimited:
            return true
        case .limited(let val):
            return val >= 0
        }
    }

    mutating func decreaseValue(by: Double) {
        if case .limited(let limit) = self {
            let value = limit - by
            assert(value >= 0)
            self = Limit.limited(value)
        }
    }

}

extension Limit: Codable {

    private enum CodingKeys: String, CodingKey { case value }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let value = try values.decode(Double.self, forKey: .value)
        self = value < 0 ? Limit.unlimited : Limit.limited(value)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .unlimited:
            try container.encode(-1, forKey: .value)
        case .limited(let value):
            assert(value >= 0)
            try container.encode(value, forKey: .value)
        }
    }

}

extension Limit: Equatable {

    public static func == (lhs: Limit, rhs: Limit) -> Bool {
        switch (lhs, rhs) {
        case let (.limited(lValue), .limited(rValue)):
            return lValue == rValue
        case (.unlimited, .unlimited):
            return true
        default:
            return false
        }
    }
}

internal extension Operation.QueuePriority {

    init(fromValue: Int?) {
        guard let value = fromValue, let priority = Operation.QueuePriority(rawValue: value) else {
            self = Operation.QueuePriority.normal
            return
        }
        self = priority
    }

}

internal extension QualityOfService {

    init(fromValue: Int?) {
        guard let value = fromValue, let service = QualityOfService(rawValue: value) else {
            self = QualityOfService.default
            return
        }
        self = service
    }

}

#if !swift(>=4.1)
extension Sequence {
    func compactMap<T>(_ fn: (Self.Iterator.Element) throws -> T?) rethrows -> [T] {
        return try flatMap(fn)
    }
}
#endif
