//
// Created by Lucas Nelaupe on 11/8/17.
// Copyright (c) 2017 Lucas Nelaupe. All rights reserved.
//

import XCTest
@testable import SwiftQueue

class ConstraintTests: XCTestCase {

    func testPeriodicJob() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .periodic(limit: .limited(5))
                .schedule(manager: manager)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 5)
        XCTAssertEqual(job.onCompleteCalled, 1)
        XCTAssertEqual(job.onRetryCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 0)
    }

    func testPeriodicJobUnlimited() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .periodic(limit: .unlimited)
                .schedule(manager: manager)
        
        // Should run at least 100 times
        job.awaitRun(value: 1000)

        // Semaphore is async so the value is un-predicable
        XCTAssertTrue(job.onRunJobCalled > 50)
        XCTAssertEqual(job.onCompleteCalled, 0)
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
                .retry(limit: .limited(2))
                .schedule(manager: manager)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 3)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onRetryCalled, 2)
        XCTAssertEqual(job.onCancelCalled, 1)
    }

    func testRetryFailJobWithRetryDelayConstraint() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        job.result = JobError()
        job.retryConstraint = .retry(delay: 0.0000001)

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .retry(limit: .limited(2))
                .schedule(manager: manager)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 3)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onRetryCalled, 2)
        XCTAssertEqual(job.onCancelCalled, 1)
    }

    func testRetryUnlimitedShouldRetryManyTimes() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        job.result = JobError()
        job.retryConstraint = .retry(delay: 0)

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .retry(limit: .unlimited)
                .schedule(manager: manager)

        job.awaitRun(value: 10000)

        XCTAssertTrue(job.onRunJobCalled > 50)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertTrue(job.onRetryCalled > 50)
        XCTAssertEqual(job.onCancelCalled, 0)
    }

    func testRetryFailJobWithCancelConstraint() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        job.result = JobError()
        job.retryConstraint = .cancel

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .retry(limit: .limited(2))
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
                .retry(limit: .limited(2))
                .schedule(manager: manager)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 3)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onRetryCalled, 2)
        XCTAssertEqual(job.onCancelCalled, 1)
    }

    func testRepeatableJobWithExponentialBackoffRetry() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        job.result = JobError()
        job.retryConstraint = RetryConstraint.exponential(initial: 0.0000001)

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .retry(limit: .limited(1))
                .periodic()
                .schedule(manager: manager)

        job.await(TimeInterval(10))

        XCTAssertEqual(job.onRunJobCalled, 2)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onRetryCalled, 1)
        XCTAssertEqual(job.onCancelCalled, 1)
    }

    func testRepeatableJobWithDelay() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .periodic(limit: .limited(2), interval: 0.0000001)
                .schedule(manager: manager)

        job.await(TimeInterval(10))

        XCTAssertEqual(job.onRunJobCalled, 2)
        XCTAssertEqual(job.onCompleteCalled, 1)
        XCTAssertEqual(job.onRetryCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 0)
    }

    func testCancelRunningOperation() {
        let job = TestJob(10)
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .schedule(manager: manager)

        runInBackgroundAfter(0.0000001) {
            manager.cancelAllOperations()
        }

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 1)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onRetryCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 1)
    }

    func testCancelRunningOperationByTag() {
        let job = TestJob(10)
        let type = UUID().uuidString

        let tag = UUID().uuidString

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .addTag(tag: tag)
                .schedule(manager: manager)

        runInBackgroundAfter(0.0000001) {
            manager.cancelOperations(tag: tag)
        }

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 1)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onRetryCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 1)
    }
}
