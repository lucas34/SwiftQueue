//
// Created by Lucas Nelaupe on 13/12/17.
//

import Foundation
import XCTest
@testable import SwiftQueue

class ConstraintDeadlineTests: XCTestCase {

    func testDeadlineWhenSchedule() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoSerializer.shared).build()
        JobBuilder(type: type)
                .deadline(date: Date(timeIntervalSinceNow: TimeInterval(-10)))
                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertRemovedBeforeRun(reason: .deadline)
    }

    func testDeadlineWhenRun() {
        let (type1, job1) = (UUID().uuidString, TestJob())
        let (type2, job2) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type1: job1, type2: job2])
        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoSerializer.shared).build()

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
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])

        let group = UUID().uuidString

        let json = JobBuilder(type: type)
                .group(name: group)
                .deadline(date: Date())
                .build(job: job)
                .toJSONStringSafe()

        let persister = PersisterTracker(key: UUID().uuidString)
        persister.put(queueName: group, taskId: UUID().uuidString, data: json)

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: persister).build()

        job.awaitForRemoval()
        job.assertRemovedBeforeRun(reason: .deadline)

        XCTAssertEqual(group, persister.restoreQueueName)

        manager.waitUntilAllOperationsAreFinished()
    }

    func testDeadlineAfterSchedule() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoSerializer.shared).build()
        JobBuilder(type: type)
                .delay(time: 60)
                .deadline(date: Date(timeIntervalSinceNow: Double.leastNonzeroMagnitude))
                .retry(limit: .unlimited)
                .schedule(manager: manager)

        manager.waitUntilAllOperationsAreFinished()

        job.awaitForRemoval()
        job.assertRemovedBeforeRun(reason: .deadline)
    }

    func testDeadlineBasic() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoSerializer.shared).build()
        JobBuilder(type: type)
                .deadline(date: Date(timeIntervalSinceNow: 0.1))
                .periodic(limit: .unlimited, interval: 0)
                .retry(limit: .unlimited)
                .schedule(manager: manager)

        manager.waitUntilAllOperationsAreFinished()

        job.awaitForRemoval()

        job.assertRunCount(atLeast: 10)
        job.assertCompletedCount(expected: 0)
        job.assertRetriedCount(expected: 0)
        job.assertCanceledCount(expected: 1)
        job.assertError(queueError: .deadline)
    }

    func testDelay() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoSerializer.shared).build()
        JobBuilder(type: type)
                .delay(time: 0.1)
                .schedule(manager: manager)

        manager.waitUntilAllOperationsAreFinished()

        job.awaitForRemoval()
        job.assertSingleCompletion()
    }

}
