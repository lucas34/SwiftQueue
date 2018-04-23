//
// Created by Lucas Nelaupe on 13/12/17.
//

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
