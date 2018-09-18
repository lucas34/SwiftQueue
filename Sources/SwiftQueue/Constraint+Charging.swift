// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import Foundation
#if os(iOS)
import UIKit
#endif

#if os(iOS)
internal final class BatteryChargingConstraint: JobConstraint {

    // To avoid cyclic ref
    private weak var actual: SqOperation?

    func batteryStateDidChange(notification: NSNotification) {
        if let job = actual, UIDevice.current.batteryState == .charging {
            // Avoid job to run multiple times
            actual = nil
            job.run()
        }
    }

    func willSchedule(queue: SqOperationQueue, operation: SqOperation) throws {
        guard operation.info.requireCharging else { return }

        /// Start listening
        NotificationCenter.default.addObserver(
                self,
                selector: Selector(("batteryStateDidChange:")),
                name: NSNotification.Name.UIDeviceBatteryStateDidChange,
                object: nil
        )
    }

    func willRun(operation: SqOperation) throws {}

    func run(operation: SqOperation) -> Bool {
        guard operation.info.requireCharging else {
            return true
        }

        guard UIDevice.current.batteryState != .charging else {
            return true
        }

        operation.logger.log(.verbose, jobId: operation.info.uuid, message: "Unsatisfied charging requirement")

        /// Keep actual job
        actual = operation
        return false
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}

#else

internal final class BatteryChargingConstraint: DefaultNoConstraint {}

#endif
