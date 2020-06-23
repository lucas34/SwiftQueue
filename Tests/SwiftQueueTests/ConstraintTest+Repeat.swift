// The MIT License (MIT)
//
// Copyright (c) 2019 Lucas Nelaupe
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import XCTest
@testable import SwiftQueue

class ConstraintTestRepeat: XCTestCase {

    func testPeriodicJob() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoPersister.shared).build()
        JobBuilder(type: type)
                .periodic(limit: .limited(5))
                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertRunCount(expected: 5)
        job.assertCompletedCount(expected: 1)
        job.assertRetriedCount(expected: 0)
        job.assertCanceledCount(expected: 0)
        job.assertNoError()
    }

    func testPeriodicJobUnlimited() {
        let runLimit = 100
        let type = UUID().uuidString

        var runCount = 0

        let job = TestJob(retry: .retry(delay: 0)) {
            runCount += 1
            if runCount == runLimit {
                $0.done(.fail(JobError()))
            } else {
                $0.done(.success)
            }
        }

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoPersister.shared).build()
        JobBuilder(type: type)
                .periodic(limit: .unlimited)
                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertRunCount(expected: runLimit)
        job.assertCompletedCount(expected: 0)
        job.assertRetriedCount(expected: 0)
        job.assertCanceledCount(expected: 1)
        job.assertError()
    }

    func testRepeatableJobWithDelay() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoPersister.shared).build()
        JobBuilder(type: type)
                .periodic(limit: .limited(2), interval: Double.leastNonzeroMagnitude)
                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertRunCount(expected: 2)
        job.assertCompletedCount(expected: 1)
        job.assertRetriedCount(expected: 0)
        job.assertCanceledCount(expected: 0)
        job.assertNoError()
    }

    func testRepeatSerialisation() {
        let (type, job, jobId) = (UUID().uuidString, TestJob(), UUID().uuidString)
        let queueId = UUID().uuidString
        let creator = TestCreator([type: job])

        let task = JobBuilder(type: type)
                .singleInstance(forId: jobId)
                .periodic(limit: .limited(2), interval: Double.leastNonzeroMagnitude)
                .build(job: job)
                .toJSONStringSafe()

        // Should invert when deserialize
        let persister = PersisterTracker(key: UUID().uuidString)
        persister.put(queueName: queueId, taskId: jobId, data: task)

        let restore = persister.restore()
        XCTAssertEqual(restore.count, 1)
        XCTAssertEqual(restore[0], queueId)

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: persister).build()

        XCTAssertEqual(queueId, persister.restoreQueueName)

        job.awaitForRemoval()
        job.assertRunCount(expected: 2)
        job.assertCompletedCount(expected: 1)
        job.assertRetriedCount(expected: 0)
        job.assertCanceledCount(expected: 0)
        job.assertNoError()

        manager.waitUntilAllOperationsAreFinished()
    }

}
