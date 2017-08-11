//
// Created by Lucas Nelaupe on 10/08/2017.
// Copyright (c) 2017 lucas34. All rights reserved.
//

import UIKit
import XCTest
import Dispatch
@testable import SwiftQueue

class SwiftQueueTests: XCTestCase {

    func testInitialization() {
        let expected = UUID().uuidString

        let queue = JobQueue(queueName: expected)
        XCTAssertEqual(queue.name, expected)
    }

    func testBuilderAssignEverything() {
        let job = MyJob()
        let creator = MyCreator([MyJob.type: job])

        let taskID = UUID().uuidString
        let jobType = MyJob.type
        let tag = UUID().uuidString
        let delay = 12345
        let deadline = Date(timeIntervalSinceNow: TimeInterval(UInt64.max))
        let needInternet = true
        let isPersisted = true // REquiered
        let params = UUID().uuidString
        let runCount = 5
        let retries = 3
        let interval: Double = 10

        let persister = MyPersister()

        let queue = JobQueue(creators: [creator], persister: persister)
        JobBuilder(taskID: taskID, jobType: jobType)
                .addTag(tag: tag)
                .delay(inSecond: delay)
                .deadline(date: deadline)
                .internet(required: true)
                .persist(required: true)
                .with(params: params)
                .retry(max: retries)
                .periodic(count: runCount, interval: interval)
                .schedule(queue: queue)

        XCTAssertNotNil(persister.onPut)
        let task = persister.onPut!

        XCTAssertEqual(task.name, taskID)
        XCTAssertEqual(task.taskID, taskID)
        XCTAssertEqual(task.jobType, jobType)
        XCTAssertEqual(task.tags.first, tag)
        XCTAssertEqual(task.delay, delay)
//TODO wtf        XCTAssertEqual(task.deadline, deadline)
        XCTAssertEqual(task.needInternet, needInternet)
        XCTAssertEqual(task.isPersisted, isPersisted)
        XCTAssertEqual(task.params as? String, params)
        XCTAssertEqual(task.runCount, runCount)
        XCTAssertEqual(task.retries, retries)
        XCTAssertEqual(task.interval, interval)
    }

    func testRunSucessJob() {
        let job = MyJob()
        let creator = MyCreator([MyJob.type: job])

        let queue = JobQueue(creators: [creator])
        JobBuilder(taskID: UUID().uuidString, jobType: MyJob.type)
                .schedule(queue: queue)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 1)
        XCTAssertEqual(job.onCompleteCalled, 1)
        XCTAssertEqual(job.onErrorCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 0)
    }

    func testScheduleJobWithoutCreatorNoError() {
        let queue = JobQueue()
        JobBuilder(taskID: UUID().uuidString, jobType: UUID().uuidString)
                .schedule(queue: queue)
    }


    func testCancelWithTag() {
        let id = UUID().uuidString
        let tag = UUID().uuidString

        let job = MyJob()
        let creator = MyCreator([MyJob.type: job])

        let persister = MyPersister()

        let queue = JobQueue(creators: [creator], persister: persister)

        JobBuilder(taskID: id, jobType: MyJob.type)
                .delay(inSecond: Int.max)
                .addTag(tag: tag)
                .schedule(queue: queue)

        queue.cancelOperation(tag: tag)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 0)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onErrorCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 1)

        XCTAssertEqual(id, persister.onRemoveUUID)
    }

    func testSerialiseDeserialize() throws {
        let job = MyJob()
        let creator = MyCreator([MyJob.type: job])

        let taskID = UUID().uuidString
        let jobType = MyJob.type
        let tag = UUID().uuidString
        let delay = 12345
        let deadline = Date(timeIntervalSinceNow: TimeInterval(-10))
        let needInternet = true
        let isPersisted = true // REquiered
        let params = UUID().uuidString
        let runCount = 5
        let retries = 3
        let interval: Double = 1

        let json = JobBuilder(taskID: taskID, jobType: jobType)
                .addTag(tag: tag)
                .delay(inSecond: delay)
                .deadline(date: deadline)
                .internet(required: true)
                .persist(required: true)
                .with(params: params) // Useless because we shortcut it
                .retry(max: retries)
                .periodic(count: runCount, interval: interval)
                .build(job: MyJob())
                .toJSONString()!

        let task = JobTask(json: json, creator: [creator])!

        XCTAssertEqual(task.taskID, taskID)
        XCTAssertEqual(task.jobType, jobType)
        XCTAssertEqual(task.tags.first, tag)
        XCTAssertEqual(task.delay, delay)
//TODO WTF        XCTAssertEqual(task.deadline, deadline)
        XCTAssertEqual(task.needInternet, needInternet)
        XCTAssertEqual(task.isPersisted, isPersisted)
        XCTAssertEqual(task.params as? String, params)
        XCTAssertEqual(task.runCount, runCount)
        XCTAssertEqual(task.retries, retries)
        XCTAssertEqual(task.interval, interval)
    }

    func testLoadSerializedTaskShouldRunSuccess() {
        let queueId = UUID().uuidString

        let job = MyJob()
        let creator = MyCreator([MyJob.type: job])

        let taskID = UUID().uuidString
        let jobType = MyJob.type

        let task = JobBuilder(taskID: taskID, jobType: jobType)
                .build(job: creator.create(jobType: MyJob.type, params: nil)!)
                .toJSONString()!

        let persister = MyPersister(needRestore: queueId, task: task)

        _ = JobQueue(queueName: queueId, creators: [creator], persister: persister)

        XCTAssertNotNil(persister.onRestore)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 1)
        XCTAssertEqual(job.onCompleteCalled, 1)
        XCTAssertEqual(job.onErrorCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 0)
    }

    func testFailInitDoesNotCrash() {
        XCTAssertNil(JobTask(json: "hey hey", creator: []))
    }

    func testAddOperationNotJobTask() {
        let queue = JobQueue()
        let operation = Operation()
        queue.addOperation(operation) // Should not crash
    }

    func testCompleteTaskRemoveFromSerializer() {
        let queueId = UUID().uuidString

        let job = MyJob()
        let creator = MyCreator([MyJob.type: job])

        let taskID = UUID().uuidString
        let jobType = MyJob.type

        let persister = MyPersister()

        let queue = JobQueue(queueName: queueId, creators: [creator], persister: persister)
        JobBuilder(taskID: taskID, jobType: jobType)
                .schedule(queue: queue)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 1)
        XCTAssertEqual(job.onCompleteCalled, 1)
        XCTAssertEqual(job.onErrorCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 0)

        XCTAssertNotNil(persister.onRemoveUUID)
        XCTAssertEqual(taskID, persister.onRemoveUUID!)
    }

    func testCompleteFailTaskRemoveFromSerializer() {
        let queueId = UUID().uuidString

        let job = MyJob()

        job.result = JobError()

        let creator = MyCreator([MyJob.type: job])

        let taskID = UUID().uuidString
        let jobType = MyJob.type

        let persister = MyPersister()

        let queue = JobQueue(queueName: queueId, creators: [creator], persister: persister)
        JobBuilder(taskID: taskID, jobType: jobType)
                .schedule(queue: queue)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 1)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onErrorCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 1)

        XCTAssertNotNil(persister.onRemoveUUID)
        XCTAssertEqual(taskID, persister.onRemoveUUID!)
    }

}
