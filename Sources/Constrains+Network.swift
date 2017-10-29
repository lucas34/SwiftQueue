//
// Created by Lucas Nelaupe on 29/10/2017.
//

import Foundation
#if os(iOS) || os(macOS) || os(tvOS)
import Reachability
#endif

public enum NetworkType: Int {
    case any = 0
    case cellular =  1
    case wifi =  2
}

#if os(iOS) || os(macOS) || os(tvOS)
internal class NetworkConstraint: JobConstraint {

    var reachability: Reachability?

    func schedule(queue: SwiftQueue, operation: SwiftQueueJob) throws {
        self.reachability = operation.requireNetwork.rawValue > NetworkType.any.rawValue ? Reachability() : nil
    }

    func run(operation: SwiftQueueJob) throws -> Bool {
        guard let reachability = reachability else {
            return true
        }

        if hasCorrectNetwork(reachability: reachability, required: operation.requireNetwork) {
            return true
        }

        do {
            try reachability.startNotifier()
        } catch (let error) {
            throw error
        }

        reachability.whenReachable = { reachability in
            reachability.stopNotifier()
            reachability.whenReachable = nil
            operation.run()
        }
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

internal class NetworkConstraint: JobConstraint {

    func schedule(queue: SwiftQueue, operation: SwiftQueueJob) throws {
        // Nothing
    }

    func run(operation: SwiftQueueJob) throws -> Bool {
        return true
    }
}

#endif
