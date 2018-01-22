//
// Created by Lucas Nelaupe on 11/8/17.
// Copyright (c) 2017 Lucas Nelaupe. All rights reserved.
//

import XCTest
import Dispatch
@testable import SwiftQueue

class TestJob: Job {
    public let semaphore = DispatchSemaphore(value: 0)

    public var result: Error?

    public var lastError: Error?

    public var onRunJobCalled = 0
    public var onRetryCalled = 0
    public var onCompleteCalled = 0
    public var onCancelCalled = 0

    public var retryConstraint = RetryConstraint.retry(delay: 0)

    public var params: [String: Any]?

    public let completionTimeout: TimeInterval

    var runSemaphoreValue = 0
    let runSemaphore = DispatchSemaphore(value: 0)
    
    init(_ completionTimeout: TimeInterval = 0) {
        self.completionTimeout = completionTimeout
    }

    func onRun(callback: JobResult) {
        onRunJobCalled += 1
        if runSemaphoreValue == onRunJobCalled {
            runSemaphore.signal()   
        }
        runInBackgroundAfter(completionTimeout) {
            if let error = self.result {
                callback.done(.fail(error))
            } else {
                callback.done(.success)
            }
        }
    }

    func onRetry(error: Error) -> RetryConstraint {
        lastError = error
        onRetryCalled += 1
        return retryConstraint
    }

    func onRemove(result: JobCompletion) {
        switch result {
        case .success:
            onCompleteCalled += 1
            semaphore.signal()

        case .fail(let error):
            lastError = error
            onCancelCalled += 1
            semaphore.signal()
        }
    }

    func await(_ seconds: TimeInterval = TimeInterval(5)) {
        let delta = DispatchTime.now() + Double(Int64(seconds) * Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
        _ = semaphore.wait(timeout: delta)
    }

    func awaitRun(value: Int, _ seconds: TimeInterval = TimeInterval(5)) {
        let delta = DispatchTime.now() + Double(Int64(seconds) * Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
        runSemaphoreValue = value
        _ = runSemaphore.wait(timeout: delta)
    }
}

class TestCreator: JobCreator {
    private let job: [String: Job]

    public init(_ job: [String: Job]) {
        self.job = job
    }

    func create(type: String, params: [String: Any]?) -> Job? {
        let value = job[type] as? TestJob
        value?.params = params
        return value
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

class JobError: Error {

}
