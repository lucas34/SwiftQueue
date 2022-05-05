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

import XCTest
import Dispatch
@testable import SwiftQueue

class SwiftQueueManagerTests: XCTestCase {

    func testRunSuccessJob() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoPersister.shared).build()
        JobBuilder(type: type)
                .priority(priority: .veryHigh)
                .service(quality: .background)
                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertSingleCompletion()
    }

    func testRunSuccessJobLambda() {
        var onRunCount = 0
        let onRemoveSemaphore = DispatchSemaphore(value: 0)

        let (type, job) = (UUID().uuidString, LambdaJob {
            onRunCount += 1
            onRemoveSemaphore.signal()
        })

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoPersister.shared).set(isSuspended: true).build()
        JobBuilder(type: type)
                .priority(priority: .veryHigh)
                .service(quality: .background)
                .schedule(manager: manager)

        XCTAssertEqual(0, onRunCount)

        manager.isSuspended = false

        onRemoveSemaphore.wait()
        XCTAssertEqual(1, onRunCount)
    }

    func testJobListener() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])
        let listener = JobListenerTest()

        let manager = SwiftQueueManagerBuilder(creator: creator)
                .set(persister: NoPersister.shared)
                .set(isSuspended: true)
                .set(listener: listener)
                .build()

        JobBuilder(type: type).schedule(manager: manager)

        // No run
        job.assertNoRun()
        XCTAssertEqual(1, listener.onJobScheduled.count)
        XCTAssertEqual(0, listener.onBeforeRun.count)
        XCTAssertEqual(0, listener.onAfterRun.count)
        XCTAssertEqual(0, listener.onTerminated.count)

        manager.isSuspended = false

        job.awaitForRemoval()
        job.assertSingleCompletion()

        XCTAssertEqual(1, listener.onJobScheduled.count)
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

    func testCancelAllRepeatJob() {
        let (type, job) = (UUID().uuidString, TestJob())

        let id = UUID().uuidString
        let tag = UUID().uuidString
        let group = UUID().uuidString

        let creator = TestCreator([type: job])

        let persister = PersisterTracker(key: UUID().uuidString)

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: persister).build()

        JobBuilder(type: type)
                .singleInstance(forId: UUID().uuidString)
                .periodic(limit: .unlimited, interval: Double.leastNonzeroMagnitude)
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
                persister: NoPersister.shared,
                serializer: DecodableSerializer(maker: DefaultConstraintMaker()),
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

        let operation = manager.getOperation(forUUID: id)?.info.constraints ?? []

        let constraint: UniqueUUIDConstraint? = getConstraint(operation)
        XCTAssertTrue(constraint?.uuid == id)
    }

    public func testGetAll() {
        let creator = TestCreator([:])
        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoPersister.shared).build()

        XCTAssertEqual(0, manager.getAll().count)
    }

    func testCancelRunningOperation() {
        var manager: SwiftQueueManager?

        let (type, job) = (UUID().uuidString, TestJob {
            manager?.cancelAllOperations()
            $0.done(.fail(JobError()))
        })

        let creator = TestCreator([type: job])

        manager = SwiftQueueManagerBuilder(creator: creator)
                .set(persister: NoPersister.shared)
                .set(dispatchQueue: DispatchQueue.main)
                .build()

        manager?.enqueue(info: JobBuilder(type: type).build())

        job.awaitForRemoval()
        job.assertRunCount(expected: 1)
        job.assertCompletedCount(expected: 0)
        job.assertRetriedCount(expected: 0)
        job.assertCanceledCount(expected: 1)
        job.assertError(queueError: .canceled)
    }

    func testConcurrentScheduling() {
        let (type, job) = (UUID().uuidString, TestJob())
        let creator = TestCreator([type: job])
        let persister = PersisterTracker(key: UUID().uuidString)
        let manager = SwiftQueueManagerBuilder(creator: creator)
                .set(isSuspended: true)
                .set(enqueueDispatcher: .main)
                .set(persister: persister).build()


        let concurrentQueue = DispatchQueue(label: "com.test.concurrent", attributes: .concurrent)
        for _ in 0..<10 {
            concurrentQueue.async {
                JobBuilder(type: type).parallel(queueName: UUID().uuidString).schedule(manager: manager)
            }
        }

        for _ in 0..<10 {
            DispatchQueue(label: "com.test.concurrent", attributes: .concurrent).async {
                JobBuilder(type: type).parallel(queueName: UUID().uuidString).schedule(manager: manager)
            }
        }

    }

}
