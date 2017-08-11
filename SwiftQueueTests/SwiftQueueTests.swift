//
// Created by Lucas Nelaupe on 10/08/2017.
// Copyright (c) 2017 lucas34. All rights reserved.
//

import UIKit
import XCTest
import Dispatch
@testable import SwiftQueue

class MyJob: Job {
    public static let type = "MyJob"

    public let semaphore = DispatchSemaphore(value: 0)

    public var result: Error?

    public var onRunJobCalled = 0
    public var onErrorCalled = 0
    public var onCompleteCalled = 0
    public var onCancelCalled = 0

    public var params: Any?

    func onRunJob(callback: JobResult) throws {
        onRunJobCalled += 1
        callback.onDone(error: result) // Auto complete
    }

    func onError(error: Error) -> RetryConstraint {
        onErrorCalled += 1
        return RetryConstraint.retry
    }

    func onComplete() {
        onCompleteCalled += 1
        semaphore.signal()
    }

    func onCancel() {
        onCancelCalled += 1
        semaphore.signal()
    }

    func await() {
        semaphore.wait()
    }
}

class MyCreator: JobCreator {
    private let job: [String: Job]

    public init(_ job: [String: Job]) {
        self.job = job
    }

    func create(jobType: String, params: Any?) -> Job? {
        if let value = job[jobType] as? MyJob {
            value.params = params
            return value
        } else {
            return job[jobType]
        }
    }
}

class MyPersister: JobPersister {
    var onRestore: String?
    var onPut: JobTask?
    var onRemoveUUID: String?
    var onRemoveTag: String?

    var needRestore: String?
    var taskToRestore: String?

    convenience init(needRestore: String, task: String) {
        self.init()
        self.needRestore = needRestore
        self.taskToRestore = task
    }

    func restore(queueName: String) -> [String] {
        onRestore = queueName
        if let needRestore = needRestore, let taskToRestore = taskToRestore, needRestore == queueName {
            return [taskToRestore]
        }
        return []
    }

    func put(info: JobTask) {
        onPut = info
    }

    func remove(uuid: String) {
        onRemoveUUID = uuid
    }

    func remove(tag: String) {
        onRemoveTag = tag
    }
}

private class JobError: Error {

}

class SwiftQTests: XCTestCase {

    func testInitialization() {
        let expected = UUID().uuidString

        let queue = JobQueue(queueName: expected)
        XCTAssertEqual(queue.name, expected)
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

    func testRunSucessPeriodicJob() {
        let job = MyJob()
        let creator = MyCreator([MyJob.type: job])

        let queue = JobQueue(creators: [creator])
        JobBuilder(taskID: UUID().uuidString, jobType: MyJob.type)
                .periodic(count: 5)
                .schedule(queue: queue)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 5)
        XCTAssertEqual(job.onCompleteCalled, 1)
        XCTAssertEqual(job.onErrorCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 0)
    }

    func testRunFailedJob() {
        let job = MyJob()
        let creator = MyCreator([MyJob.type: job])

        job.result = JobError()

        let queue = JobQueue(creators: [creator])
        JobBuilder(taskID: UUID().uuidString, jobType: MyJob.type)
                .schedule(queue: queue)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 1)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onErrorCalled, 0) // Not called. Should we ?
        XCTAssertEqual(job.onCancelCalled, 1)
    }

    func testRunFailedJobRetry() {
        let job = MyJob()
        let creator = MyCreator([MyJob.type: job])

        job.result = JobError()

        let queue = JobQueue(creators: [creator])
        JobBuilder(taskID: UUID().uuidString, jobType: MyJob.type)
                .retry(max: 2)
                .schedule(queue: queue)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 3)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onErrorCalled, 2)
        XCTAssertEqual(job.onCancelCalled, 1)
    }

    func testSetParams() {
        let expected = UUID().uuidString

        let job = MyJob()
        let creator = MyCreator([MyJob.type: job])

        job.result = JobError()

        let queue = JobQueue(creators: [creator])
        JobBuilder(taskID: UUID().uuidString, jobType: MyJob.type)
                .with(params: expected)
                .schedule(queue: queue)

        job.await()

        XCTAssertEqual(job.params as? String, expected)
    }

    func testCancelWithTag() {
        let tag = UUID().uuidString

        let job = MyJob()
        let creator = MyCreator([MyJob.type: job])

        let queue = JobQueue(creators: [creator])
        JobBuilder(taskID: UUID().uuidString, jobType: MyJob.type)
                .addTag(tag: tag)
                .schedule(queue: queue)

        job.await()

        // TODO check if persisiter remove by tag
        // TODO cancel with tag
    }

    func testAssignEverything() {
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

        XCTAssertEqual(task.taskID, taskID)
        XCTAssertEqual(task.jobType, jobType)
        XCTAssertEqual(task.tags.first, tag)
        XCTAssertEqual(task.delay, delay)
        XCTAssertEqual(task.deadline, deadline)
        XCTAssertEqual(task.needInternet, needInternet)
        XCTAssertEqual(task.isPersisted, isPersisted)
//        XCTAssertEqual(task.params, params)
//        XCTAssertEqual(task.createTime, cre)
//        XCTAssertEqual(task.runCount, runCount)
        XCTAssertEqual(task.retries, retries)
        XCTAssertEqual(task.interval, interval)
    }

    func testScheduleJobWithoutCreatorNoError() {
        let queue = JobQueue()
        JobBuilder(taskID: UUID().uuidString, jobType: UUID().uuidString)
                .schedule(queue: queue)
    }

    func testScheduleAbortTaskBecauseOfDeadline() {
        let job = MyJob()
        let creator = MyCreator([MyJob.type: job])

        job.result = JobError()

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

    func testSerialiseDeserialise() throws {
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
//        XCTAssertEqual(task.deadline, deadline)
        XCTAssertEqual(task.needInternet, needInternet)
        XCTAssertEqual(task.isPersisted, isPersisted)
//        XCTAssertEqual(task.params, params)
//        XCTAssertEqual(task.createTime, cre)
        XCTAssertEqual(task.runCount, runCount)
        XCTAssertEqual(task.retries, retries)
        XCTAssertEqual(task.interval, interval)
    }

    func testLoadSerializedTask() {
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
