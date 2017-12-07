//
// Created by Lucas Nelaupe on 12/10/17.
//

import Foundation

import XCTest
import Dispatch
@testable import SwiftQueue

class SwiftQueueBuilderTests: XCTestCase {

    func testBuilderAssignEverything() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let taskID = UUID().uuidString
        let group = UUID().uuidString
        let tag = UUID().uuidString
        let delay = TimeInterval(12345)
        let deadline = Date(timeIntervalSinceNow: TimeInterval(30))
        let requireNetwork = NetworkType.wifi
        let isPersisted = true // Required
        let params: [String: Any] = [UUID().uuidString: UUID().uuidString]
        let maxRun = 5
        let retries = 3
        let interval: TimeInterval = 10

        let persister = PersisterTracker(key: UUID().uuidString)

        let manager = SwiftQueueManager(creators: [creator], persister: persister)
        JobBuilder(type: type)
                .singleInstance(forId: taskID)
                .group(name: group)
                .addTag(tag: tag)
                .delay(time: delay)
                .deadline(date: deadline)
                .internet(atLeast: .wifi)
                .persist(required: true)
                .with(params: params)
                .retry(max: retries)
                .periodic(count: maxRun, interval: interval)
                .schedule(manager: manager)

        XCTAssertEqual([taskID], persister.putTaskId)
        XCTAssertEqual([group], persister.putQueueName)
        XCTAssertEqual(1, persister.putData.count)

        let jobInfo = SwiftQueueJob(json: persister.putData[0], creator: [creator])

        XCTAssertEqual(jobInfo?.name, taskID)
        XCTAssertEqual(jobInfo?.uuid, taskID)
        XCTAssertEqual(jobInfo?.type, type)
        XCTAssertEqual(jobInfo?.group, group)
        XCTAssertEqual(jobInfo?.tags.first, tag)
        XCTAssertEqual(jobInfo?.delay, delay)
        // Due to loss of precision need to convert
        XCTAssertEqual(jobInfo?.deadline, dateFormatter.date(from: dateFormatter.string(from: deadline)))
        XCTAssertEqual(jobInfo?.requireNetwork, requireNetwork)
        XCTAssertEqual(jobInfo?.isPersisted, isPersisted)
        XCTAssertTrue(NSDictionary(dictionary: params).isEqual(to: jobInfo?.params))
        XCTAssertEqual(jobInfo?.maxRun, maxRun)
        XCTAssertEqual(jobInfo?.retries, retries)
        XCTAssertEqual(jobInfo?.interval, interval)
    }
}