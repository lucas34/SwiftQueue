// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

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
                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertSingleCompletion()
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
                .group(name: group)
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
                .group(name: group)
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
                .group(name: group)
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
        let queue = SqOperationQueue(id: UUID().uuidString)
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

    func testJobCount() {
        let (type, job) = (UUID().uuidString, TestJob())
        let creator = TestCreator([type: job])
        let manager = SwiftQueueManagerBuilder(creator: creator).build()

        XCTAssertEqual(0, manager.queueCount())
        XCTAssertEqual(0, manager.jobCount())

        for _ in 0..<10 {

            let queueName = UUID().uuidString

            for _ in 0..<10 {
                JobBuilder(type: type)
                        .group(name: queueName)
                        .delay(time: 3600)
                        .schedule(manager: manager)
            }
        }

        XCTAssertEqual(10, manager.queueCount())
        XCTAssertEqual(100, manager.jobCount())
    }

}

extension SqOperationQueue {

    convenience init(id: String) {
        self.init(id, TestCreator([:]), UserDefaultsPersister(), DecodableSerializer(), false, true, NoLogger.shared)

    }

}

extension JobBuilder {

    internal func build(job: Job) -> SqOperation {
        return self.build(job: job, logger: NoLogger.shared)
    }

}
