//
// Created by Lucas Nelaupe on 11/8/17.
// Copyright (c) 2017 Lucas Nelaupe. All rights reserved.
//

import UIKit
import XCTest
import Dispatch
@testable import SwiftQueue

class MyJob: Job {
    public let semaphore = DispatchSemaphore(value: 0)

    public var result: Error?

    public var onRunJobCalled = 0
    public var onErrorCalled = 0
    public var onCompleteCalled = 0
    public var onCancelCalled = 0

    public var retryConstraint = RetryConstraint.retry

    public var params: Any?

    func onRunJob(callback: JobResult) throws {
        onRunJobCalled += 1
        callback.onDone(error: result) // Auto complete
    }

    func onError(error: Error) -> RetryConstraint {
        onErrorCalled += 1
        return retryConstraint
    }

    func onComplete() {
        onCompleteCalled += 1
        semaphore.signal()
    }

    func onCancel() {
        onCancelCalled += 1
        semaphore.signal()
    }

    func await() {
        semaphore.wait()
    }
}

class MyCreator: JobCreator {
    private let job: [String: Job]

    public init(_ job: [String: Job]) {
        self.job = job
    }

    func create(jobType: String, params: Any?) -> Job? {
        if let value = job[jobType] as? MyJob {
            value.params = params
            return value
        } else {
            return job[jobType]
        }
    }
}

class AlwaysTrueCreator: JobCreator {

    func create(jobType: String, params: Any?) -> Job? {
        return MyJob()
    }

}

class PersisterTracker: UserDefaultsPersister {
    var restoreQueueName = ""

    var putQueueName = ""
    var putTaskId = ""
    var putData = ""

    var removeQueueName = ""
    var removeTaskId = ""

    override func restore(queueName: String) -> [String] {
        restoreQueueName = queueName
        return super.restore(queueName: queueName)
    }

    override func put(queueName: String, taskId: String, data: String) {
        putQueueName = queueName
        putTaskId = taskId
        putData = data
        super.put(queueName: queueName, taskId: taskId, data: data)
    }

    override func remove(queueName: String, taskId: String) {
        removeQueueName = queueName
        removeTaskId = taskId
        super.remove(queueName: queueName, taskId: taskId)
    }
}

class JobError: Error {

}
