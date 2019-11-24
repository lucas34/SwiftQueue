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
                name: UIDevice.batteryStateDidChangeNotification,
                object: nil
        )
    }

    func willRun(operation: SqOperation) throws {}

    func run(operation: SqOperation) -> Bool {
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
