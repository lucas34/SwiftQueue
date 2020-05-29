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

internal final class RepeatConstraint {

    static func run(operation: SqOperation) -> Bool {
        switch operation.info.executor {
        case .background:
            return false
        case .foreground:
            return true
        case.any:
            return true
        }
    }

    static func completionSuccess(sqOperation: SqOperation) {

        if case .limited(let limit) = sqOperation.info.maxRun {
            // Reached run limit
            guard sqOperation.info.runCount + 1 < limit else {
                sqOperation.onTerminate()
                return
            }
        }

        guard sqOperation.info.interval > 0 else {
            // Run immediately
            sqOperation.info.runCount += 1
            sqOperation.run()
            return
        }

        // Schedule run after interval
        sqOperation.nextRunSchedule = Date().addingTimeInterval(sqOperation.info.interval)
        sqOperation.dispatchQueue.runAfter(sqOperation.info.interval, callback: { [weak sqOperation] in
            sqOperation?.info.runCount += 1
            sqOperation?.run()
        })
    }

}

/// Enum to specify background and foreground restriction
public enum Executor: Int {

    /// Job will only run only when the app is in foreground
    case foreground = 0

    /// Job will only run only when the app is in background
    case background = 1

    /// Job can run in both background and foreground
    case any = 2

}

internal extension Executor {

    static func fromRawValue(value: Int) -> Executor {
        assert(value == 0 || value == 1 || value == 2)
        switch value {
        case 1:
            return Executor.background
        case 2:
            return Executor.any
        default:
            return Executor.foreground
        }
    }

}

extension Executor: Codable {

    private enum CodingKeys: String, CodingKey { case value }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let value = try values.decode(Int.self, forKey: .value)
        self = Executor.fromRawValue(value: value)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.rawValue, forKey: .value)
    }

}
