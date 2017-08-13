//
// Created by Lucas Nelaupe on 11/8/17.
// Copyright (c) 2017 Lucas Nelaupe. All rights reserved.
//

import XCTest
@testable import SwiftQueue

class ConstraintTests: XCTestCase {

    func testDeadlineWhenSchedule() {
        let job = MyJob()
        let creator = MyCreator([MyJob.type: job])

        let queue = JobQueue(creators: [creator])
        JobBuilder(taskID: UUID().uuidString, jobType: MyJob.type)
                .deadline(date: Date(timeIntervalSinceNow: TimeInterval(-10)))
                .schedule(queue: queue)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 0)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onErrorCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 1)
    }

    func testDeadlineWhenRun() {
        let job1 = MyJob()
        let type1 = UUID().uuidString

        let job2 = MyJob()
        let type2 = UUID().uuidString

        let creator = MyCreator([type1: job1, type2: job2])

        let queue = JobQueue(creators: [creator])
        JobBuilder(taskID: UUID().uuidString, jobType: type1)
                .delay(inSecond: 1)
                .schedule(queue: queue)

        JobBuilder(taskID: UUID().uuidString, jobType: type2)
                .deadline(date: Date()) // After 1 second should fail
                .schedule(queue: queue)

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
        let queueId = UUID().uuidString

        let job = MyJob()
        let creator = MyCreator([MyJob.type: job])

        let taskID = UUID().uuidString
        let jobType = MyJob.type

        let task = JobBuilder(taskID: taskID, jobType: jobType)
                .deadline(date: Date())
                .build(job: creator.create(jobType: MyJob.type, params: nil)!)
                .toJSONString()!

        let persister = MyPersister(needRestore: queueId, task: task)

        _ = JobQueue(queueName: queueId, creators: [creator], persister: persister)

        XCTAssertNotNil(persister.onRestore)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 0)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onErrorCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 1)
    }

    func testPeriodicJob() {
        let job = MyJob()
        let type = UUID().uuidString

        let creator = MyCreator([type: job])

        let queue = JobQueue(creators: [creator])
        JobBuilder(taskID: UUID().uuidString, jobType: type)
                .periodic(count: 5)
                .schedule(queue: queue)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 5)
        XCTAssertEqual(job.onCompleteCalled, 1)
        XCTAssertEqual(job.onErrorCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 0)
    }

    func testRetryFailJobWithRetryConstraint() {
        let job = MyJob()
        let type = UUID().uuidString

        let creator = MyCreator([type: job])

        job.result = JobError()
        job.retryConstraint = .retry

        let queue = JobQueue(creators: [creator])
        JobBuilder(taskID: UUID().uuidString, jobType: type)
                .retry(max: 2)
                .schedule(queue: queue)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 3)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onErrorCalled, 2)
        XCTAssertEqual(job.onCancelCalled, 1)
    }

    func testRetryFailJobWithCancelConstraint() {
        let job = MyJob()
        let type = UUID().uuidString

        let creator = MyCreator([type: job])

        job.result = JobError()
        job.retryConstraint = .cancel

        let queue = JobQueue(creators: [creator])
        JobBuilder(taskID: UUID().uuidString, jobType: type)
                .retry(max: 2)
                .schedule(queue: queue)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 1)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onErrorCalled, 1)
        XCTAssertEqual(job.onCancelCalled, 1)
    }

    func testUniqueIdConstraintShouldCancelTheSecond() {
        let id = UUID().uuidString

        let job1 = MyJob()
        let type1 = UUID().uuidString

        let job2 = MyJob()
        let type2 = UUID().uuidString

        let creator = MyCreator([type1: job1, type2: job2])

        let queue = JobQueue(creators: [creator])
        JobBuilder(taskID: id, jobType: type1)
                .delay(inSecond: Int.max)
                .schedule(queue: queue)

        JobBuilder(taskID: id, jobType: type2).schedule(queue: queue)

        job2.await()

        XCTAssertEqual(job2.onRunJobCalled, 0)
        XCTAssertEqual(job2.onCompleteCalled, 0)
        XCTAssertEqual(job2.onErrorCalled, 0)
        XCTAssertEqual(job2.onCancelCalled, 1)
    }

}
