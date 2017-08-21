//
// Created by Lucas Nelaupe on 11/8/17.
// Copyright (c) 2017 Lucas Nelaupe. All rights reserved.
//

import XCTest
@testable import SwiftQueue

class ConstraintTests: XCTestCase {

    override class func setUp() {
        super.setUp()

        UserDefaults().set(nil, forKey: "SwiftQueueInfo")
        UserDefaults().synchronize()
    }

    override func tearDown() {
        UserDefaults().set(nil, forKey: "SwiftQueueInfo")
        UserDefaults().synchronize()
        super.tearDown()
    }

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
        XCTAssertEqual(job.onErrorCalled, 0)
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
                .schedule(manager: manager)

        JobBuilder(type: type2)
                .deadline(date: Date()) // After 1 second should fail
                .schedule(manager: manager)

        job1.await()

        XCTAssertEqual(job1.onRunJobCalled, 1)
        XCTAssertEqual(job1.onCompleteCalled, 1)
        XCTAssertEqual(job1.onErrorCalled, 0)
        XCTAssertEqual(job1.onCancelCalled, 0)

        job2.await()

        XCTAssertEqual(job2.onRunJobCalled, 0)
        XCTAssertEqual(job2.onCompleteCalled, 0)
        XCTAssertEqual(job2.onErrorCalled, 0)
        XCTAssertEqual(job2.onCancelCalled, 1)
    }

    func testDeadlineWhenDeserialize() {
        UserDefaults().set(nil, forKey: "SwiftQueueInfo")
        let group = UUID().uuidString

        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let taskID = UUID().uuidString

        let task = JobBuilder(type: type)
                .group(name: group)
                .deadline(date: Date())
                .build(job: job)
                .toJSONString()!

        let persister = PersisterTracker()
        persister.put(queueName: group, taskId: taskID, data: task)

        _ = SwiftQueueManager(creators: [creator], persister: persister)

        XCTAssertEqual(group, persister.restoreQueueName)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 0)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onErrorCalled, 0)
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
        XCTAssertEqual(job.onErrorCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 0)
    }

    func testRetryFailJobWithRetryConstraint() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        job.result = JobError()
        job.retryConstraint = .retry

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .retry(max: 2)
                .schedule(manager: manager)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 3)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onErrorCalled, 2)
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
        XCTAssertEqual(job.onErrorCalled, 1)
        XCTAssertEqual(job.onCancelCalled, 1)
    }

    func testUniqueIdConstraintShouldCancelTheSecond() {
        let id = UUID().uuidString

        let job1 = TestJob()
        let type1 = UUID().uuidString

        let job2 = TestJob()
        let type2 = UUID().uuidString

        let creator = TestCreator([type1: job1, type2: job2])

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type1)
                .singleInstance(forId: id)
                .delay(inSecond: Int.max)
                .schedule(manager: manager)

        JobBuilder(type: type2).singleInstance(forId: id).schedule(manager: manager)

        job2.await()

        XCTAssertEqual(job2.onRunJobCalled, 0)
        XCTAssertEqual(job2.onCompleteCalled, 0)
        XCTAssertEqual(job2.onErrorCalled, 0)
        XCTAssertEqual(job2.onCancelCalled, 1)
    }

}
