//
// Created by Lucas Nelaupe on 10/08/2017.
// Copyright (c) 2017 lucas34. All rights reserved.
//

import Foundation

func runInBackgroundAfter(_ seconds: TimeInterval, callback: @escaping () -> Void) {
    let delta = DispatchTime.now() + seconds
    DispatchQueue.global(qos: DispatchQoS.QoSClass.background).asyncAfter(deadline: delta, execute: callback)
}

func toJSON(_ obj: [String: Any]) -> String? {
    assert(JSONSerialization.isValidJSONObject(obj))
    let jsonData = try? JSONSerialization.data(withJSONObject: obj)
    return jsonData.flatMap { String(data: $0, encoding: .utf8) }
}

func fromJSON(_ str: String) -> Any? {
    return str.data(using: String.Encoding.utf8, allowLossyConversion: false)
            .flatMap { try? JSONSerialization.jsonObject(with: $0, options: .allowFragments)  }
}

let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z"
    return formatter
}()

func assertNotEmptyString(_ string: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) {
    assert(!string().isEmpty, file: file, line: line)
}

internal extension Limit {

    static func fromIntValue(value: Int) -> Limit {
        if value < 0 {
            return Limit.unlimited
        } else {
            return Limit.limited(value)
        }
    }
    
    var intValue: Int {
        switch self {
        case .unlimited:
            return -1
        case .limited(let val):
            assert(val >= 0)
            return val
        }

    }
    
    mutating func decreaseValue(by: Int) {
        if case .limited(let limit) = self {
            let value = limit - by
            assert(value >= 0)
            self = Limit.limited(value)
        }
    }

}


 extension Limit: Equatable {

    public static func ==(lhs: Limit, rhs: Limit) -> Bool {
        switch (lhs, rhs) {
        case let (.limited(a), .limited(b)):
            return a == b
        case (.unlimited, .unlimited):
            return true
        default:
            return false
        }
    }
}