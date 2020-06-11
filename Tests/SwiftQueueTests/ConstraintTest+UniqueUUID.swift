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

class ConstraintTestUniqueUUID: XCTestCase {

    func testUniqueIdConstraintShouldCancelTheSecond() {
        let (type1, job1) = (UUID().uuidString, TestJob())
        let (type2, job2) = (UUID().uuidString, TestJob())

        let id = UUID().uuidString

        let creator = TestCreator([type1: job1, type2: job2])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoPersister.shared).build()
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

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoPersister.shared).build()
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
