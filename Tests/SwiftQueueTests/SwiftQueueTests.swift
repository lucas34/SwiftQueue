//
// Created by Lucas Nelaupe on 10/08/2017.
// Copyright (c) 2017 lucas34. All rights reserved.
//

import XCTest
import Dispatch
@testable import SwiftQueue

class SwiftQueueManagerTests: XCTestCase {

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
        XCTAssertEqual(job.onRetryCalled, 0)
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

        let persister = PersisterTracker(key: UUID().uuidString)

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
        XCTAssertEqual(job.onRetryCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 1)

        XCTAssertEqual(0, persister.putQueueName.count)
        XCTAssertEqual(0, persister.putTaskId.count)
        XCTAssertEqual(0, persister.putData.count)

        XCTAssertEqual(0, persister.removeJobId.count)
        XCTAssertEqual(0, persister.removeQueueName.count)
    }

    func testCancelWithTagShouldRemoveFromPersister() {
        let id = UUID().uuidString
        let tag = UUID().uuidString
        let type = UUID().uuidString
        let group = UUID().uuidString

        let job = TestJob()
        let creator = TestCreator([type: job])

        let persister = PersisterTracker(key: UUID().uuidString)

        let manager = SwiftQueueManager(creators: [creator], persister: persister)

        JobBuilder(type: type)
                .singleInstance(forId: id)
                .group(name: group)
                .delay(inSecond: Int.max)
                .addTag(tag: tag)
                .persist(required: true)
                .schedule(manager: manager)

        manager.cancelOperations(tag: tag)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 0)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onRetryCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 1)

        XCTAssertEqual([id], persister.removeJobId)
        XCTAssertEqual([group], persister.removeQueueName)
    }

    func testCancelAll() {
        let id = UUID().uuidString
        let tag = UUID().uuidString
        let type = UUID().uuidString
        let group = UUID().uuidString

        let job = TestJob()
        let creator = TestCreator([type: job])

        let persister = PersisterTracker(key: UUID().uuidString)

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
        XCTAssertEqual(job.onRetryCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 1)

        XCTAssertEqual(0, persister.putQueueName.count)
        XCTAssertEqual(0, persister.putTaskId.count)
        XCTAssertEqual(0, persister.putData.count)

        XCTAssertEqual(0, persister.removeJobId.count)
        XCTAssertEqual(0, persister.removeQueueName.count)
    }

    func testCancelAllShouldRemoveFromPersister() {
        let group = UUID().uuidString

        let id1 = UUID().uuidString
        let type1 = UUID().uuidString
        let job1 = TestJob()

        let id2 = UUID().uuidString
        let type2 = UUID().uuidString
        let job2 = TestJob()

        let creator = TestCreator([type1: job1, type2: job2])

        let persister = PersisterTracker(key: UUID().uuidString)

        let manager = SwiftQueueManager(creators: [creator], persister: persister)

        JobBuilder(type: type1)
                .singleInstance(forId: id1)
                .group(name: group)
                .delay(inSecond: Int.max)
                .persist(required: true)
                .schedule(manager: manager)

        JobBuilder(type: type2)
                .singleInstance(forId: id2)
                .group(name: group)
                .delay(inSecond: Int.max)
                .persist(required: true)
                .schedule(manager: manager)

        manager.cancelAllOperations()

        job1.await()
        job2.await()

        XCTAssertEqual(job1.onRunJobCalled, 0)
        XCTAssertEqual(job1.onCompleteCalled, 0)
        XCTAssertEqual(job1.onRetryCalled, 0)
        XCTAssertEqual(job1.onCancelCalled, 1)

        XCTAssertEqual(job2.onRunJobCalled, 0)
        XCTAssertEqual(job2.onCompleteCalled, 0)
        XCTAssertEqual(job2.onRetryCalled, 0)
        XCTAssertEqual(job2.onCancelCalled, 1)

        XCTAssertEqual([id1, id2], persister.removeJobId)
        XCTAssertEqual([group, group], persister.removeQueueName)
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
        let persister = PersisterTracker(key: UUID().uuidString)
        persister.put(queueName: queueId, taskId: job2Id, data: task2)
        XCTAssertEqual(persister.restore().count, 1)
        XCTAssertEqual(persister.restore()[0], queueId)

        persister.put(queueName: queueId, taskId: job1Id, data: task1)
        XCTAssertEqual(persister.restore().count, 1)
        XCTAssertEqual(persister.restore()[0], queueId)

        _ = SwiftQueueManager(creators: [creator], persister: persister)

        XCTAssertEqual(queueId, persister.restoreQueueName)

        job1.await()

        XCTAssertEqual(job1.onRunJobCalled, 1)
        XCTAssertEqual(job1.onCompleteCalled, 1)
        XCTAssertEqual(job1.onRetryCalled, 0)
        XCTAssertEqual(job1.onCancelCalled, 0)

        job2.await()

        XCTAssertEqual(job2.onRunJobCalled, 1)
        XCTAssertEqual(job2.onCompleteCalled, 1)
        XCTAssertEqual(job2.onRetryCalled, 0)
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

        let persister = PersisterTracker(key: UUID().uuidString)

        let manager = SwiftQueueManager(creators: [creator], persister: persister)
        JobBuilder(type: type)
                .singleInstance(forId: taskID)
                .group(name: queueId)
                .persist(required: true)
                .schedule(manager: manager)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 1)
        XCTAssertEqual(job.onCompleteCalled, 1)
        XCTAssertEqual(job.onRetryCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 0)

        XCTAssertEqual([taskID], persister.removeJobId)
        XCTAssertEqual([queueId], persister.removeQueueName)
    }

    func testCompleteFailTaskRemoveFromSerializer() {
        let queueId = UUID().uuidString

        let job = TestJob()
        let type = UUID().uuidString

        job.result = JobError()

        let creator = TestCreator([type: job])

        let taskID = UUID().uuidString

        let persister = PersisterTracker(key: UUID().uuidString)

        let manager = SwiftQueueManager(creators: [creator], persister: persister)
        JobBuilder(type: type)
                .singleInstance(forId: taskID)
                .group(name: queueId)
                .persist(required: true)
                .schedule(manager: manager)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 1)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onRetryCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 1)

        XCTAssertEqual([taskID], persister.removeJobId)
        XCTAssertEqual([queueId], persister.removeQueueName)
    }
}
