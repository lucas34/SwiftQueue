//
// Created by Lucas Nelaupe on 13/12/17.
//

import Foundation
import XCTest
@testable import SwiftQueue

class ConstraintUniqueUUIDTests: XCTestCase {

    func testUniqueIdConstraintShouldCancelTheSecond() {
        let id = UUID().uuidString

        let job1 = TestJob()
        let type1 = UUID().uuidString

        let job2 = TestJob()
        let type2 = UUID().uuidString

        let creator = TestCreator([type1: job1, type2: job2])

        let manager = SwiftQueueManager(creators: [creator])
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
        let id = UUID().uuidString

        let job1 = TestJob()
        let type1 = UUID().uuidString

        let job2 = TestJob()
        let type2 = UUID().uuidString

        let creator = TestCreator([type1: job1, type2: job2])

        let manager = SwiftQueueManager(creators: [creator])
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
