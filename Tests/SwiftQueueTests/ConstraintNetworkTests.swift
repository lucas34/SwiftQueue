//
// Created by Lucas Nelaupe on 13/12/17.
//

import Foundation

import Foundation
import XCTest
@testable import SwiftQueue

class ConstraintNetworkTests: XCTestCase {

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

}
