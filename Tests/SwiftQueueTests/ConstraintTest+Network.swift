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

class ConstraintTestNetwork: XCTestCase {

    func testNetworkConstraint() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoSerializer.shared).build()
        JobBuilder(type: type)
                .internet(atLeast: .cellular)
                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertSingleCompletion()
    }

    func testNetworkConstraintWifi() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoSerializer.shared).build()
        JobBuilder(type: type)
                .internet(atLeast: .wifi)
                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertSingleCompletion()
    }

    func testNetworkWhenDeserialize() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])

        let group = UUID().uuidString

        let json = JobBuilder(type: type)
                .parallel(queueName: group)
                .internet(atLeast: .wifi)
                .build(job: job)
                .toJSONStringSafe()

        let persister = PersisterTracker(key: UUID().uuidString)
        persister.put(queueName: group, taskId: UUID().uuidString, data: json)

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: persister).build()

        job.awaitForRemoval()

        XCTAssertEqual(group, persister.restoreQueueName)

        manager.waitUntilAllOperationsAreFinished()
    }





}
