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
            lastError = nil
            onCompletedCount += 1
            onRemoveSemaphore.signal()

        case .fail(let error):
            lastError = error
            onCanceledCount += 1
            onRemoveSemaphore.signal()
        }
    }

    // Wait

    func awaitForRemoval() {
        onRemoveSemaphore.wait()
    }

    // Assertion

    public func assertRunCount(expected: Int, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(expected, onRunCount)
    }
    public func assertCompletedCount(expected: Int, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(expected, onCompletedCount)
    }
    public func assertRetriedCount(expected: Int, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(expected, onRetryCount)
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
        case (.timeout, .timeout): return

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

    func clearAll() {}

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
