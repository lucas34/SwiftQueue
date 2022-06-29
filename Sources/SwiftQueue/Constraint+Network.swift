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
import Network

/// Kind of connectivity required for the job to run
public enum NetworkType: Int, Codable {
    /// Job will run regardless the connectivity of the platform
    case any = 0
    /// Requires at least cellular such as 2G, 3G, 4G, LTE or Wifi
    case cellular = 1
    /// Device has to be connected to Wifi or Lan
    case wifi = 2
}

internal final class NetworkConstraint: SimpleConstraint, CodableConstraint {

    /// Require a certain connectivity type
    internal let networkType: NetworkType

    private var monitor: NWPathMonitor?

    required init(networkType: NetworkType) {
        assert(networkType != .any)
        self.networkType = networkType
    }

    convenience init?(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NetworkConstraintKey.self)
        if container.contains(.requireNetwork) {
            try self.init(networkType: container.decode(NetworkType.self, forKey: .requireNetwork))
        } else { return nil }
    }

    override func willSchedule(queue: SqOperationQueue, operation: SqOperation) throws {
        assert(operation.dispatchQueue != .main)
        self.monitor = NWPathMonitor()
    }

    override func run(operation: SqOperation) -> Bool {
        guard let monitor = monitor else { return true }

        if monitor.currentPath.status == .satisfied {
            return true
        }

        monitor.pathUpdateHandler = { [monitor, operation, networkType] path in
            guard path.status == .satisfied else {
                operation.logger.log(.verbose, jobId: operation.name, message: "Unsatisfied network requirement")
                return
            }

            /// If network type is wifi, make sure the path is not using cellular, otherwise wait
            if networkType == .wifi,
               path.usesInterfaceType(.cellular) {
                operation.logger.log(.verbose, jobId: operation.name, message: "Unsatisfied network requirement")
                return
            }

            monitor.cancel()
            monitor.pathUpdateHandler = nil
            operation.run()
        }

        monitor.start(queue: operation.dispatchQueue)
        return false
    }

    private enum NetworkConstraintKey: String, CodingKey {
        case requireNetwork
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: NetworkConstraintKey.self)
        try container.encode(networkType, forKey: .requireNetwork)
    }

}
