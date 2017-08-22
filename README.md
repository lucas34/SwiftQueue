# SwiftQueue
[![pod](https://img.shields.io/cocoapods/v/SwiftQueue.svg?style=flat)](https://github.com/lucas34/SwiftQueue)
[![swift](https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat)](https://swift.org)
[![travis](https://travis-ci.org/lucas34/SwiftQueue.svg?branch=master)](https://travis-ci.org/lucas34/SwiftQueue)
[![codecov](https://codecov.io/gh/lucas34/SwiftQ/branch/master/graph/badge.svg)](https://codecov.io/gh/lucas34/SwiftQueue)
[![codebeat badge](https://codebeat.co/badges/4ac05b9d-fefa-4be3-a38f-f58a4b5698cd)](https://codebeat.co/projects/github-com-lucas34-swiftq-master)
[![licence](https://img.shields.io/badge/License-MIT-blue.svg?style=flat)](https://tldrlegal.com/license/mit-license)
    
Queue manager built on top of Operation and OperationQueue. Support multiple queues with concurrent run, failure/retry, persistence and more.

## How to use

Don't forget to check our [**WIKI**](https://github.com/lucas34/SwiftQueue/wiki). 

### Sample
Schedule and send tweets with SwiftQueue.

#### Create a queue and schedule a task

```swift
// Create my Queue manager
let manager = SwiftQueueManager(creators: [TweetJobCreator()])

class TweetJobCreator: JobCreator {

    // Base on type, return the actual job implementation
    func create(type: String, params: Any?) -> Job? {
        // check for job and params type
        if type == SendTweetJob.type, let message = params as? String  {
            return SendTweetJob(message: message)
        } else {
            // Nothing match
            return nil
        }
    }
}
```

After that you can start scheduling jobs.

```swift
// type I'll receive in JobCreator
JobBuilder(type: SendTweetJob.type)
        // params of my job
        .with(params: "Hello TweetWorld")
        // Add to queue manager
        .schedule(manager: manager)
```

#### Job creation


```swift
// A job to send a tweet
class SendTweetJob: Job {
    
    // Type to know which Job to return in job creator
    static let type = "SendTweetJob"
    // Param
    private let tweetMessage: String

    required init(message: String) {
        // Receive params from JobBuilder.with()
        self.tweetMessage = message
    }

    func onRun(callback: JobResult) throws {
        // Run your job here
        callback.onDone(error: nil)
    }

    func onRetry(error: Error) -> RetryConstraint {
        // Check if error is non fatal
        return error is ApiError ? RetryConstraint.cancel : RetryConstraint.retry
    }

    func onRemove(error: Error?) {
        // This job will never run anymore  
        // Success if error is nil. fail otherwise
    }
}
```

### Advanced
JobBuilder has many extra options.
```swift
JobBuilder(type: SendTweetJob.type)
        // Job with same id will not run
        .singleInstance(forId: "tweet1")
        // Other groups will run in parallel
        .group(name: "tweet")
        // To cancel base on tag
        .addTag(tag: "tweet")
        // Job requires internet
        // .any : No internet required
        // .cellular : Need connection (3G, 4G, Wifi, ...)
        // .wifi : Requires wifi
        .internet(atLeast: .cellular)
        // Wait before execution
        .delay(inSecond: 1)
        // Cancel after a certain date
        .deadline(date: deadline)
        // Persist job in database
        .persist(required: true)
        // Custom params to your job
        .with(params: "Hello TweetWorld")
        // Max number of retries
        .retry(max: 5)
        // Run two times with at least 5 seconds interval.
        .periodic(count: 2, interval: 5) // Auto repeat job. Wait 5 seconds between each run
        // Add to Operation Queue
        .schedule(manager: manager)
```

## Contributors

* [Lucas Nelaupe](http://www.lucas-nelaupe.fr/) - <https://github.com/lucas34>
* Feel free to contribute, All suggestions are welcome :-)

## License

Licensed under the [MIT License](https://github.com/lucas34/SwiftQueue/blob/master/LICENSE)