// The MIT License (MIT)
//
// Copyright (c) 2017 Lucas Nelaupe
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

import XCTest
import Dispatch
@testable import SwiftQueue

class SwiftQueueManagerTests: XCTestCase {

    func testRunSuccessJob() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoSerializer.shared).build()
        JobBuilder(type: type)
                .internet(atLeast: .wifi)
                .priority(priority: .veryHigh)
                .service(quality: .background)

                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertSingleCompletion()
    }

    func testJobListener() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])
        let listener = JobListenerTest()

        let manager = SwiftQueueManagerBuilder(creator: creator)
                .set(persister: NoSerializer.shared)
                .set(isSuspended: true)
                .set(listener: listener)
                .build()

        JobBuilder(type: type).schedule(manager: manager)

        // No run
        job.assertNoRun()
        XCTAssertEqual(0, listener.onBeforeRun.count)
        XCTAssertEqual(0, listener.onAfterRun.count)
        XCTAssertEqual(0, listener.onTerminated.count)

        manager.isSuspended = false

        job.awaitForRemoval()
        job.assertSingleCompletion()

        XCTAssertEqual(1, listener.onBeforeRun.count)
        XCTAssertEqual(1, listener.onAfterRun.count)
        XCTAssertEqual(1, listener.onTerminated.count)
    }

    func testCancelWithTag() {
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
                .schedule(manager: manager)

        manager.cancelOperations(tag: tag)

        job.awaitForRemoval()
        job.assertRemovedBeforeRun(reason: .canceled)

        XCTAssertEqual(0, persister.putQueueName.count)
        XCTAssertEqual(0, persister.putJobUUID.count)
        XCTAssertEqual(0, persister.putData.count)

        XCTAssertEqual(0, persister.removeJobUUID.count)
        XCTAssertEqual(0, persister.removeQueueName.count)
    }

    func testCancelWithUUID() {
        let (type, job) = (UUID().uuidString, TestJob())

        let id = UUID().uuidString
        let group = UUID().uuidString

        let creator = TestCreator([type: job])

        let persister = PersisterTracker(key: UUID().uuidString)

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: persister).build()

        JobBuilder(type: type)
                .singleInstance(forId: id)
                .parallel(queueName: group)
                .delay(time: 3600)
                .schedule(manager: manager)

        manager.cancelOperations(uuid: id)

        job.awaitForRemoval()
        job.assertRemovedBeforeRun(reason: .canceled)

        XCTAssertEqual(0, persister.putQueueName.count)
        XCTAssertEqual(0, persister.putJobUUID.count)
        XCTAssertEqual(0, persister.putData.count)

        XCTAssertEqual(0, persister.removeJobUUID.count)
        XCTAssertEqual(0, persister.removeQueueName.count)
    }

    func testCancelAll() {
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
                .schedule(manager: manager)

        manager.cancelAllOperations()

        job.awaitForRemoval()
        job.assertRemovedBeforeRun(reason: .canceled)

        XCTAssertEqual(0, persister.putQueueName.count)
        XCTAssertEqual(0, persister.putJobUUID.count)
        XCTAssertEqual(0, persister.putData.count)

        XCTAssertEqual(0, persister.removeJobUUID.count)
        XCTAssertEqual(0, persister.removeQueueName.count)
    }

    func testAddOperationNotJobTask() {
        let params = SqManagerParams(
                jobCreator: TestCreator([:]),
                queueCreator: BasicQueueCreator(),
                persister: UserDefaultsPersister(),
                serializer: DecodableSerializer(),
                logger: NoLogger.shared,
                listener: nil,
                initInBackground: false
        )
        let queue = SqOperationQueue(params, BasicQueue.synchronous, true)
        let operation = Operation()
        queue.addOperation(operation) // Should not crash
    }

    func testLimitEquatable() {
        XCTAssertEqual(Limit.unlimited, Limit.unlimited)
        XCTAssertEqual(Limit.limited(-1), Limit.limited(-1))
        XCTAssertEqual(Limit.limited(0), Limit.limited(0))
        XCTAssertEqual(Limit.limited(1), Limit.limited(1))
        XCTAssertNotEqual(Limit.limited(1), Limit.limited(2))

        XCTAssertNotEqual(Limit.unlimited, Limit.limited(1))
        XCTAssertNotEqual(Limit.unlimited, Limit.limited(0))
        XCTAssertNotEqual(Limit.unlimited, Limit.limited(-1))
    }

    public func testGetAllAllowBackgroundOperation() {
        let (type, job) = (UUID().uuidString, TestJob())

        let id = UUID().uuidString
        let id2 = UUID().uuidString

        let group = UUID().uuidString
        let group2 = UUID().uuidString

        let creator = TestCreator([type: job])

        let persister = PersisterTracker(key: UUID().uuidString)

        let manager = SwiftQueueManagerBuilder(creator: creator).set(isSuspended: true).set(persister: persister).build()

        JobBuilder(type: type).periodic(executor: .foreground).parallel(queueName: group).schedule(manager: manager)
        JobBuilder(type: type).periodic(executor: .foreground).parallel(queueName: group2).schedule(manager: manager)

        JobBuilder(type: type).singleInstance(forId: id).periodic(executor: .background).parallel(queueName: group).schedule(manager: manager)
        JobBuilder(type: type).singleInstance(forId: id2).periodic(executor: .any).parallel(queueName: group2).schedule(manager: manager)

        let result = manager.getAllAllowBackgroundOperation()

        XCTAssertEqual(2, result.count)
        XCTAssertTrue([id, id2].contains(result[0].info.uuid))
        XCTAssertTrue([id, id2].contains(result[1].info.uuid))
    }

    public func testGetOperation() {
        let (type, job) = (UUID().uuidString, TestJob())
        let id = UUID().uuidString
        let creator = TestCreator([type: job])
        let persister = PersisterTracker(key: UUID().uuidString)
        let manager = SwiftQueueManagerBuilder(creator: creator).set(isSuspended: true).set(persister: persister).build()

        for _ in 0..<100 {
            JobBuilder(type: type).parallel(queueName: UUID().uuidString).schedule(manager: manager)
        }

        JobBuilder(type: type).singleInstance(forId: id).parallel(queueName: UUID().uuidString).schedule(manager: manager)

        let operation = manager.getOperation(forUUID: id)

        XCTAssertNotNil(operation)
        XCTAssertEqual(id, operation?.info.uuid)
    }

    public func testBackgroundOperationShouldNotRun() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoSerializer.shared).build()
        JobBuilder(type: type)
                .periodic(executor: .background)
                .internet(atLeast: .wifi)
                .priority(priority: .veryHigh)
                .service(quality: .background)
                .schedule(manager: manager)

        job.assertNoRun()
    }

    func testJobCount() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoSerializer.shared).build()

        XCTAssertEqual(manager.queueCount(), 0)
        XCTAssertEqual(manager.jobCount(), 0)

        JobBuilder(type: type).delay(time: 10000).schedule(manager: manager)

        XCTAssertEqual(manager.queueCount(), 1)
        XCTAssertEqual(manager.jobCount(), 1)

        manager.cancelAllOperations()
        manager.waitUntilAllOperationsAreFinished()
    }


}
