//
// Created by Lucas Nelaupe on 11/8/17.
// Copyright (c) 2017 Lucas Nelaupe. All rights reserved.
//

import UIKit
import XCTest
import Dispatch
@testable import SwiftQueue

class MyJob: Job {
    public static let type = "MyJob"

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

class MyPersister: JobPersister {
    var onRestore: String?
    var onPut: JobTask?
    var onRemoveUUID: String?

    var needRestore: String?
    var taskToRestore: String?

    convenience init(needRestore: String, task: String) {
        self.init()
        self.needRestore = needRestore
        self.taskToRestore = task
    }

    func restore(queueName: String) -> [String] {
        onRestore = queueName
        if let needRestore = needRestore, let taskToRestore = taskToRestore, needRestore == queueName {
            return [taskToRestore]
        }
        return []
    }

    func put(taskId: String, data: String) {
        onPut = JobTask(json: data, creator: [AlwaysTrueCreator()])
    }

    func remove(taskId: String) {
        onRemoveUUID = taskId
    }
}

class JobError: Error {

}
