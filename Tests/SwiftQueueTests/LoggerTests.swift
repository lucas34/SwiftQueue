//
// Created by Lucas Nelaupe on 18/4/18.
//

import XCTest
import Dispatch
@testable import SwiftQueue

class LoggerTests: XCTestCase {

    func testRunSuccessJobLogger() {
        let id = UUID().uuidString

        let debugLogger = DebugLogger()

        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManager(creator: creator, logger: debugLogger)
        JobBuilder(type: type)
                .singleInstance(forId: id)
                .internet(atLeast: .wifi)
                .schedule(manager: manager)

        job.awaitForRemoval()
        job.assertSingleCompletion()

        let outputs = debugLogger.outputs

        XCTAssertEqual(5, outputs.count)
        XCTAssertEqual(outputs[0], "[SwiftQueue] level=verbose jobId=\(id) message=Job has been started by the system")
        XCTAssertEqual(outputs[1], "[SwiftQueue] level=verbose jobId=\(id) message=Job is running")
        XCTAssertEqual(outputs[2], "[SwiftQueue] level=verbose jobId=\(id) message=Job completed successfully")
        XCTAssertEqual(outputs[3], "[SwiftQueue] level=verbose jobId=\(id) message=Job will not run anymore")
        XCTAssertEqual(outputs[4], "[SwiftQueue] level=verbose jobId=\(id) message=Job is removed from the queue result=success")
    }

}

class DebugLogger: ConsoleLogger {

    var outputs = [String]()

    override func printComputed(output: String) {
        outputs.append(output)
    }

}
