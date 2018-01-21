//
// Created by Lucas Nelaupe on 12/10/17.
//

import Foundation

import XCTest
import Dispatch
@testable import SwiftQueue

class SwiftQueueBuilderTests: XCTestCase {

    public func testBuilderJobType() {
        let type = UUID().uuidString

        let jobInfo = toJobInfo(type: type, JobBuilder(type: type))
        XCTAssertEqual(jobInfo?.type, type)
    }

    public func testBuilderSingleInstance() {
        let type = UUID().uuidString
        let uuid = UUID().uuidString

        let jobInfo = toJobInfo(type: type, JobBuilder(type: type).singleInstance(forId: uuid))
        XCTAssertEqual(jobInfo?.uuid, uuid)
        XCTAssertEqual(jobInfo?.override, false)
    }

    public func testBuilderSingleInstanceOverride() {
        let type = UUID().uuidString
        let uuid = UUID().uuidString

        let jobInfo = toJobInfo(type: type, JobBuilder(type: type).singleInstance(forId: uuid, override: true))
        XCTAssertEqual(jobInfo?.uuid, uuid)
        XCTAssertEqual(jobInfo?.override, true)
    }

    public func testBuilderGroup() {
        let type = UUID().uuidString
        let groupName = UUID().uuidString

        let jobInfo = toJobInfo(type: type, JobBuilder(type: type).group(name: groupName))
        XCTAssertEqual(jobInfo?.group, groupName)
    }

    public func testBuilderDelay() {
        let type = UUID().uuidString
        let delay: Double = 1234

        let jobInfo = toJobInfo(type: type, JobBuilder(type: type).delay(time: delay))
        XCTAssertEqual(jobInfo?.delay, delay)
    }

    public func testBuilderDeadline() {
        let type = UUID().uuidString
        let deadline = Date(timeIntervalSinceNow: TimeInterval(30))

        let jobInfo = toJobInfo(type: type, JobBuilder(type: type).deadline(date: deadline))
        XCTAssertEqual(jobInfo?.deadline.map(dateFormatter.string), dateFormatter.string(from: deadline))
    }

    public func testBuilderPeriodicUnlimited() {
        let type = UUID().uuidString
        let interval: Double = 12341

        let jobInfo = toJobInfo(type: type, JobBuilder(type: type).periodic(limit: .unlimited, interval: interval))
        XCTAssertEqual(jobInfo?.maxRun, Limit.unlimited)
        XCTAssertEqual(jobInfo?.interval, interval)
    }

    public func testBuilderPeriodicLimited() {
        let type = UUID().uuidString
        let limited: Int = 123
        let interval: Double = 12342

        let jobInfo = toJobInfo(type: type, JobBuilder(type: type).periodic(limit: .limited(limited), interval: interval))
        XCTAssertEqual(jobInfo?.maxRun, Limit.limited(limited))
        XCTAssertEqual(jobInfo?.interval, interval)
    }

    public func testBuilderInternetAny() {
        let type = UUID().uuidString
        let network: NetworkType = .any

        let jobInfo = toJobInfo(type: type, JobBuilder(type: type).internet(atLeast: network))
        XCTAssertEqual(jobInfo?.requireNetwork, network)
    }

    public func testBuilderInternetCellular() {
        let type = UUID().uuidString
        let network: NetworkType = .cellular

        let jobInfo = toJobInfo(type: type, JobBuilder(type: type).internet(atLeast: network))
        XCTAssertEqual(jobInfo?.requireNetwork, network)
    }

    public func testBuilderInternetWifi() {
        let type = UUID().uuidString
        let network: NetworkType = .wifi

        let jobInfo = toJobInfo(type: type, JobBuilder(type: type).internet(atLeast: network))
        XCTAssertEqual(jobInfo?.requireNetwork, network)
    }

    public func testBuilderRetryUnlimited() {
        let type = UUID().uuidString

        let jobInfo = toJobInfo(type: type, JobBuilder(type: type).retry(limit: .unlimited))
        XCTAssertEqual(jobInfo?.retries, Limit.unlimited)
    }

    public func testBuilderRetryLimited() {
        let type = UUID().uuidString
        let limited = 123

        let jobInfo = toJobInfo(type: type, JobBuilder(type: type).retry(limit: .limited(limited)))
        XCTAssertEqual(jobInfo?.retries, Limit.limited(limited))
    }

    public func testBuilderAddTag() {
        let type = UUID().uuidString
        let tag1 = UUID().uuidString
        let tag2 = UUID().uuidString

        let jobInfo = toJobInfo(type: type, JobBuilder(type: type).addTag(tag: tag1).addTag(tag: tag2))
        XCTAssertTrue(jobInfo?.tags.contains(tag1) ?? false)
        XCTAssertTrue(jobInfo?.tags.contains(tag2) ?? false)
    }

    public func testBuilderWith() {
        let type = UUID().uuidString
        let params: [String: Any] = [UUID().uuidString: [UUID().uuidString: UUID().uuidString]]

        let jobInfo = toJobInfo(type: type, JobBuilder(type: type).with(params: params))
        XCTAssertTrue(NSDictionary(dictionary: params).isEqual(to: jobInfo?.params))
    }

    public func testBuilderWithFreeArgs() {
        let type = UUID().uuidString
        let params: [String: Any] = [UUID().uuidString: [UUID().uuidString: self]]

        let creator = TestCreator([type: TestJob()])
        let manager = SwiftQueueManager(creators: [creator])
        
        // No assert expected
        JobBuilder(type: type).with(params: params).schedule(manager: manager)
    }

    private func toJobInfo(type: String, _ builder: JobBuilder) -> JobInfo? {
        let creator = TestCreator([type: TestJob()])
        let persister = PersisterTracker(key: UUID().uuidString)
        let manager = SwiftQueueManager(creators: [creator], persister: persister)

        builder.persist(required: true).schedule(manager: manager)

        let actual = SwiftQueueJob(json: persister.putData[0], creator: [creator])
        return actual?.info
    }

}
