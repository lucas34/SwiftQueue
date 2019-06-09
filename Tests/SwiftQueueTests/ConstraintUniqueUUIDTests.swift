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

import Foundation
import XCTest
@testable import SwiftQueue

class ConstraintUniqueUUIDTests: XCTestCase {

    func testUniqueIdConstraintShouldCancelTheSecond() {
        let (type1, job1) = (UUID().uuidString, TestJob())
        let (type2, job2) = (UUID().uuidString, TestJob())

        let id = UUID().uuidString

        let creator = TestCreator([type1: job1, type2: job2])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoSerializer.shared).build()
        JobBuilder(type: type1)
                .singleInstance(forId: id)
                .delay(time: 3600)
                .schedule(manager: manager)

        JobBuilder(type: type2).singleInstance(forId: id).schedule(manager: manager)

        job2.awaitForRemoval()
        job2.assertRemovedBeforeRun(reason: .duplicate)

        manager.cancelAllOperations()
        manager.waitUntilAllOperationsAreFinished()
    }

    func testUniqueIdConstraintShouldCancelTheFirst() {
        let (type1, job1) = (UUID().uuidString, TestJob())
        let (type2, job2) = (UUID().uuidString, TestJob())

        let id = UUID().uuidString

        let creator = TestCreator([type1: job1, type2: job2])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoSerializer.shared).build()
        JobBuilder(type: type1)
                .singleInstance(forId: id)
                .delay(time: 3600)
                .schedule(manager: manager)

        JobBuilder(type: type2)
                .singleInstance(forId: id, override: true)
                .schedule(manager: manager)

        job1.awaitForRemoval()
        job1.assertRemovedBeforeRun(reason: .canceled)

        job2.awaitForRemoval()
        job2.assertSingleCompletion()

        manager.cancelAllOperations()
        manager.waitUntilAllOperationsAreFinished()
    }

}
