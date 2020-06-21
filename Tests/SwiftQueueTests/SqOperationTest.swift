//
// Created by Lucas Nelaupe on 22/6/20.
//

import Foundation

import Foundation
import XCTest
@testable import SwiftQueue

class SqOperationTest: XCTestCase {

    func testQueuePriority() {
        let priorities = [
            Operation.QueuePriority.veryLow,
            Operation.QueuePriority.low,
            Operation.QueuePriority.normal,
            Operation.QueuePriority.high,
            Operation.QueuePriority.veryHigh
        ]

        for priority in priorities {
            var jobInfo = JobInfo.init(type: "")
            jobInfo.priority = priority
            let operation = SqOperation(TestJob(), jobInfo, NoLogger.shared, nil, .main, [])

            XCTAssertEqual(priority, operation.queuePriority)
        }
    }

    func testQualityOfService() {
        let services = [
            QualityOfService.userInteractive,
            QualityOfService.userInitiated,
            QualityOfService.utility,
            QualityOfService.background,
            QualityOfService.default
        ]

        for service in services {
            var jobInfo = JobInfo.init(type: "")
            jobInfo.qualityOfService = service
            let operation = SqOperation(TestJob(), jobInfo, NoLogger.shared, nil, .main, [])

            XCTAssertEqual(service, operation.qualityOfService)
        }
    }

}
