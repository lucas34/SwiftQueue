//
// Created by Lucas Nelaupe on 10/08/2017.
// Copyright (c) 2017 lucas34. All rights reserved.
//

import UIKit
import XCTest
import Dispatch
@testable import SwiftQueue

class SwiftQueueManagerTests: XCTestCase {
    
    override class func setUp() {
        super.setUp()

        UserDefaults().setValue(nil, forKey: "SwiftQueueInfo")
    }

    func testBuilderAssignEverything() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let taskID = UUID().uuidString
        let group = UUID().uuidString
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

        let manager = SwiftQueueManager(creators: [creator], persister: persister)
        JobBuilder(type: type)
                .singleInstance(forId: taskID)
                .group(name: group)
                .addTag(tag: tag)
                .delay(inSecond: delay)
                .deadline(date: deadline)
                .internet(atLeast: .wifi)
                .persist(required: true)
                .with(params: params)
                .retry(max: retries)
                .periodic(count: runCount, interval: interval)
                .schedule(manager: manager)

        XCTAssertEqual(taskID, persister.putTaskId)
        XCTAssertEqual(group, persister.putQueueName)

        let task = SwiftQueueJob(json: persister.putData, creator: [creator])

        XCTAssertEqual(task?.name, taskID)
        XCTAssertEqual(task?.taskID, taskID)
        XCTAssertEqual(task?.type, type)
        XCTAssertEqual(task?.group, group)
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
        XCTAssertEqual(job.onErrorCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 0)
    }

    func testScheduleJobWithoutCreatorNoError() {
        let manager = SwiftQueueManager(creators: [])
        JobBuilder(type: UUID().uuidString)
                .schedule(manager: manager)
    }

    func testCancelWithTag() {
        let id = UUID().uuidString
        let tag = UUID().uuidString
        let type = UUID().uuidString
        let group = UUID().uuidString

        let job = TestJob()
        let creator = TestCreator([type: job])

        let persister = PersisterTracker()

        let manager = SwiftQueueManager(creators: [creator], persister: persister)

        JobBuilder(type: type)
                .singleInstance(forId: id)
                .group(name: group)
                .delay(inSecond: Int.max)
                .addTag(tag: tag)
                .schedule(manager: manager)

        manager.cancelOperations(tag: tag)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 0)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onErrorCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 1)

        XCTAssertEqual(id, persister.removeTaskId)
        XCTAssertEqual(group, persister.removeQueueName)
    }

    func testCancelAll() {
        let id = UUID().uuidString
        let tag = UUID().uuidString
        let type = UUID().uuidString
        let group = UUID().uuidString

        let job = TestJob()
        let creator = TestCreator([type: job])

        let persister = PersisterTracker()

        let manager = SwiftQueueManager(creators: [creator], persister: persister)

        JobBuilder(type: type)
                .singleInstance(forId: id)
                .group(name: group)
                .delay(inSecond: Int.max)
                .addTag(tag: tag)
                .schedule(manager: manager)

        manager.cancelAllOperations()

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 0)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onErrorCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 1)

        XCTAssertEqual(id, persister.removeTaskId)
        XCTAssertEqual(group, persister.removeQueueName)
    }

    func testSerialiseDeserialize() throws {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let taskID = UUID().uuidString
        let tag = UUID().uuidString
        let group = UUID().uuidString
        let delay = 12345
        let deadline = Date(timeIntervalSinceNow: TimeInterval(-10))
        let requireNetwork = NetworkType.any
        let isPersisted = true // Required
        let params = UUID().uuidString
        let runCount = 5
        let retries = 3
        let interval: Double = 1

        let json = JobBuilder(type: type)
                .singleInstance(forId: taskID)
                .group(name: group)
                .addTag(tag: tag)
                .delay(inSecond: delay)
                .deadline(date: deadline)
                .internet(atLeast: requireNetwork)
                .persist(required: true)
                .with(params: params) // Useless because we shortcut it
                .retry(max: retries)
                .periodic(count: runCount, interval: interval)
                .build(job: TestJob())
                .toJSONString()!

        let task = SwiftQueueJob(json: json, creator: [creator])

        XCTAssertEqual(task?.taskID, taskID)
        XCTAssertEqual(task?.type, type)
        XCTAssertEqual(task?.group, group)
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

        let job1 = TestJob()
        let type1 = UUID().uuidString
        let job1Id = UUID().uuidString

        let job2 = TestJob()
        let type2 = UUID().uuidString
        let job2Id = UUID().uuidString

        let creator = TestCreator([type1: job1, type2: job2])

        let task1 = JobBuilder(type: type1)
                .singleInstance(forId: job1Id)
                .group(name: queueId)
                .build(job: job1)
                .toJSONString()!

        let task2 = JobBuilder(type: type2)
                .singleInstance(forId: job2Id)
                .group(name: queueId)
                .build(job: job2)
                .toJSONString()!

        // Should invert when deserialize
        let persister = PersisterTracker()
        persister.put(queueName: queueId, taskId: job2Id, data: task2)
        persister.put(queueName: queueId, taskId: job1Id, data: task1)

        _ = SwiftQueueManager(creators: [creator], persister: persister)

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
        XCTAssertNil(SwiftQueueJob(json: "hey hey", creator: []))
    }

    func testAddOperationNotJobTask() {
        let queue = SwiftQueue(queueName: UUID().uuidString, creators: [])
        let operation = Operation()
        queue.addOperation(operation) // Should not crash
    }

    func testCompleteTaskRemoveFromSerializer() {
        let queueId = UUID().uuidString

        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let taskID = UUID().uuidString

        let persister = PersisterTracker()

        let manager = SwiftQueueManager(creators: [creator], persister: persister)
        JobBuilder(type: type)
                .schedule(manager: manager)

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

        let job = TestJob()
        let type = UUID().uuidString

        job.result = JobError()

        let creator = TestCreator([type: job])

        let taskID = UUID().uuidString

        let persister = PersisterTracker()

        let manager = SwiftQueueManager(creators: [creator], persister: persister)
        JobBuilder(type: type)
                .singleInstance(forId: taskID)
                .group(name: queueId)
                .schedule(manager: manager)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 1)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onErrorCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 1)

        XCTAssertEqual(taskID, persister.removeTaskId)
        XCTAssertEqual(queueId, persister.removeQueueName)
    }
}
