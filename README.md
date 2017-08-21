## SwiftQueue
[![pod](https://img.shields.io/cocoapods/v/SwiftQueue.svg?style=flat)](https://github.com/lucas34/SwiftQueue)
[![swift](https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat)](https://swift.org)
[![travis](https://travis-ci.org/lucas34/SwiftQueue.svg?branch=master)](https://travis-ci.org/lucas34/SwiftQueue)
[![codecov](https://codecov.io/gh/lucas34/SwiftQ/branch/master/graph/badge.svg)](https://codecov.io/gh/lucas34/SwiftQueue)
[![codebeat badge](https://codebeat.co/badges/4ac05b9d-fefa-4be3-a38f-f58a4b5698cd)](https://codebeat.co/projects/github-com-lucas34-swiftq-master)
[![licence](https://img.shields.io/badge/License-MIT-blue.svg?style=flat)](https://tldrlegal.com/license/mit-license)
    
Powerful queue system for IOS built on top of operation and OperationQueue.

### Sample Code
Schedule and send tweet with SwiftQueue

#### Create a queue and schedule a task
```swift
// Create queue
let manager = SwiftQueueManager(creators: [TweetJobCreator()])

JobBuilder(type: SendTweetJob.type)
        .singleInstance(forId: taskID)
        .group(name: "tweet") // Other groups will run in parallel
        .addTag(tag: "tweet") // To cancel base on tag
        .internet(atLeast: .cellular) // .any : No internet required; .cellular: Need connection; .wifi: Require wifi
        .delay(inSecond: 1) // delay before execution
        .deadline(date: deadline) // Will be canceled after a certain date
        .persist(required: true) // See persistence section
        .with(params: "Hello TweetWorld") // Add custom params
        .retry(max: 5) // Number of retires if the job fail
        .periodic(count: Int.max, interval: 5) // Auto repeat job. Wait 5 seconds between each run
        .schedule(manager: manager) // Add to queue
```

#### Job creation

```swift
class SendTweetJob: Job {
    
    public static let type = "SendTweetJob"

    private let tweetMessage: String

    required init(message: String) {
        self.tweetMessage = message
    }

    func onRunJob(callback: JobResult) throws {
        // Actual sending is happening here
        api.sendTweet(type: "TEXT", content: tweetMessage)
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

#### Link job and JobBuilder
JobBuilder and Job are't linked due to job persistance capability. SwiftQueue will ask you to return your job implementation base on the job type.

```swift
class TweetJobCreator: JobCreator {

    func create(type: String, params: Any?) -> Job? {
        // check for job and param types
        if type == SendTweetJob.type, let message = params as? String  {
            return SendTweetJob(message: message)
        } else {
            // Nothing match
            return nil
        }
    }
}
```
