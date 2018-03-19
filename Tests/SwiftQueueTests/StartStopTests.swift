//
// Created by Lucas Nelaupe on 29/8/17.
// Copyright (c) 2017 Lucas Nelaupe. All rights reserved.
//

import XCTest
@testable import SwiftQueue

class StartStopTests: XCTestCase {

    func testScheduleWhenQueueStop() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManager(creators: [creator])

        manager.pause()

        JobBuilder(type: type).schedule(manager: manager)

        // No run
        job.assertNoRun()

        manager.start()

        job.awaitForRemoval()
        job.assertSingleCompletion()
    }

    func testSchedulePeriodicJobThenStart() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManager(creators: [creator])

        manager.pause()

        JobBuilder(type: type).periodic(limit: .limited(4), interval: 0).schedule(manager: manager)

        // No run
        job.assertNoRun()

        manager.start()
        manager.start()
        manager.start()
        manager.start()
        manager.start()
        manager.start()
        manager.start()

        job.awaitForRemoval()

        job.assertRunCount(expected: 4)
        job.assertCompletedCount(expected: 1)
        job.assertRetriedCount(expected: 0)
        job.assertCanceledCount(expected: 0)
        job.assertNoError()
    }

    func testPauseQueue() {
        let (type1, job1) = (UUID().uuidString, TestJob())
        let (type2, job2) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type1: job1, type2: job2])

        let manager = SwiftQueueManager(creators: [creator])

        JobBuilder(type: type1).schedule(manager: manager)

        // Even if pause, if the job is already scheduled it will run
        manager.pause()

        JobBuilder(type: type2).schedule(manager: manager)

        job1.awaitForRemoval()
        job1.assertSingleCompletion()

        // Not run yet
        job2.assertNoRun()

        manager.start()

        job2.awaitForRemoval()
        job2.assertSingleCompletion()
    }

}
