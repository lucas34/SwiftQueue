//
// Created by Lucas Nelaupe on 18/4/18.
//

import Foundation
import XCTest
import Dispatch
@testable import SwiftQueue

class LoggerTests: XCTestCase {

    func testRunSuccessJobLogger() {
        let id = UUID().uuidString

        let debugLogger = DebugLogger()

        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoSerializer.shared).set(logger: debugLogger).build()
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

    func testLoggerLevel() {

        let verbose = DebugLogger(min: .verbose)
        let warning = DebugLogger(min: .warning)
        let error = DebugLogger(min: .error)

        let verbose1 = UUID().uuidString
        let verbose2 = UUID().uuidString

        verbose.log(.verbose, jobId: verbose1, message: verbose2)
        warning.log(.verbose, jobId: verbose1, message: verbose2)
        error.log(.verbose, jobId: verbose1, message: verbose2)

        let warning1 = UUID().uuidString
        let warning2 = UUID().uuidString

        verbose.log(.warning, jobId: warning1, message: warning2)
        warning.log(.warning, jobId: warning1, message: warning2)
        error.log(.warning, jobId: warning1, message: warning2)

        let error1 = UUID().uuidString
        let error2 = UUID().uuidString

        verbose.log(.error, jobId: error1, message: error2)
        warning.log(.error, jobId: error1, message: error2)
        error.log(.error, jobId: error1, message: error2)

        XCTAssertEqual(3, verbose.outputs.count)
        XCTAssertEqual(2, warning.outputs.count)
        XCTAssertEqual(1, error.outputs.count)

        XCTAssertEqual(verbose.outputs[0], "[SwiftQueue] level=\(LogLevel.verbose.description) jobId=\(verbose1) message=\(verbose2)")
        XCTAssertEqual(verbose.outputs[1], "[SwiftQueue] level=\(LogLevel.warning.description) jobId=\(warning1) message=\(warning2)")
        XCTAssertEqual(verbose.outputs[2], "[SwiftQueue] level=\(LogLevel.error.description) jobId=\(error1) message=\(error2)")

        XCTAssertEqual(warning.outputs[0], "[SwiftQueue] level=\(LogLevel.warning.description) jobId=\(warning1) message=\(warning2)")
        XCTAssertEqual(warning.outputs[1], "[SwiftQueue] level=\(LogLevel.error.description) jobId=\(error1) message=\(error2)")

        XCTAssertEqual(error.outputs[0], "[SwiftQueue] level=\(LogLevel.error.description) jobId=\(error1) message=\(error2)")
    }

}

class DebugLogger: ConsoleLogger {

    var outputs = [String]()

    override func printComputed(output: String) {
        outputs.append(output)
    }

}
