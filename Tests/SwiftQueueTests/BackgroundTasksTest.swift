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

import XCTest
import Dispatch
@testable import SwiftQueue

@available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
class BackgroundTasksTest {

    @available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
    public func testBackgroundOperationShouldNotRun() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoPersister.shared).build()
        JobBuilder(type: type)
                .periodic(executor: .background)
                .internet(atLeast: .wifi)
                .priority(priority: .veryHigh)
                .service(quality: .background)
                .schedule(manager: manager)

        job.assertNoRun()
    }

    @available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
    public func testBuilderPeriodicLimited() throws {
        let type = UUID().uuidString
        let limited: Double = 123
        let interval: Double = 12342
        let executor = Executor.any

        let jobInfo = JobBuilder(type: type).periodic(limit: .limited(limited), interval: interval, executor: .any).info

        let constraint: RepeatConstraint? = getConstraint(jobInfo)
        XCTAssertNotNil(constraint)

        XCTAssertEqual(constraint?.maxRun, Limit.limited(limited))
        XCTAssertEqual(constraint?.interval, interval)
        XCTAssertEqual(constraint?.executor, executor)

    }

    @available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
    public func testBuilderPeriodicBackground() throws {
        let type = UUID().uuidString
        let limited: Double = 123
        let interval: Double = 12342
        let executor = Executor.background

        let jobInfo = JobBuilder(type: type).periodic(limit: .limited(limited), interval: interval, executor: .background).info

        let constraint: RepeatConstraint? = getConstraint(jobInfo)
        XCTAssertNotNil(constraint)

        XCTAssertEqual(constraint?.maxRun, Limit.limited(limited))
        XCTAssertEqual(constraint?.interval, interval)
        XCTAssertEqual(constraint?.executor, executor)
    }

    @available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
    public func testGetAllAllowBackgroundOperation() {
        let (type, job) = (UUID().uuidString, TestJob())

        let id = UUID().uuidString
        let id2 = UUID().uuidString

        let group = UUID().uuidString
        let group2 = UUID().uuidString

        let creator = TestCreator([type: job])

        let persister = PersisterTracker(key: UUID().uuidString)

        let manager = SwiftQueueManagerBuilder(creator: creator).set(isSuspended: true).set(persister: persister).build()

        JobBuilder(type: type).periodic(executor: .foreground).parallel(queueName: group).schedule(manager: manager)
        JobBuilder(type: type).periodic(executor: .foreground).parallel(queueName: group2).schedule(manager: manager)

        JobBuilder(type: type).singleInstance(forId: id).periodic(executor: .background).parallel(queueName: group).schedule(manager: manager)
        JobBuilder(type: type).singleInstance(forId: id2).periodic(executor: .any).parallel(queueName: group2).schedule(manager: manager)

        let result = manager.getAllAllowBackgroundOperation()

        XCTAssertEqual(2, result.count)
    }

}
