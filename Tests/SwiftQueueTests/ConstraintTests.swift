//
// Created by Lucas Nelaupe on 11/8/17.
// Copyright (c) 2017 Lucas Nelaupe. All rights reserved.
//

import XCTest
@testable import SwiftQueue

class ConstraintTests: XCTestCase {

    func testDeadlineWhenSchedule() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .deadline(date: Date(timeIntervalSinceNow: TimeInterval(-10)))
                .schedule(manager: manager)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 0)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onRetryCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 1)
    }

    func testDeadlineWhenRun() {
        let job1 = TestJob()
        let type1 = UUID().uuidString

        let job2 = TestJob()
        let type2 = UUID().uuidString

        let creator = TestCreator([type1: job1, type2: job2])

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type1)
                .delay(inSecond: 1)
                .retry(max: 5)
                .schedule(manager: manager)

        JobBuilder(type: type2)
                .deadline(date: Date()) // After 1 second should fail
                .retry(max: 5)
                .schedule(manager: manager)

        manager.waitUntilAllOperationsAreFinished()
        job1.await()

        XCTAssertEqual(job1.onRunJobCalled, 1)
        XCTAssertEqual(job1.onCompleteCalled, 1)
        XCTAssertEqual(job1.onRetryCalled, 0)
        XCTAssertEqual(job1.onCancelCalled, 0)

        job2.await()

        XCTAssertEqual(job2.onRunJobCalled, 0)
        XCTAssertEqual(job2.onCompleteCalled, 0)
        XCTAssertEqual(job2.onRetryCalled, 0)
        XCTAssertEqual(job2.onCancelCalled, 1)
    }

    func testDeadlineAfterSchedule() {
        let job1 = TestJob()
        let type1 = UUID().uuidString

        let creator = TestCreator([type1: job1])

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type1)
                .delay(inSecond: 60)
                .deadline(date: Date(timeIntervalSinceNow: TimeInterval(2)))
                .retry(max: 5)
                .schedule(manager: manager)

        manager.waitUntilAllOperationsAreFinished()
        job1.await()

        XCTAssertEqual(job1.onRunJobCalled, 0)
        XCTAssertEqual(job1.onCompleteCalled, 0)
        XCTAssertEqual(job1.onRetryCalled, 0)
        XCTAssertEqual(job1.onCancelCalled, 1)
    }

    func testDeadlineWhenDeserialize() {
        let group = UUID().uuidString

        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let taskId = UUID().uuidString

        let json = JobBuilder(type: type)
                .group(name: group)
                .deadline(date: Date())
                .build(job: job)
                .toJSONString()!

        let persister = PersisterTracker(key: UUID().uuidString)
        persister.put(queueName: group, taskId: taskId, data: json)

        _ = SwiftQueueManager(creators: [creator], persister: persister)

        XCTAssertEqual(group, persister.restoreQueueName)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 0)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onRetryCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 1)
    }

    func testPeriodicJob() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .periodic(count: 5)
                .schedule(manager: manager)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 5)
        XCTAssertEqual(job.onCompleteCalled, 1)
        XCTAssertEqual(job.onRetryCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 0)
    }

    func testRetryFailJobWithRetryConstraint() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        job.result = JobError()
        job.retryConstraint = .retry(delay: 0)

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .retry(max: 2)
                .schedule(manager: manager)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 3)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onRetryCalled, 2)
        XCTAssertEqual(job.onCancelCalled, 1)
    }

    func testRetryFailJobWithCancelConstraint() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        job.result = JobError()
        job.retryConstraint = .cancel

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .retry(max: 2)
                .schedule(manager: manager)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 1)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onRetryCalled, 1)
        XCTAssertEqual(job.onCancelCalled, 1)
    }

    func testRetryFailJobWithExponentialConstraint() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        job.result = JobError()
        job.retryConstraint = .exponential(initial: 0)

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .retry(max: 2)
                .schedule(manager: manager)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 3)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onRetryCalled, 2)
        XCTAssertEqual(job.onCancelCalled, 1)
    }

    func testUniqueIdConstraintShouldCancelTheSecond() {
        let id = UUID().uuidString

        let job1 = TestJob()
        let type1 = UUID().uuidString

        let job2 = TestJob()
        let type2 = UUID().uuidString

        let job3 = TestJob()
        let type3 = UUID().uuidString

        let creator = TestCreator([type1: job1, type2: job2, type3: job3])

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type1)
                .singleInstance(forId: id)
                .delay(inSecond: 3600)
                .schedule(manager: manager)

        JobBuilder(type: type2)
                .singleInstance(forId: id)
                .delay(inSecond: 3600)
                .schedule(manager: manager)

        JobBuilder(type: type3).singleInstance(forId: id).schedule(manager: manager)

        job3.await()

        XCTAssertEqual(job3.onRunJobCalled, 0)
        XCTAssertEqual(job3.onCompleteCalled, 0)
        XCTAssertEqual(job3.onRetryCalled, 0)
        XCTAssertEqual(job3.onCancelCalled, 1)

        manager.cancelAllOperations()
        manager.waitUntilAllOperationsAreFinished()
    }

    func testNonPersistedJobShouldNotBePersisted() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let persister = PersisterTracker(key: UUID().uuidString)

        let manager = SwiftQueueManager(creators: [creator], persister: persister)
        JobBuilder(type: type)
                .schedule(manager: manager)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 1)
        XCTAssertEqual(job.onCompleteCalled, 1)
        XCTAssertEqual(job.onRetryCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 0)

        XCTAssertEqual(0, persister.putQueueName.count)
        XCTAssertEqual(0, persister.putTaskId.count)
        XCTAssertEqual(0, persister.putData.count)
        XCTAssertEqual(0, persister.removeQueueName.count)
        XCTAssertEqual(0, persister.removeJobId.count)
    }

    func testRepeatableJobWithExponentialBackoffRetry() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        job.result = JobError()
        job.retryConstraint = RetryConstraint.exponential(initial: 1)

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .retry(max: 1)
                .periodic()
                .schedule(manager: manager)

        job.await(TimeInterval(10))

        XCTAssertEqual(job.onRunJobCalled, 2)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onRetryCalled, 1)
        XCTAssertEqual(job.onCancelCalled, 1)
    }

    func testNetworkConstraint() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
            .internet(atLeast: .cellular)
            .schedule(manager: manager)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 1)
        XCTAssertEqual(job.onCompleteCalled, 1)
        XCTAssertEqual(job.onRetryCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 0)
    }

    func testNetworkConstraintWifi() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
            .internet(atLeast: .wifi)
            .schedule(manager: manager)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 1)
        XCTAssertEqual(job.onCompleteCalled, 1)
        XCTAssertEqual(job.onRetryCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 0)
    }
}
