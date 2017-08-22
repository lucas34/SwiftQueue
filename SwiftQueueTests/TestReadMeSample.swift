//
// Created by Lucas Nelaupe on 21/8/17.
// Copyright (c) 2017 Lucas Nelaupe. All rights reserved.
//

import UIKit
import XCTest
import Dispatch
@testable import SwiftQueue

class TestReadMeSample: XCTestCase {

    public func testBuilder() {
        let deadline = Date()

        // Create queue
        let manager = SwiftQueueManager(creators: [TweetJobCreator()])

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
    }

}

class SendTweetJob: Job {

    static let type = "SendTweetJob"
    private let tweetMessage: String

    required init(message: String) {
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

class TweetJobCreator: JobCreator {

    func create(type: String, params: Any?) -> Job? {
        // check for job and param types
        if type == SendTweetJob.type, let message = params as? String {
            return SendTweetJob(message: message)
        } else {
            // Nothing match
            return nil
        }
    }
}

enum ApiError: Error {
}
