//
// Created by Lucas Nelaupe on 13/12/17.
//

import Foundation
import XCTest
@testable import SwiftQueue

class ConstraintDeadlineTests: XCTestCase {

    func testDeadlineWhenSchedule() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .deadline(date: Date(timeIntervalSinceNow: TimeInterval(-10)))
                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertRemovedBeforeRun(reason: .deadline)
    }

    func testDeadlineWhenRun() {
        let job1 = TestJob()
        let type1 = UUID().uuidString

        let job2 = TestJob()
        let type2 = UUID().uuidString

        let creator = TestCreator([type1: job1, type2: job2])

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type1)
                .delay(time: Double.leastNonzeroMagnitude)
                .retry(limit: .limited(5))
                .schedule(manager: manager)

        JobBuilder(type: type2)
                .deadline(date: Date()) // After 1 second should fail
                .retry(limit: .unlimited)
                .schedule(manager: manager)

        manager.waitUntilAllOperationsAreFinished()

        job1.awaitForRemoval()
        job1.assertSingleCompletion()

        job2.awaitForRemoval()
        job2.assertRemovedBeforeRun(reason: .deadline)
    }

    func testDeadlineWhenDeserialize() {
        let group = UUID().uuidString

        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let jobUUID = UUID().uuidString

        let json = JobBuilder(type: type)
                .group(name: group)
                .deadline(date: Date())
                .build(job: job)
                .toJSONString()!

        let persister = PersisterTracker(key: UUID().uuidString)
        persister.put(queueName: group, taskId: jobUUID, data: json)

        _ = SwiftQueueManager(creators: [creator], persister: persister)

        XCTAssertEqual(group, persister.restoreQueueName)

        job.awaitForRemoval()
        job.assertRemovedBeforeRun(reason: .deadline)
    }

    func testDeadlineAfterSchedule() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .delay(time: 60)
                .deadline(date: Date(timeIntervalSinceNow: Double.leastNonzeroMagnitude))
                .retry(limit: .unlimited)
                .schedule(manager: manager)

        manager.waitUntilAllOperationsAreFinished()

        job.awaitForRemoval()
        job.assertRemovedBeforeRun(reason: .deadline)
    }

}
