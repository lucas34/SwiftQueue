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

class BasicConstraintTest: XCTestCase {

    func testContraintThrowExceptionShouldCancelOperation() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])
        let constraint = BasicConstraint(onWillSchedule: {
            throw JobError()
        })

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoPersister.shared).build()
        JobBuilder(type: type)
                .add(constraint: constraint)
                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertError()

        XCTAssertTrue(constraint.willScheduleCalled)
        XCTAssertFalse(constraint.willRunCalled)
        XCTAssertFalse(constraint.runCalled)
    }

    func testJobShouldBeCancelIfThrowExceptionInConstraintOnWillRun() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])
        let constraint = BasicConstraint(onWillRun: {
            throw JobError()
        })

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoPersister.shared).build()
        JobBuilder(type: type)
                .add(constraint: constraint)
                .schedule(manager: manager)

        job.assertNoRun()

        job.awaitForRemoval()
        job.assertError()

        XCTAssertTrue(constraint.willScheduleCalled)
        XCTAssertTrue(constraint.willRunCalled)
        XCTAssertFalse(constraint.runCalled)
    }

    func testOperationRunWhenConstraintTrigger() {
        let (type, job) = (UUID().uuidString, TestJob())
        var operation: SqOperation?

        let creator = TestCreator([type: job])
        let constraint = BasicConstraint(onRun: { ope in
            print("Operation")
            if operation != nil {
                return true
            }
            operation = ope
            return true
        })

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoPersister.shared).build()
        JobBuilder(type: type)
                .add(constraint: constraint)
                .schedule(manager: manager)

        job.assertNoRun()

        operation?.run()

        job.awaitForRemoval()
        job.assertSingleCompletion()

        XCTAssertTrue(constraint.willScheduleCalled)
        XCTAssertTrue(constraint.willRunCalled)
        XCTAssertTrue(constraint.runCalled)
    }

}

class BasicConstraint: CustomConstraint {

    let onWillSchedule: () throws-> Void
    let onWillRun: () throws -> Void
    let onRun: (SqOperation) -> Bool

    required init(onWillSchedule: @escaping () throws -> Void = {}, onWillRun: @escaping () throws -> Void = {}, onRun: @escaping (SqOperation) -> Bool = { _ in true}) {
        self.onWillSchedule = onWillSchedule
        self.onWillRun = onWillRun
        self.onRun = onRun
    }

    override func willSchedule(queue: SqOperationQueue, operation: SqOperation) throws {
        try super.willSchedule(queue: queue, operation: operation)
        try onWillSchedule()
    }

    override func willRun(operation: SqOperation) throws {
        try super.willRun(operation: operation)
        try onWillRun()
    }

    override func run(operation: SqOperation) -> Bool {
        super.run(operation: operation) && onRun(operation)
    }

}
