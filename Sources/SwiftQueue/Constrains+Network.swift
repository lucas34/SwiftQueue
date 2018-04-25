//
// Created by Lucas Nelaupe on 29/10/2017.
//

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
internal final class NetworkConstraint: JobConstraint {

    var reachability: Reachability?

    func willSchedule(queue: SqOperationQueue, operation: SqOperation) throws {
        self.reachability = operation.info.requireNetwork.rawValue > NetworkType.any.rawValue ? Reachability() : nil
    }

    func willRun(operation: SqOperation) throws {
        guard let reachability = reachability else { return }
        guard hasCorrectNetwork(reachability: reachability, required: operation.info.requireNetwork) else {
            try reachability.startNotifier()
            return
        }
    }

    func run(operation: SqOperation) -> Bool {
        guard let reachability = reachability else {
            return true
        }

        if hasCorrectNetwork(reachability: reachability, required: operation.info.requireNetwork) {
            return true
        }

        reachability.whenReachable = { reachability in
            reachability.stopNotifier()
            reachability.whenReachable = nil
            operation.run()
        }

        operation.logger.log(.verbose, jobId: operation.info.uuid, message: "Unsatisfied network requirement")
        return false
    }

    private func hasCorrectNetwork(reachability: Reachability, required: NetworkType) -> Bool {
        switch required {
        case .any:
            return true
        case .cellular:
            return reachability.connection != .none
        case .wifi:
            return reachability.connection == .wifi
        }
    }

}
#else

internal final class NetworkConstraint: DefaultNoConstraint {}

#endif
