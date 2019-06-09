// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import Foundation
import XCTest
import Dispatch
@testable import SwiftQueue

class TestJob: Job {

    private let onRunCallback: (JobResult) -> Void
    private var withRetry: RetryConstraint

    private var onRunCount = 0
    private var onRetryCount = 0
    private var onCompletedCount = 0
    private var onCanceledCount = 0

    private let onRunSemaphore = DispatchSemaphore(value: 0)
    private let onRemoveSemaphore = DispatchSemaphore(value: 0)

    private var runSemaphoreValue = 0

    private var lastError: Error?

    init(retry: RetryConstraint = .retry(delay: 0), onRunCallback: @escaping (JobResult) -> Void = { $0.done(.success) }) {
        self.onRunCallback = onRunCallback
        self.withRetry = retry
    }

    func onRun(callback: JobResult) {
        XCTAssertFalse(Thread.isMainThread)

        onRunCount += 1
        if runSemaphoreValue == onRunCount {
            onRunSemaphore.signal()
        }

        onRunCallback(callback)
    }

    func onRetry(error: Error) -> RetryConstraint {
        XCTAssertFalse(Thread.isMainThread)

        lastError = error
        onRetryCount += 1
        return withRetry
    }

    func onRemove(result: JobCompletion) {
        switch result {
        case .success:
            onCompletedCount += 1
            onRemoveSemaphore.signal()

        case .fail(let error):
            lastError = error
            onCanceledCount += 1
            onRemoveSemaphore.signal()
        }
    }

    // Wait

    func awaitForRemoval(_ seconds: TimeInterval = TimeInterval(5)) {
        let delta = DispatchTime.now() + Double(Int64(seconds) * Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
        _ = onRemoveSemaphore.wait(timeout: delta)
    }

    func awaitForRun(value: Int, _ seconds: TimeInterval = TimeInterval(5)) {
        let delta = DispatchTime.now() + Double(Int64(seconds) * Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
        runSemaphoreValue = value
        _ = onRunSemaphore.wait(timeout: delta)
    }

    // Assertion

    public func assertRunCount(expected: Int, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(expected, onRunCount)
    }
    public func assertRunCount(atLeast: Int, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(onRunCount > atLeast, "\(onRunCount) is smaller than \(atLeast)")
    }
    public func assertCompletedCount(expected: Int, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(expected, onCompletedCount)
    }
    public func assertRetriedCount(expected: Int, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(expected, onRetryCount)
    }
    public func assertRetriedCount(atLeast: Int, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(onRetryCount > atLeast)
    }
    public func assertCanceledCount(expected: Int, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(expected, onCanceledCount)
    }
    public func assertError(file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(lastError is JobError)
    }
    public func assertError(queueError: SwiftQueueError, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(lastError is SwiftQueueError)
        guard let base: SwiftQueueError = lastError as? SwiftQueueError else { return }
        switch (base, queueError) {

        case let (.onRetryCancel(lErr), .onRetryCancel(rErr)):
            XCTAssertEqual(lErr as? JobError, rErr as? JobError)

        case (.duplicate, .duplicate): return
        case (.deadline, .deadline): return
        case (.canceled, .canceled): return

        default: XCTFail("Type mismatch")
        }
    }

    public func assertNoError(file: StaticString = #file, line: UInt = #line) {
        XCTAssertNil(lastError)
    }
    public func assertNoRun(file: StaticString = #file, line: UInt = #line) {
        self.assertRunCount(expected: 0)
        self.assertCompletedCount(expected: 0)
        self.assertRetriedCount(expected: 0)
        self.assertCanceledCount(expected: 0)
        self.assertNoError(file: file, line: line)
    }
    // Job has run once without error and completed
    public func assertSingleCompletion(file: StaticString = #file, line: UInt = #line) {
        self.assertRunCount(expected: 1)
        self.assertCompletedCount(expected: 1)
        self.assertRetriedCount(expected: 0)
        self.assertCanceledCount(expected: 0)
        self.assertNoError(file: file, line: line)
    }

    public func assertRemovedBeforeRun(reason: SwiftQueueError, file: StaticString = #file, line: UInt = #line) {
        self.assertRunCount(expected: 0)
        self.assertCompletedCount(expected: 0)
        self.assertRetriedCount(expected: 0)
        self.assertCanceledCount(expected: 1)
        self.assertError(queueError: reason)
    }

}

class TestJobFail: TestJob {

    required init(retry: RetryConstraint = .retry(delay: 0), error: Swift.Error = JobError()) {
        super.init(retry: retry) { $0.done(.fail(error))}
    }

}

class TestCreator: JobCreator {
    private let job: [String: TestJob]

    public init(_ job: [String: TestJob]) {
        self.job = job
    }

    func create(type: String, params: [String: Any]?) -> Job {
        return job[type]!
    }
}

class PersisterTracker: UserDefaultsPersister {
    var restoreQueueName = ""

    var putQueueName: [String] = [String]()
    var putJobUUID: [String] = [String]()
    var putData: [String] = [String]()

    var removeQueueName: [String] = [String]()
    var removeJobUUID: [String] = [String]()

    override func restore(queueName: String) -> [String] {
        restoreQueueName = queueName
        return super.restore(queueName: queueName)
    }

    override func put(queueName: String, taskId: String, data: String) {
        putQueueName.append(queueName)
        putJobUUID.append(taskId)
        putData.append(data)
        super.put(queueName: queueName, taskId: taskId, data: data)
    }

    override func remove(queueName: String, taskId: String) {
        removeQueueName.append(queueName)
        removeJobUUID.append(taskId)
        super.remove(queueName: queueName, taskId: taskId)
    }
}

class JobListenerTest: JobListener {

    var onBeforeRun: [JobInfo] = [JobInfo]()
    var onAfterRun: [(JobInfo, JobCompletion)] = [(JobInfo, JobCompletion)]()
    var onTerminated: [(JobInfo, JobCompletion)] = [(JobInfo, JobCompletion)]()

    func onBeforeRun(job: JobInfo) {
        onBeforeRun.append(job)
    }

    func onAfterRun(job: JobInfo, result: JobCompletion) {
        onAfterRun.append((job, result))
    }

    func onTerminated(job: JobInfo, result: JobCompletion) {
        onTerminated.append((job, result))
    }
}

class JobError: Error {

    let id = UUID().uuidString

}

extension JobError: Equatable {

    public static func == (lhs: JobError, rhs: JobError) -> Bool {
        return lhs.id == rhs.id
    }
}

extension SqOperation {

    func toJSONStringSafe() -> String {
        return (try? DecodableSerializer().serialize(info: self.info)) ?? "{}"
    }

}

class NoSerializer: JobPersister {

    public static let shared = NoSerializer()

    private init() {}

    func restore() -> [String] { return [] }

    func restore(queueName: String) -> [String] { return [] }

    func put(queueName: String, taskId: String, data: String) {}

    func remove(queueName: String, taskId: String) {}
}

class MemorySerializer: JobInfoSerializer {

    private var data: [String: JobInfo] = [:]

    func serialize(info: JobInfo) throws -> String {
        data[info.uuid] = info
        return info.uuid
    }

    func deserialize(json: String) throws -> JobInfo {
        return data[json] ?? JobInfo(type: json)
    }
}

extension JobBuilder {

    internal func build(job: Job, logger: SwiftQueueLogger = NoLogger.shared, listener: JobListener? = nil) -> SqOperation {
        return SqOperation(job: job, info: build(), logger: logger, listener: listener, dispatchQueue: DispatchQueue.global(qos: DispatchQoS.QoSClass.utility))
    }

}

