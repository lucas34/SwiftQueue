//
// Created by Lucas Nelaupe on 10/08/2017.
// Copyright (c) 2017 lucas34. All rights reserved.
//

import Foundation
import Dispatch

func runInBackgroundAfter(_ seconds: TimeInterval, callback: @escaping () -> Void) {
    let delta = DispatchTime.now() + seconds
    DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).asyncAfter(deadline: delta, execute: callback)
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

#if !swift(>=4.1)
extension Sequence {
    func compactMap<T>(_ fn: (Self.Iterator.Element) throws -> T?) rethrows -> [T] {
        return try flatMap(fn)
    }
}
#endif
