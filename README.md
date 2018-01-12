# SwiftQueue
> Schedule tasks with constraints made easy.

[![Awesome](https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg)](https://github.com/sindresorhus/awesome)
[![platform](https://img.shields.io/cocoapods/p/SwiftQueue.svg)](https://cocoapods.org/pods/SwiftQueue)
[![swift](https://img.shields.io/badge/Swift-3.0%20%7C%203.2%20%7C%204.0-orange.svg)](https://swift.org)
[![travis](https://travis-ci.org/lucas34/SwiftQueue.svg?branch=master)](https://travis-ci.org/lucas34/SwiftQueue)
[![codecov](https://codecov.io/gh/lucas34/SwiftQueue/branch/master/graph/badge.svg)](https://codecov.io/gh/lucas34/SwiftQueue)
[![pod](https://img.shields.io/cocoapods/v/SwiftQueue.svg?style=flat)](https://cocoapods.org/pods/SwiftQueue)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![codebeat badge](https://codebeat.co/badges/3d446d9e-3e7a-435c-85fc-aa626d4f7652)](https://codebeat.co/projects/github-com-lucas34-swiftqueue-master)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Documentation](https://lucas34.github.io/SwiftQueue/badge.svg)](https://lucas34.github.io/SwiftQueue)

SwiftQueue is a job scheduler for Ios inspired by popular android libraries like *android-priority-jobqueue* or *android-job*. It allows you to run your tasks with run and retry constraints. 

Library will rely on *Operation* and *OperationQueue* to make sure all tasks will run in order. Don't forget to check our [**WIKI**](https://github.com/lucas34/SwiftQueue/wiki). 

## Features

- [x] Sequential execution
- [x] Concurrent run
- [x] Persistence
- [x] Cancel all or by tag
- [x] Delay
- [x] Deadline
- [x] Internet constraint
- [x] Single instance in queue
- [x] Retry: Max count, exponential backoff
- [x] Periodic: Max run, interval delay
- [x] Start / Stop queue

## Requirements

- iOS 8.0+, watchOS 2.0+, OSX 10.10+, tvOS 9.0+
- Xcode 7.3

## Installation

#### Carthage
SwiftQueue is carthage compatible. Add the following entry in your Cartfile:

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
## Usage example

This short example will shows you how to schedule a task that send tweets. First, you will need to extend `Job` and implement `onRun`, `onRetry` and `onRemove` callbacks.

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

    func onRun(callback: JobResult) throws {
        do {
            try Api().sendTweet(data: tweet)
            // Consider the call synchronous in this case
            callback.done(.success)        
        } catch let error {
            callback.done(.fail(error))    
        }
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

The class `SwiftQueueManager` serves as entry point. Your jobs need to extend the class `Job`. Specify run and retry constraints with `JobBuilder` and schedule by giving `SwiftQueueManager` 

```swift
let manager = SwiftQueueManager(creators: [TweetJobCreator()])
```

Schedule a job with type, parameters and constraints.

```swift
JobBuilder(type: SendTweetJob.type)
        // params of my job
        .with(params: ["content": "Hellow world"])
        // Add to queue manager
        .schedule(manager: manager)
```

The `JobCreator` maps a job type to a specific `job` class. You will receive parameters you specified in `JobBuilder`.

```swift
class TweetJobCreator: JobCreator {

    // Base on type, return the actual job implementation
    func create(type: String, params: [String: Any]?) -> Job? {
        // check for job and params type
        if type == SendTweetJob.type  {
            return SendTweetJob(params: params)
        } else {
            // Nothing match
            return nil
        }
    }
}
```

That's it. We haven't specify any constraint so the job will run immediately. Check the [**WIKI**](https://github.com/lucas34/SwiftQueue/wiki) for a more detailed example.

## Contributors

We would love you for the contribution to **SwiftQueue**, check the ``LICENSE`` file for more info.

* [Lucas Nelaupe](http://www.lucas-nelaupe.fr/) - [@lucas34990](https://twitter.com/lucas34990)

## Licence

Distributed under the MIT license. See ``LICENSE`` for more information.
