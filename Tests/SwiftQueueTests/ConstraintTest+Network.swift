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
import XCTest
@testable import SwiftQueue

class ConstraintTestNetwork: XCTestCase {

    func testNetworkConstraint() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoPersister.shared).build()
        JobBuilder(type: type)
                .internet(atLeast: .cellular)
                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertSingleCompletion()
    }

    func testNetworkConstraintWifi() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoPersister.shared).build()
        JobBuilder(type: type)
                .internet(atLeast: .wifi)
                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertSingleCompletion()
    }

    func testNetworkWaitUntilAvailable() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])
        let semaphore = DispatchSemaphore(value: 0)

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoPersister.shared).build()
        JobBuilder(type: type)
                .add(constraint: NetworkConstraint(networkType: .wifi, monitor: TestNetworkMonitor(semaphore: semaphore)))
                .schedule(manager: manager)

        job.assertNoRun()

        semaphore.signal()

        job.awaitForRemoval()
        job.assertSingleCompletion()
    }

}

internal class TestNetworkMonitor: NetworkMonitor {

    private let semaphore: DispatchSemaphore

    private var hasNetworkChanged = false

    required init(semaphore: DispatchSemaphore) {
        self.semaphore = semaphore
    }

    func hasCorrectNetworkType(require: NetworkType) -> Bool {
        hasNetworkChanged
    }

    func startMonitoring(networkType: NetworkType, operation: SqOperation) {
        operation.dispatchQueue.async { [weak self] in
            self?.semaphore.wait()
            self?.hasNetworkChanged = true
            operation.run()
        }
    }
}
