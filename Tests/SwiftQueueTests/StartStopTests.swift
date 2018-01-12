//
// Created by Lucas Nelaupe on 29/8/17.
// Copyright (c) 2017 Lucas Nelaupe. All rights reserved.
//

import XCTest
@testable import SwiftQueue

class StartStopTests: XCTestCase {

    func testScheduleWhenQueueStop() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManager(creators: [creator])

        manager.pause()

        JobBuilder(type: type).schedule(manager: manager)

        // No run
        XCTAssertEqual(job.onRunJobCalled, 0)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onRetryCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 0)

        manager.start()
        job.await()

        XCTAssertEqual(job.onRunJobCalled, 1)
        XCTAssertEqual(job.onCompleteCalled, 1)
        XCTAssertEqual(job.onRetryCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 0)
    }

    func testSchedulePeriodicJobThenStart() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManager(creators: [creator])

        manager.pause()

        JobBuilder(type: type).periodic(limit: .limited(4), interval: 0).schedule(manager: manager)

        // No run
        XCTAssertEqual(job.onRunJobCalled, 0)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onRetryCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 0)

        manager.start()
        manager.start()
        manager.start()
        manager.start()
        manager.start()
        manager.start()
        manager.start()
        job.await()

        XCTAssertEqual(job.onRunJobCalled, 4)
        XCTAssertEqual(job.onCompleteCalled, 1)
        XCTAssertEqual(job.onRetryCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 0)
    }

    func testPauseQueue() {
        let job1 = TestJob()
        let type1 = UUID().uuidString

        let job2 = TestJob()
        let type2 = UUID().uuidString

        let creator = TestCreator([type1: job1, type2: job2])

        let manager = SwiftQueueManager(creators: [creator])

        JobBuilder(type: type1).schedule(manager: manager)

        // Even if pause, if the job is already scheduled it will run
        manager.pause()

        JobBuilder(type: type2).schedule(manager: manager)

        job1.await()

        XCTAssertEqual(job1.onRunJobCalled, 1)
        XCTAssertEqual(job1.onCompleteCalled, 1)
        XCTAssertEqual(job1.onRetryCalled, 0)
        XCTAssertEqual(job1.onCancelCalled, 0)

        // Not run yet
        XCTAssertEqual(job2.onRunJobCalled, 0)
        XCTAssertEqual(job2.onCompleteCalled, 0)
        XCTAssertEqual(job2.onRetryCalled, 0)
        XCTAssertEqual(job2.onCancelCalled, 0)

        manager.start()
        job2.await()

        XCTAssertEqual(job2.onRunJobCalled, 1)
        XCTAssertEqual(job2.onCompleteCalled, 1)
        XCTAssertEqual(job2.onRetryCalled, 0)
        XCTAssertEqual(job2.onCancelCalled, 0)

    }

}
