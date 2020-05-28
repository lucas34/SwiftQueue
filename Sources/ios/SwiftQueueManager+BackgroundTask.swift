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

#if canImport(BackgroundTasks)
import BackgroundTasks
#endif

@available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
/// Extension of SwiftQueueManager to support BackgroundTask API from iOS 13.
public extension SwiftQueueManager {

    /// Register task that can potentially run in Background (Using BackgroundTask API)
    /// Registration of all launch handlers must be complete before the end of applicationDidFinishLaunching(_:)
    /// https://developer.apple.com/documentation/backgroundtasks/bgtaskscheduler/3180427-register
    func registerForBackgroundTask(forTaskWithUUID: String) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: forTaskWithUUID, using: nil) { [weak self] task in
            if let operation = self?.getOperation(forUUID: task.identifier) {
                task.expirationHandler = {
                    operation.done(.fail(SwiftQueueError.timeout))
                }
                operation.handler.onRun(callback: TaskJobResult(actual: operation, task: task))
            }
        }
    }

    /// Call this method when application is entering background to schedule jobs as background task
    func applicationDidEnterBackground() {
        for operation in getAllAllowBackgroundOperation() {
            operation.scheduleBackgroundTask()
        }
    }

    /// Cancel all possible background Task
    func cancelAllBackgroundTask() {
        for operation in getAllAllowBackgroundOperation() {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: operation.info.uuid)
        }
    }
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
internal extension SqOperation {

    func scheduleBackgroundTask() {
        let request = BGProcessingTaskRequest(identifier: info.uuid)

        request.requiresNetworkConnectivity = info.requireNetwork.rawValue > NetworkType.any.rawValue
        request.requiresExternalPower = info.requireCharging
        request.earliestBeginDate = nextRunSchedule

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            logger.log(.verbose, jobId: name, message: "Could not schedule BackgroundTask")
        }
    }
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
private class TaskJobResult: JobResult {

    private let task: BGTask
    private let actual: JobResult

    init(actual: JobResult, task: BGTask) {
        self.actual = actual
        self.task = task
    }

    public func done(_ result: JobCompletion) {
        actual.done(result)

        switch result {
        case .success:
            task.setTaskCompleted(success: true)
        case .fail:
            task.setTaskCompleted(success: false)
        }
    }
}
