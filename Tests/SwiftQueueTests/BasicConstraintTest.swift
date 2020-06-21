//
// Created by Lucas Nelaupe on 22/6/20.
//

import Foundation

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
        super.run(operation: operation)
        return onRun(operation)
    }

}
