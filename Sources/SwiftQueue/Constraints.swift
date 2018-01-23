//
// Created by Lucas Nelaupe on 10/08/2017.
// Copyright (c) 2017 lucas34. All rights reserved.
//

import Foundation

internal protocol JobConstraint {

    /**
        - Operation will be added to the queue
        Raise exception if the job cannot run
    */
    func willSchedule(queue: SqOperationQueue, operation: SqOperation) throws

    /**
        - Operation will run
        Raise exception if the job cannot run anymore
    */
    func willRun(operation: SqOperation) throws

    /**
        - Operation will run
        Return false if the job cannot run immediately
    */
    func run(operation: SqOperation) -> Bool

}

/// Generic class for any constraint violation
open class ConstraintError: Swift.Error {}

/// Job has been canceled
public final class Canceled: Swift.Error {}

/// Behaviour for retrying the job
public enum RetryConstraint {
    /// Retry after a certain time. If set to 0 it will retry immediately
    case retry(delay: TimeInterval)
    /// Will not retry, onRemoved will be called immediately
    case cancel
    /// Exponential back-off
    case exponential(initial: TimeInterval)
}
