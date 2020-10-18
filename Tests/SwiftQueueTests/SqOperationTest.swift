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
