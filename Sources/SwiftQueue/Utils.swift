// The MIT License (MIT)
//
// Copyright (c) 2022 Lucas Nelaupe
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

internal extension String {

    static func fromUTF8(data: Data, key: [CodingKey] = []) throws -> String {
        guard let utf8 = String(data: data, encoding: .utf8) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: key,
                    debugDescription: "Unexpected error")
            )
        }
        return utf8
    }

    func utf8Data() throws -> Data {
        guard let data = self.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unexpected error")
            )
        }
        return data
    }

}

internal func getConstraint<T: JobConstraint>(_ operation: JobInfo?) -> T? {
    guard let constraints = operation?.constraints else { return nil }
    return getConstraint(constraints)
}

internal func getConstraint<T: JobConstraint>(_ constraints: [JobConstraint]) -> T? {
    for case let constraint as T in constraints {
        return constraint
    }
    return nil
}
