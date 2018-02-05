//
// Created by Lucas Nelaupe on 13/12/17.
//

import Foundation

import Foundation
import XCTest
@testable import SwiftQueue

class ConstraintNetworkTests: XCTestCase {

    func testNetworkConstraint() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .internet(atLeast: .cellular)
                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertSingleCompletion()
    }

    func testNetworkConstraintWifi() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .internet(atLeast: .wifi)
                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertSingleCompletion()
    }

}
