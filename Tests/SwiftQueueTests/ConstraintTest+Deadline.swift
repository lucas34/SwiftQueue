// The MIT License (MIT)
//
// Copyright (c) 2022 Lucas Nelaupe
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

class ConstraintTestDeadline: XCTestCase {

    func testDeadlineWhenSchedule() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoPersister.shared).build()
        JobBuilder(type: type)
                .deadline(date: Date(timeIntervalSinceNow: TimeInterval(-10)))
                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertRemovedBeforeRun(reason: .deadline)
    }

    func testDeadlineWhenRun() {
        let (type1, job1) = (UUID().uuidString, TestJob())
        let (type2, job2) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type1: job1, type2: job2])
        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoPersister.shared).build()

        JobBuilder(type: type1)
                .delay(time: Double.leastNonzeroMagnitude)
                .retry(limit: .limited(5))
                .schedule(manager: manager)

        JobBuilder(type: type2)
                .deadline(date: Date()) // After 1 second should fail
                .retry(limit: .unlimited)
                .schedule(manager: manager)

        manager.waitUntilAllOperationsAreFinished()

        job1.awaitForRemoval()
        job1.assertSingleCompletion()

        job2.awaitForRemoval()
        job2.assertRemovedBeforeRun(reason: .deadline)
    }

    func testDeadlineWhenDeserialize() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])

        let group = UUID().uuidString

        let json = JobBuilder(type: type)
                .parallel(queueName: group)
                .deadline(date: Date())
                .build(job: job)
                .toJSONStringSafe()

        let persister = PersisterTracker(key: UUID().uuidString)
        persister.put(queueName: group, taskId: UUID().uuidString, data: json)

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: persister).build()

        job.awaitForRemoval()
        job.assertRemovedBeforeRun(reason: .deadline)

        XCTAssertEqual(group, persister.restoreQueueName)

        manager.waitUntilAllOperationsAreFinished()
    }

    func testDeadlineAfterSchedule() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoPersister.shared).build()
        JobBuilder(type: type)
                .delay(time: 60)
                .deadline(date: Date(timeIntervalSinceNow: Double.leastNonzeroMagnitude))
                .retry(limit: .unlimited)
                .schedule(manager: manager)

        manager.waitUntilAllOperationsAreFinished()

        job.awaitForRemoval()
        job.assertRemovedBeforeRun(reason: .deadline)
    }

}
