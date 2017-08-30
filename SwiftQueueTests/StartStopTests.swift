//
// Created by Lucas Nelaupe on 29/8/17.
// Copyright (c) 2017 Lucas Nelaupe. All rights reserved.
//

import XCTest
@testable import SwiftQueue

class StartStopTests: XCTestCase {

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

    func testScheduleWhenQueueStop() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManager(creators: [creator])

        manager.pause()

        JobBuilder(type: type).schedule(manager: manager)

        job.await(TimeInterval(1)) // Wait for timeout

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

    func testPauseAlreadyRunningJob() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManager(creators: [creator])

        JobBuilder(type: type).delay(inSecond: 2).schedule(manager: manager)

        manager.pause()

        job.await(TimeInterval(3)) // Wait for timeout

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

        JobBuilder(type: type).periodic(count: 4, interval: 0).schedule(manager: manager)

        job.await()

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

}
