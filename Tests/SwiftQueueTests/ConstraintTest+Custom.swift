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

class CustomConstraintTest: XCTestCase {

    func testCustomConstraint() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])
        let constraint = CustomConstraint()

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoPersister.shared).build()
        JobBuilder(type: type)
                .add(constraint: constraint)
                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertSingleCompletion()

        XCTAssertTrue(constraint.willScheduleCalled)
        XCTAssertTrue(constraint.willRunCalled)
        XCTAssertTrue(constraint.runCalled)
    }

}

class CustomConstraint: JobConstraint {

    var willScheduleCalled = false
    var willRunCalled = false
    var runCalled = false

    func willSchedule(queue: SqOperationQueue, operation: SqOperation) throws {
        willScheduleCalled = true
    }

    func willRun(operation: SqOperation) throws {
        willRunCalled = true
    }

    func run(operation: SqOperation) -> Bool {
        runCalled = true
        return true
    }

}
