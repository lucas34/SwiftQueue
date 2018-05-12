# SwiftQueue
> Schedule tasks with constraints made easy.

[![Awesome](https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg)](https://github.com/sindresorhus/awesome)
[![platform](https://img.shields.io/cocoapods/p/SwiftQueue.svg)](https://cocoapods.org/pods/SwiftQueue)
[![swift](https://img.shields.io/badge/Swift-3.2%20%20%7C%204.1-orange.svg)](https://swift.org)
[![travis](https://travis-ci.org/lucas34/SwiftQueue.svg?branch=master)](https://travis-ci.org/lucas34/SwiftQueue)
[![codecov](https://codecov.io/gh/lucas34/SwiftQueue/branch/master/graph/badge.svg)](https://codecov.io/gh/lucas34/SwiftQueue)
[![pod](https://img.shields.io/cocoapods/v/SwiftQueue.svg?style=flat)](https://cocoapods.org/pods/SwiftQueue)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Documentation](https://lucas34.github.io/SwiftQueue/badge.svg)](https://lucas34.github.io/SwiftQueue)

`SwiftQueue` is a job scheduler for iOS inspired by popular android libraries like *android-priority-jobqueue* or *android-job*. It allows you to run your tasks with run and retry constraints. 

Library will rely on `Operation` and `OperationQueue` to make sure all tasks will run in order. Don't forget to check our [**WIKI**](https://github.com/lucas34/SwiftQueue/wiki). 

## Features

- [x] Sequential execution
- [x] Concurrent run
- [x] Persistence
- [x] Cancel all, by id or by tag
- [x] Delay
- [x] Deadline
- [x] Internet constraint
- [x] Single instance in queue
- [x] Retry: Max count, exponential backoff
- [x] Periodic: Max run, interval delay
- [x] Start / Stop queue

## Requirements

- iOS 8.0+, watchOS 2.0+, macOS 10.10+, tvOS 9.0+
- Xcode 7.3

## Installation

#### Carthage
`SwiftQueue` is `carthage` compatible. Add the following entry in your `Cartfile`:

```
github "lucas34/SwiftQueue"
```

Then run `carthage update`.

#### CocoaPods
You can use [CocoaPods](https://cocoapods.org/pods/SwiftQueue) to install `SwiftQueue` by adding it to your `Podfile`:

```ruby
platform :ios, '8.0'
use_frameworks!
pod 'SwiftQueue'
```

In your application, simply import the library

``` swift
import SwiftQueue
```
## Example
This example will simply wrap an api call. Create your custom job by extending `Job` with `onRun`, `onRetry` and `onRemove` callbacks.

```swift
// A job to send a tweet
class SendTweetJob: Job {
    
    // Type to know which Job to return in job creator
    static let type = "SendTweetJob"
    // Param
    private let tweet: [String: Any]

    required init(params: [String: Any]) {
        // Receive params from JobBuilder.with()
        self.tweet = params
    }

    func onRun(callback: JobResult) {
        let api = Api()
        api.sendTweet(data: tweet).execute(onSuccess: {
            callback.done(.success)
        }, onError: { error in
            callback.done(.fail(error))
        })
    }

    func onRetry(error: Error) -> RetryConstraint {
        // Check if error is non fatal
        return error is ApiError ? RetryConstraint.cancel : RetryConstraint.retry(delay: 0) // immediate retry
    }

    func onRemove(result: JobCompletion) {
        // This job will never run anymore  
        switch result {
            case .success:
                // Job success
            break
            
            case .fail(let error):
                // Job fail
            break
       
        }
    }
}
```

Create your `SwiftQueueManager` and **keep the reference**. If you want to cancel a job it has to be done with the same instance.

```swift
let manager = SwiftQueueManagerBuilder(creator: TweetJobCreator()).build()
```

Schedule your job and specify the constraints.

```swift
JobBuilder(type: SendTweetJob.type)
        // Requires internet to run
        .internet(atLeast: .cellular)
        // params of my job
        .with(params: ["content": "Hello world"])
        // Add to queue manager
        .schedule(manager: manager)
```

Bind your `job` type with an actual instance.

```swift
class TweetJobCreator: JobCreator {

    // Base on type, return the actual job implementation
    func create(type: String, params: [String: Any]?) -> Job {
        // check for job and params type
        if type == SendTweetJob.type  {
            return SendTweetJob(params: params)
        } else {
            // Nothing match
            // You can use `fatalError` or create an empty job to report this issue.
            fatalError("No Job !")
        }
    }
}
```

## Contributors

We would love you for the contribution to **SwiftQueue**, check the [`LICENSE`](LICENSE) file for more info.

* [Lucas Nelaupe](http://www.lucas-nelaupe.fr/) - [@lucas34990](https://twitter.com/lucas34990)

## License

Distributed under the MIT license. See [`LICENSE`](LICENSE) for more information.
