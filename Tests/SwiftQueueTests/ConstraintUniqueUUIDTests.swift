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

        let job3 = TestJob()
        let type3 = UUID().uuidString

        let creator = TestCreator([type1: job1, type2: job2, type3: job3])

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type1)
                .singleInstance(forId: id)
                .delay(inSecond: 3600)
                .schedule(manager: manager)

        JobBuilder(type: type2)
                .singleInstance(forId: id)
                .delay(inSecond: 3600)
                .schedule(manager: manager)

        JobBuilder(type: type3).singleInstance(forId: id).schedule(manager: manager)

        job3.await()

        XCTAssertEqual(job3.onRunJobCalled, 0)
        XCTAssertEqual(job3.onCompleteCalled, 0)
        XCTAssertEqual(job3.onRetryCalled, 0)
        XCTAssertEqual(job3.onCancelCalled, 1)

        manager.cancelAllOperations()
        manager.waitUntilAllOperationsAreFinished()
    }

}
