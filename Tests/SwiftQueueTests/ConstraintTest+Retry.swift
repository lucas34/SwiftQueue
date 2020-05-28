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

class ConstraintTestRetry: XCTestCase {



    func testRetryUnlimitedShouldRetryManyTimes() {
        let runLimit = 100
        var runCount = 0

        let job = TestJob(retry: .retry(delay: 0)) {
            runCount += 1
            if runCount == runLimit {
                $0.done(.success)
            } else {
                $0.done(.fail(JobError()))
            }
        }

        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoSerializer.shared).build()
        JobBuilder(type: type)
                .retry(limit: .unlimited)
                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertRunCount(expected: runLimit)
        job.assertCompletedCount(expected: 1)
        job.assertRetriedCount(expected: runLimit - 1)
        job.assertCanceledCount(expected: 0)
        job.assertNoError()
    }

    func testRetryFailJobWithCancelConstraint() {
        let error = JobError()

        let (type, job) = (UUID().uuidString, TestJobFail(retry: .cancel, error: error))

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoSerializer.shared).build()
        JobBuilder(type: type)
                .retry(limit: .limited(2))
                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertRunCount(expected: 1)
        job.assertCompletedCount(expected: 0)
        job.assertRetriedCount(expected: 1)
        job.assertCanceledCount(expected: 1)
        job.assertError(queueError: .onRetryCancel(error))
    }

    func testRetryFailJobWithExponentialConstraint() {
        let job = TestJobFail(retry: .exponential(initial: 0))
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoSerializer.shared).build()
        JobBuilder(type: type)
                .retry(limit: .limited(2))
                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertRunCount(expected: 3)
        job.assertCompletedCount(expected: 0)
        job.assertRetriedCount(expected: 2)
        job.assertCanceledCount(expected: 1)
        job.assertError()
    }

    func testRetryFailJobWithExponentialMaxDelayConstraint() {
        let job = TestJobFail(retry: .exponentialWithLimit(initial: 0, maxDelay: 1))
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoSerializer.shared).build()
        JobBuilder(type: type)
                .retry(limit: .limited(2))
                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertRunCount(expected: 3)
        job.assertCompletedCount(expected: 0)
        job.assertRetriedCount(expected: 2)
        job.assertCanceledCount(expected: 1)
        job.assertError()
    }

    func testRepeatableJobWithExponentialBackoffRetry() {
        let type = UUID().uuidString
        let job = TestJobFail(retry: .exponential(initial: Double.leastNonzeroMagnitude))

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoSerializer.shared).build()
        JobBuilder(type: type)
                .retry(limit: .limited(1))
                .periodic()
                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertRunCount(expected: 2)
        job.assertCompletedCount(expected: 0)
        job.assertRetriedCount(expected: 1)
        job.assertCanceledCount(expected: 1)
        job.assertError()
    }

    func testRetryFailJobWithRetryConstraint() {
        let (type, job) = (UUID().uuidString, TestJobFail(retry: .retry(delay: 0)))

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoSerializer.shared).build()
        JobBuilder(type: type)
                .retry(limit: .limited(2))
                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertRunCount(expected: 3)
        job.assertCompletedCount(expected: 0)
        job.assertRetriedCount(expected: 2)
        job.assertCanceledCount(expected: 1)
        job.assertError()
    }

    func testRetryFailJobWithRetryDelayConstraint() {
        let job = TestJobFail(retry: .retry(delay: Double.leastNonzeroMagnitude))
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoSerializer.shared).build()
        JobBuilder(type: type)
                .retry(limit: .limited(2))
                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertRunCount(expected: 3)
        job.assertCompletedCount(expected: 0)
        job.assertRetriedCount(expected: 2)
        job.assertCanceledCount(expected: 1)
        job.assertError()
    }


}