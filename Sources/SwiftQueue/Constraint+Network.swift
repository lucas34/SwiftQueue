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
#if os(iOS) || os(macOS) || os(tvOS)
import Reachability
#endif

/// Kind of connectivity required for the job to run
public enum NetworkType: Int, Codable {
    /// Job will run regardless the connectivity of the platform
    case any = 0
    /// Requires at least cellular such as 2G, 3G, 4G, LTE or Wifi
    case cellular = 1
    /// Device has to be connected to Wifi or Lan
    case wifi = 2
}

#if os(iOS) || os(macOS) || os(tvOS)
internal final class NetworkConstraint: SimpleConstraint {

    /// Require a certain connectivity type
    internal let networkType: NetworkType

    private var reachability: Reachability?

    required init(networkType: NetworkType) {
        assert(networkType != .any)
        self.networkType = networkType
    }

    override func willSchedule(queue: SqOperationQueue, operation: SqOperation) throws {
        assert(operation.dispatchQueue != .main)
        self.reachability = try Reachability(targetQueue: operation.dispatchQueue, notificationQueue: operation.dispatchQueue)
    }

    override func run(operation: SqOperation) -> Bool {
        guard let reachability = reachability else { return true }

        if (hasCorrectNetwork(reachability: reachability)) {
            return true
        }

        operation.logger.log(.verbose, jobId: operation.name, message: "Unsatisfied network requirement")

        reachability.whenReachable = { reachability in
            reachability.stopNotifier()
            reachability.whenReachable = nil
            operation.run()
        }

        do {
            try reachability.startNotifier()
            return false
        } catch {
            operation.logger.log(.verbose, jobId: operation.name, message: "Unable to start network listener. Job will run.")
            operation.logger.log(.error, jobId: operation.name, message: error.localizedDescription)
            return true
        }
    }

    private func hasCorrectNetwork(reachability: Reachability) -> Bool {
        switch networkType {
        case .any:
            return true
        case .cellular:
            return reachability.connection != .unavailable
        case .wifi:
            return reachability.connection == .wifi
        }
    }

}
#else

internal final class NetworkConstraint: SimpleConstraint {

    init(networkType: NetworkType) {}

}

#endif
