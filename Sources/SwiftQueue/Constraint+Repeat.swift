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

internal final class RepeatConstraint: SimpleConstraint, CodableConstraint {

    /// Number of run maximum
    internal let maxRun: Limit

    /// Time between each repetition of the job
    internal let interval: TimeInterval

    /// Executor to run job in foreground or background
    internal let executor: Executor

    /// Current number of run
    private var runCount: Double = 0

    required init(maxRun: Limit, interval: TimeInterval, executor: Executor) {
        self.maxRun = maxRun
        self.interval = interval
        self.executor = executor
    }

    convenience init?(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: RepeatConstraintKey.self)
        if container.contains(.maxRun) && container.contains(.interval) && container.contains(.executor) {
            try self.init(
                    maxRun: container.decode(Limit.self, forKey: .maxRun),
                    interval: container.decode(TimeInterval.self, forKey: .interval),
                    executor: container.decode(Executor.self, forKey: .executor)
            )
        } else { return nil }
    }

    override func run(operation: SqOperation) -> Bool {
        switch executor {
        case .background:
            return false
        case .foreground:
            return true
        case.any:
            return true
        }
    }

    func completionSuccess(sqOperation: SqOperation) {
        if case .limited(let limit) = maxRun {
            // Reached run limit
            guard runCount + 1 < limit else {
                sqOperation.onTerminate()
                return
            }
        }

        guard interval > 0 else {
            // Run immediately
            runCount += 1
            sqOperation.run()
            return
        }

        // Schedule run after interval
        sqOperation.nextRunSchedule = Date().addingTimeInterval(interval)
        sqOperation.dispatchQueue.runAfter(interval, callback: { [weak self, weak sqOperation] in
            self?.runCount += 1
            sqOperation?.run()
        })
    }

    private enum RepeatConstraintKey: String, CodingKey {
        case maxRun
        case interval
        case executor
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RepeatConstraintKey.self)
        try container.encode(maxRun, forKey: .maxRun)
        try container.encode(interval, forKey: .interval)
        try container.encode(executor, forKey: .executor)
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
