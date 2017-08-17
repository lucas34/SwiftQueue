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

        let queue = SwiftQueue(queueName: expected)
        XCTAssertEqual(queue.name, expected)
    }

    func testBuilderAssignEverything() {
        let job = MyJob()
        let type = UUID().uuidString

        let creator = MyCreator([type: job])

        let taskID = UUID().uuidString
        let jobType = type
        let tag = UUID().uuidString
        let delay = 12345
        let deadline = Date(timeIntervalSinceNow: TimeInterval(UInt64.max))
        let requireNetwork = NetworkType.wifi
        let isPersisted = true // REquiered
        let params = UUID().uuidString
        let runCount = 5
        let retries = 3
        let interval: Double = 10

        let persister = PersisterTracker()

        let queue = SwiftQueue(creators: [creator], persister: persister)
        JobBuilder(taskID: taskID, jobType: jobType)
                .addTag(tag: tag)
                .delay(inSecond: delay)
                .deadline(date: deadline)
                .internet(atLeast: .wifi)
                .persist(required: true)
                .with(params: params)
                .retry(max: retries)
                .periodic(count: runCount, interval: interval)
                .schedule(queue: queue)

        XCTAssertEqual(taskID, persister.putTaskId)
        XCTAssertEqual(queue.name, persister.putQueueName)

        let task = JobTask(json: persister.putData, creator: [creator])

        XCTAssertEqual(task?.name, taskID)
        XCTAssertEqual(task?.taskID, taskID)
        XCTAssertEqual(task?.jobType, jobType)
        XCTAssertEqual(task?.tags.first, tag)
        XCTAssertEqual(task?.delay, delay)
        // Due to loss of precision need to convert
        XCTAssertEqual(task?.deadline, dateFormatter.date(from: dateFormatter.string(from: deadline)))
        XCTAssertEqual(task?.requireNetwork, requireNetwork)
        XCTAssertEqual(task?.isPersisted, isPersisted)
        XCTAssertEqual(task?.params as? String, params)
        XCTAssertEqual(task?.runCount, runCount)
        XCTAssertEqual(task?.retries, retries)
        XCTAssertEqual(task?.interval, interval)
    }

    func testRunSucessJob() {
        let job = MyJob()
        let type = UUID().uuidString

        let creator = MyCreator([type: job])

        let queue = SwiftQueue(creators: [creator])
        JobBuilder(taskID: UUID().uuidString, jobType: type)
                .schedule(queue: queue)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 1)
        XCTAssertEqual(job.onCompleteCalled, 1)
        XCTAssertEqual(job.onErrorCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 0)
    }

    func testScheduleJobWithoutCreatorNoError() {
        let queue = SwiftQueue()
        JobBuilder(taskID: UUID().uuidString, jobType: UUID().uuidString)
                .schedule(queue: queue)
    }

    func testCancelWithTag() {
        let id = UUID().uuidString
        let tag = UUID().uuidString
        let type = UUID().uuidString

        let job = MyJob()
        let creator = MyCreator([type: job])

        let persister = PersisterTracker()

        let queue = SwiftQueue(creators: [creator], persister: persister)

        JobBuilder(taskID: id, jobType: type)
                .delay(inSecond: Int.max)
                .addTag(tag: tag)
                .schedule(queue: queue)

        queue.cancelOperation(tag: tag)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 0)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onErrorCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 1)

        XCTAssertEqual(id, persister.removeTaskId)
        XCTAssertEqual(queue.name, persister.removeQueueName)
    }

//    func testCancelAll() {
//        let id = UUID().uuidString
//        let tag = UUID().uuidString
//        let type = UUID().uuidString
//
//        let job = MyJob()
//        let creator = MyCreator([type: job])
//
//        let persister = MyPersister()
//
//        let queue = SwiftQueue(creators: [creator], persister: persister)
//
//        JobBuilder(taskID: id, jobType: type)
//                .delay(inSecond: Int.max)
//                .addTag(tag: tag)
//                .schedule(queue: queue)
//
//        queue.cancelAllOperations()
//
//        job.await()
//
//        XCTAssertEqual(job.onRunJobCalled, 0)
//        XCTAssertEqual(job.onCompleteCalled, 0)
//        XCTAssertEqual(job.onErrorCalled, 0)
//        XCTAssertEqual(job.onCancelCalled, 1)
//
//        XCTAssertEqual(id, persister.onRemoveUUID)
//    }

    func testSerialiseDeserialize() throws {
        let job = MyJob()
        let type = UUID().uuidString

        let creator = MyCreator([type: job])

        let taskID = UUID().uuidString
        let jobType = type
        let tag = UUID().uuidString
        let delay = 12345
        let deadline = Date(timeIntervalSinceNow: TimeInterval(-10))
        let requireNetwork = NetworkType.any
        let isPersisted = true // REquiered
        let params = UUID().uuidString
        let runCount = 5
        let retries = 3
        let interval: Double = 1

        let json = JobBuilder(taskID: taskID, jobType: jobType)
                .addTag(tag: tag)
                .delay(inSecond: delay)
                .deadline(date: deadline)
                .internet(atLeast: requireNetwork)
                .persist(required: true)
                .with(params: params) // Useless because we shortcut it
                .retry(max: retries)
                .periodic(count: runCount, interval: interval)
                .build(job: MyJob())
                .toJSONString() ?? ""

        let task = JobTask(json: json, creator: [creator])

        XCTAssertEqual(task?.taskID, taskID)
        XCTAssertEqual(task?.jobType, jobType)
        XCTAssertEqual(task?.tags.first, tag)
        XCTAssertEqual(task?.delay, delay)
        // Due to loss of precision need to convert
        XCTAssertEqual(task?.deadline, dateFormatter.date(from: dateFormatter.string(from: deadline)))
        XCTAssertEqual(task?.requireNetwork, requireNetwork)
        XCTAssertEqual(task?.isPersisted, isPersisted)
        XCTAssertEqual(task?.params as? String, params)
        XCTAssertEqual(task?.runCount, runCount)
        XCTAssertEqual(task?.retries, retries)
        XCTAssertEqual(task?.interval, interval)
    }

    func testLoadSerializedSortedTaskShouldRunSuccess() {
        let queueId = UUID().uuidString

        let job1 = MyJob()
        let type1 = UUID().uuidString
        let job1Id = UUID().uuidString

        let job2 = MyJob()
        let type2 = UUID().uuidString
        let job2Id = UUID().uuidString

        let creator = MyCreator([type1: job1, type2: job2])

        let task1 = JobBuilder(taskID: job1Id, jobType: type1)
                .build(job: job1)
                .toJSONString() ?? ""

        let task2 = JobBuilder(taskID: job2Id, jobType: type2)
                .build(job: job2)
                .toJSONString() ?? ""

        UserDefaults(suiteName: queueId)?.setValue(task2, forKey: job2Id)
        UserDefaults(suiteName: queueId)?.setValue(task1, forKey: job1Id)  // Should invert when deserialize

        let persister = PersisterTracker()
        _ = SwiftQueue(queueName: queueId, creators: [creator], persister: persister)

        XCTAssertEqual(queueId, persister.restoreQueueName)

        job1.await()

        XCTAssertEqual(job1.onRunJobCalled, 1)
        XCTAssertEqual(job1.onCompleteCalled, 1)
        XCTAssertEqual(job1.onErrorCalled, 0)
        XCTAssertEqual(job1.onCancelCalled, 0)

        job2.await()

        XCTAssertEqual(job2.onRunJobCalled, 1)
        XCTAssertEqual(job2.onCompleteCalled, 1)
        XCTAssertEqual(job2.onErrorCalled, 0)
        XCTAssertEqual(job2.onCancelCalled, 0)
    }

    func testFailInitDoesNotCrash() {
        XCTAssertNil(JobTask(json: "hey hey", creator: []))
    }

    func testAddOperationNotJobTask() {
        let queue = SwiftQueue()
        let operation = Operation()
        queue.addOperation(operation) // Should not crash
    }

    func testCompleteTaskRemoveFromSerializer() {
        let queueId = UUID().uuidString

        let job = MyJob()
        let type = UUID().uuidString

        let creator = MyCreator([type: job])

        let taskID = UUID().uuidString

        let persister = PersisterTracker()

        let queue = SwiftQueue(queueName: queueId, creators: [creator], persister: persister)
        JobBuilder(taskID: taskID, jobType: type)
                .schedule(queue: queue)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 1)
        XCTAssertEqual(job.onCompleteCalled, 1)
        XCTAssertEqual(job.onErrorCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 0)

        XCTAssertNotNil(persister.removeTaskId)
        XCTAssertNotNil(persister.removeQueueName)
    }

    func testCompleteFailTaskRemoveFromSerializer() {
        let queueId = UUID().uuidString

        let job = MyJob()
        let type = UUID().uuidString

        job.result = JobError()

        let creator = MyCreator([type: job])

        let taskID = UUID().uuidString

        let persister = PersisterTracker()

        let queue = SwiftQueue(queueName: queueId, creators: [creator], persister: persister)
        JobBuilder(taskID: taskID, jobType: type)
                .schedule(queue: queue)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 1)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onErrorCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 1)

        XCTAssertEqual(taskID, persister.removeTaskId)
        XCTAssertEqual(queueId, persister.removeQueueName)
    }
}
