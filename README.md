## SwiftQ
[![swift](https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat)](https://swift.org")
[![travis](https://travis-ci.org/lucas34/SwiftQ.svg?branch=master)](https://travis-ci.org/lucas34/SwiftQ)
[![codecov](https://codecov.io/gh/lucas34/SwiftQ/branch/master/graph/badge.svg)](https://codecov.io/gh/lucas34/SwiftQ)
[![codebeat badge](https://codebeat.co/badges/4ac05b9d-fefa-4be3-a38f-f58a4b5698cd)](https://codebeat.co/projects/github-com-lucas34-swiftq-master)
[![licence](https://img.shields.io/badge/License-MIT-blue.svg?style=flat)](https://tldrlegal.com/license/mit-license)
    
Powerful queue system for IOS built on top of operation and OperationQueue.

## Example Code
For a thorough example see the demo project in the top level of the repository.

### Create a queue and schedule a task
```swift
// Create queue
let queue = JobQueue(creators: [creator], persister: persister)

JobBuilder(taskID: taskID, jobType: jobType)
        .addTag(tag: tag) // To cancel base on tag
        .delay(inSecond: delay) // delay before execution
        .deadline(date: deadline) // Will be canceled after a certain date
        .internet(required: true) // Only run if the device is connected
        .persist(required: true) // See persistence section
        .with(params: params) // Add custom params
        .retry(max: retries) // Number of retires if the job fail
        .periodic(count: runCount, interval: interval) // Auto repeat job
        .schedule(queue: queue) // Add to queue
```

### Job creation
```swift
class MyJob: Job {
    
    public static let type = "MyJob"    

    func onRunJob(callback: JobResult) throws {
        // Actual task has to run here
        callback.onDone(error: nil) // Give the error if your network call or anything failed
    }

    func onError(error: Error) -> RetryConstraint {
        // Do something when the job failed
        // Will not be called if retry count to set to default (0)
        return RetryConstraint.retry // Ask to retry
    }

    func onComplete() {
        // Success ! This job will never run anymore
    }

    func onCancel() {
        // Fail ! This job will never run anymore
        // Can be due to deadline, retry count reach limit, or RetryConstraint.cancel
    }
}
```

### Job callback creation
```swift
class MyCreator: JobCreator {

    func create(jobType: String, params: Any?) -> Job? {
        if jobType == MyJob.type {
            return MyJob()
        } else {
            return nil
        }
    }
}
```