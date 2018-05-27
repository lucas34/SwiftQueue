//
// Created by Lucas Nelaupe on 20/4/18.
//

import Foundation
#if os(iOS)
import UIKit
#endif

#if os(iOS)
internal final class BatteryChargingConstraint: JobConstraint {

    // To avoid cyclic ref
    private weak var actual: SqOperation?

    func batteryStateDidChange(notification: NSNotification) {
        if UIDevice.current.batteryState == .charging {
            actual?.run()
            NotificationCenter.default.removeObserver(self)
        }
    }

    func willSchedule(queue: SqOperationQueue, operation: SqOperation) throws {}

    func willRun(operation: SqOperation) throws {}

    func run(operation: SqOperation) -> Bool {
        guard operation.info.requireCharging else {
            return true
        }

        if UIDevice.current.batteryState == .charging {
            return true
        }

        NotificationCenter.default.addObserver(self, selector: Selector(("batteryStateDidChange:")), name: NSNotification.Name.UIDeviceBatteryStateDidChange, object: nil)

        operation.logger.log(.verbose, jobId: operation.info.uuid, message: "Unsatisfied charging requirement")
        return false
    }

}

#else

internal final class BatteryChargingConstraint: DefaultNoConstraint {}

#endif
