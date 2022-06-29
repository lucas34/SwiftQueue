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
import Dispatch
@testable import SwiftQueue

class SwiftQueueBuilderTests: XCTestCase {

    public func testBuilderJobType() throws {
        let type = UUID().uuidString

        let jobInfo = JobBuilder(type: type).info
        XCTAssertEqual(jobInfo.type, type)

    }

    public func testBuilderSingleInstance() throws {
        let type = UUID().uuidString
        let uuid = UUID().uuidString

        let jobInfo = JobBuilder(type: type).singleInstance(forId: uuid).info

        let constraint: UniqueUUIDConstraint? = getConstraint(jobInfo)
        XCTAssertNotNil(constraint)
        XCTAssertEqual(constraint?.uuid, uuid)
        XCTAssertFalse(constraint?.override ?? false)
    }

    public func testBuilderSingleInstanceOverride() throws {
        let type = UUID().uuidString
        let uuid = UUID().uuidString

        let jobInfo = JobBuilder(type: type).singleInstance(forId: uuid, override: true).info

        let constraint: UniqueUUIDConstraint? = getConstraint(jobInfo)
        XCTAssertNotNil(constraint)
        XCTAssertEqual(constraint?.uuid, uuid)
        XCTAssertTrue(constraint?.override ?? false)
    }

    public func testBuilderGroup() throws {
        let type = UUID().uuidString
        let groupName = UUID().uuidString

        let jobInfo = JobBuilder(type: type).parallel(queueName: groupName).info
        XCTAssertEqual(jobInfo.queueName, groupName)
    }

    public func testBuilderDelay() throws {
        let type = UUID().uuidString
        let delay: Double = 1234

        let jobInfo = JobBuilder(type: type).delay(time: delay).info
        let constraint: DelayConstraint? = getConstraint(jobInfo)
        XCTAssertNotNil(constraint)
        XCTAssertEqual(constraint?.delay, delay)
    }

    public func testBuilderDeadlineCodable() throws {
        let type = UUID().uuidString
        let deadline = Date(timeIntervalSinceNow: TimeInterval(30))
        let jobInfo = JobBuilder(type: type).deadline(date: deadline).info

        let constraint: DeadlineConstraint? = getConstraint(jobInfo)
        XCTAssertNotNil(constraint)
        XCTAssertEqual(constraint?.deadline, deadline)
    }

    public func testBuilderPeriodicUnlimited() throws {
        let type = UUID().uuidString
        let interval: Double = 12341
        let executor = Executor.foreground

        let jobInfo = JobBuilder(type: type).periodic(limit: .unlimited, interval: interval).info

        let constraint: RepeatConstraint? = getConstraint(jobInfo)
        XCTAssertNotNil(constraint)

        XCTAssertEqual(constraint?.maxRun, Limit.unlimited)
        XCTAssertEqual(constraint?.interval, interval)
        XCTAssertEqual(constraint?.executor, executor)
    }

    public func testBuilderInternetCellular() throws {
        let type = UUID().uuidString
        let network: NetworkType = .cellular

        let jobInfo = JobBuilder(type: type).internet(atLeast: network).info

        let constraint: NetworkConstraint? = getConstraint(jobInfo)
        XCTAssertNotNil(constraint)
        XCTAssertEqual(constraint?.networkType, NetworkType.cellular)
    }

    public func testBuilderInternetWifi() throws {
        let type = UUID().uuidString
        let network: NetworkType = .wifi

        let jobInfo = JobBuilder(type: type).internet(atLeast: network).info

        let constraint: NetworkConstraint? = getConstraint(jobInfo)
        XCTAssertNotNil(constraint)
        XCTAssertEqual(constraint?.networkType, NetworkType.wifi)
    }

    public func testBuilderRetryUnlimited() throws {
        let type = UUID().uuidString

        let jobInfo = JobBuilder(type: type).retry(limit: .unlimited).info

        let constraint: JobRetryConstraint? = getConstraint(jobInfo)
        XCTAssertNotNil(constraint)
        XCTAssertEqual(constraint?.limit, Limit.unlimited)
    }

    public func testBuilderRetryLimited() throws {
        let type = UUID().uuidString
        let limited: Double = 123

        let jobInfo = JobBuilder(type: type).retry(limit: .limited(limited)).info

        let constraint: JobRetryConstraint? = getConstraint(jobInfo)
        XCTAssertNotNil(constraint)
        XCTAssertEqual(constraint?.limit, Limit.limited(limited))
    }

    public func testBuilderAddTag() throws {
        let type = UUID().uuidString
        let tag1 = UUID().uuidString
        let tag2 = UUID().uuidString

        let jobInfo = JobBuilder(type: type).addTag(tag: tag1).addTag(tag: tag2).info

        let constraint: TagConstraint? = getConstraint(jobInfo)
        XCTAssertNotNil(constraint)
        XCTAssertEqual(constraint?.tags.contains(tag1), true)
        XCTAssertEqual(constraint?.tags.contains(tag2), true)
    }

    public func testBuilderWithFreeArgs() {
        let type = UUID().uuidString
        let params: [String: Any] = [UUID().uuidString: [UUID().uuidString: self]]

        let creator = TestCreator([type: TestJob()])
        let manager = SwiftQueueManagerBuilder(creator: creator)
                .set(persister: NoPersister.shared)
                .build()

        // No assert expected
        // This is just to test if the serialization failed on self
        JobBuilder(type: type).with(params: params).schedule(manager: manager)
    }

    public func testBuilderRequireCharging() throws {
        let type = UUID().uuidString

        let jobInfo = JobBuilder(type: type).requireCharging().info

        let constraint: BatteryChargingConstraint? = getConstraint(jobInfo)
        XCTAssertNotNil(constraint)
    }

    func testCopyBuilder() {
        var origin = JobBuilder(type: UUID().uuidString)
        let builder = origin.copy()

        origin = origin.internet(atLeast: .wifi)

        let constraint: NetworkConstraint? = getConstraint(builder.info)
        XCTAssertNil(constraint)
    }

}
