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
import Dispatch
@testable import SwiftQueue

class PersisterTests: XCTestCase {

    func testLoadSerializedSortedJobShouldRunSuccess() {
        let (type1, job1, job1Id) = (UUID().uuidString, TestJob(), UUID().uuidString)
        let (type2, job2, job2Id) = (UUID().uuidString, TestJob(), UUID().uuidString)

        let queueId = UUID().uuidString

        let creator = TestCreator([type1: job1, type2: job2])

        let task1 = JobBuilder(type: type1)
                .singleInstance(forId: job1Id)
                .parallel(queueName: queueId)
                .build(job: job1)
                .toJSONStringSafe()

        let task2 = JobBuilder(type: type2)
                .singleInstance(forId: job2Id)
                .parallel(queueName: queueId)
                .build(job: job2)
                .toJSONStringSafe()

        // Should invert when deserialize
        let persister = PersisterTracker(key: UUID().uuidString)
        persister.put(queueName: queueId, taskId: job2Id, data: task2)

        let restore = persister.restore()
        XCTAssertEqual(restore.count, 1)
        XCTAssertEqual(restore[0], queueId)

        persister.put(queueName: queueId, taskId: job1Id, data: task1)

        let restore2 = persister.restore()
        XCTAssertEqual(restore2.count, 1)
        XCTAssertEqual(restore2[0], queueId)

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: persister).build()

        XCTAssertEqual(queueId, persister.restoreQueueName)

        job1.awaitForRemoval()
        job1.assertSingleCompletion()

        job2.awaitForRemoval()
        job2.assertSingleCompletion()

        manager.waitUntilAllOperationsAreFinished()
    }

    func testCancelAllShouldRemoveFromPersister() {
        let (type1, job1, job1Id) = (UUID().uuidString, TestJob(), UUID().uuidString)
        let (type2, job2, job2Id) = (UUID().uuidString, TestJob(), UUID().uuidString)

        let group = UUID().uuidString

        let creator = TestCreator([type1: job1, type2: job2])

        let persister = PersisterTracker(key: UUID().uuidString)

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: persister).build()

        JobBuilder(type: type1)
                .singleInstance(forId: job1Id)
                .parallel(queueName: group)
                .delay(time: 3600)
                .persist()
                .schedule(manager: manager)

        JobBuilder(type: type2)
                .singleInstance(forId: job2Id)
                .parallel(queueName: group)
                .delay(time: 3600)
                .persist()
                .schedule(manager: manager)

        manager.cancelAllOperations()

        job1.awaitForRemoval()
        job2.awaitForRemoval()

        job1.assertRemovedBeforeRun(reason: .canceled)
        job2.assertRemovedBeforeRun(reason: .canceled)

        XCTAssertEqual([job1Id, job2Id], persister.removeJobUUID)
        XCTAssertEqual([group, group], persister.removeQueueName)
    }

    func testCompleteJobRemoveFromSerializer() {
        let (type, job) = (UUID().uuidString, TestJob())

        let queueId = UUID().uuidString
        let taskID = UUID().uuidString

        let creator = TestCreator([type: job])
        let persister = PersisterTracker(key: UUID().uuidString)

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: persister).build()
        JobBuilder(type: type)
                .singleInstance(forId: taskID)
                .parallel(queueName: queueId)
                .persist()
                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertSingleCompletion()

        XCTAssertEqual([taskID], persister.removeJobUUID)
        XCTAssertEqual([queueId], persister.removeQueueName)
    }

    func testCompleteFailTaskRemoveFromSerializer() {
        let queueId = UUID().uuidString

        let job = TestJobFail()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let taskID = UUID().uuidString

        let persister = PersisterTracker(key: UUID().uuidString)

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: persister).build()
        JobBuilder(type: type)
                .singleInstance(forId: taskID)
                .parallel(queueName: queueId)
                .persist()
                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertRunCount(expected: 1)
        job.assertCompletedCount(expected: 0)
        job.assertRetriedCount(expected: 0)
        job.assertCanceledCount(expected: 1)
        job.assertError()

        XCTAssertEqual([taskID], persister.removeJobUUID)
        XCTAssertEqual([queueId], persister.removeQueueName)
    }

    func testNonPersistedJobShouldNotBePersisted() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])
        let persister = PersisterTracker(key: UUID().uuidString)

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: persister).build()
        JobBuilder(type: type)
                .schedule(manager: manager)

        job.awaitForRemoval()

        job.assertSingleCompletion()

        XCTAssertEqual(0, persister.putQueueName.count)
        XCTAssertEqual(0, persister.putJobUUID.count)
        XCTAssertEqual(0, persister.putData.count)
        XCTAssertEqual(0, persister.removeQueueName.count)
        XCTAssertEqual(0, persister.removeJobUUID.count)
    }

    func testCancelWithTagShouldRemoveFromPersister() {
        let (type, job) = (UUID().uuidString, TestJob())

        let id = UUID().uuidString
        let tag = UUID().uuidString
        let group = UUID().uuidString

        let creator = TestCreator([type: job])

        let persister = PersisterTracker(key: UUID().uuidString)

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: persister).build()

        JobBuilder(type: type)
                .singleInstance(forId: id)
                .parallel(queueName: group)
                .delay(time: 3600)
                .addTag(tag: tag)
                .persist()
                .schedule(manager: manager)

        manager.cancelOperations(tag: tag)

        job.awaitForRemoval()
        job.assertRemovedBeforeRun(reason: .canceled)

        XCTAssertEqual([id], persister.removeJobUUID)
        XCTAssertEqual([group], persister.removeQueueName)
    }

    func testCustomSerializer() {
        let (type1, job1) = (UUID().uuidString, TestJob())

        let persister = PersisterTracker(key: UUID().uuidString)
        let serializer = MemorySerializer()

        let manager = SwiftQueueManagerBuilder(creator: TestCreator([type1: job1]))
                .set(persister: persister)
                .set(serializer: serializer)
                .set(isSuspended: true)
                .build()

        JobBuilder(type: type1)
                .parallel(queueName: UUID().uuidString)
                .persist()
                .schedule(manager: manager)

        // at this point the job should have been serialised
        job1.assertNoRun()

        // Re-create manager
        let manager2 = SwiftQueueManagerBuilder(creator: TestCreator([type1: job1]))
                .set(persister: persister)
                .set(serializer: serializer)
                .set(isSuspended: false)
                .build()

        manager2.waitUntilAllOperationsAreFinished()

        job1.awaitForRemoval()
        job1.assertSingleCompletion()
    }

    func testRemoveAllJob() {
        let persister = PersisterTracker(key: UUID().uuidString)

        // Nothing to assert since we don't rely on the actual one in test cases
        persister.clearAll()
    }

}
