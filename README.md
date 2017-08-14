## SwiftQueue
[![swift](https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat)](https://swift.org")
[![travis](https://travis-ci.org/lucas34/SwiftQ.svg?branch=master)](https://travis-ci.org/lucas34/SwiftQueue)
[![codecov](https://codecov.io/gh/lucas34/SwiftQ/branch/master/graph/badge.svg)](https://codecov.io/gh/lucas34/SwiftQueue)
[![codebeat badge](https://codebeat.co/badges/4ac05b9d-fefa-4be3-a38f-f58a4b5698cd)](https://codebeat.co/projects/github-com-lucas34-swiftq-master)
[![licence](https://img.shields.io/badge/License-MIT-blue.svg?style=flat)](https://tldrlegal.com/license/mit-license)
    
Powerful queue system for IOS built on top of operation and OperationQueue.

## Example Code
For a thorough example see the demo project in the top level of the repository.

### Create a queue and schedule a task
```swift
// Create queue
let queue = SwiftQueue(creators: [creator], persister: persister)

JobBuilder(taskID: taskID, jobType: SendTweetJob.type)
        .addTag(tag: "tweet") // To cancel base on tag
        .delay(inSecond: 1) // delay before execution
        .deadline(date: deadline) // Will be canceled after a certain date
        // TODO .internet(required: true) // Only run if the device is connected.
        .persist(required: true) // See persistence section
        .with(params: "Hellow World") // Add custom params
        .retry(max: 5) // Number of retires if the job fail
        .periodic(count: Int.max, interval: 5) // Auto repeat job. Wait 5 seconds between each run
        .schedule(queue: queue) // Add to queue
```

### Job creation
```swift
class SendTweetJob: Job {
    
    public static let type = "SendTweetJob"    

    private let message: String

    required init(message: String) {
        self.message = message
    }


    func onRunJob(callback: JobResult) throws {
        api.sendTweet(type: "TEXT", content: message)
        .onSucess {
            callback.onDone(error: nil)
        }.onFail { error in
            callback.onDone(error: error)
        }
    }

    func onError(error: Error) -> RetryConstraint {
        // Job as failed and retry count > 0
        // WARNING will not be called if you put .retry(count: 0) in job builder
        // Convenient if you want to check base on the error to retry or not
        if error is ApiError {
            // Server rejected my message.
            return RetryConstraint.cancel // Stop even if retry count > 0
        } else {
            return RetryConstraint.retry // Ask to retry
        }
    }

    func onComplete() {
        // Success ! This job will never run anymore
        // Update your UI or your database
    }

    func onCancel() {
        // Fail ! This job will never run anymore
        // Can be due to deadline, retry count reach limit, or RetryConstraint.cancel
        // Update your UI or your database
    }
}
```

### Job callback creation
```swift
class MyCreator: JobCreator {

    func create(jobType: String, params: Any?) -> Job? {
        if jobType == SendTweetJob.type, let message = params as? String  {
            return SendTweetJob(message: message)
        } else {
            return nil
        }
    }
}
```