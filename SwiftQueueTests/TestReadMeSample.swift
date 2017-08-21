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
        let taskID = UUID().uuidString
        let deadline = Date()

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
    }

}

class SendTweetJob: Job {

    public static let type = "SendTweetJob"

    private let tweetMessage: String

    required init(message: String) {
        self.tweetMessage = message
    }

    func onRunJob(callback: JobResult) throws {
        // Actual sending is happening here
        //api.sendTweet(type: "TEXT", content: tweetMessage)
        //        .onSucess {
        //            callback.onDone(error: nil)
        //        }.onFail { error in
        //            callback.onDone(error: error)
        //        }
    }

    func onError(error: Error) -> RetryConstraint {
        // Job as failed and retry count > 0
        // WARNING will not be called if you put .retry(count: 0) in job builder
        // Convenient if you want to check base on the error to retry or not
        // if error is ApiError {
        //     // Server rejected my message.
        //     return RetryConstraint.cancel // Stop even if retry count > 0
        // } else {
        //     return RetryConstraint.retry // Ask to retry
        // }
        return RetryConstraint.cancel
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