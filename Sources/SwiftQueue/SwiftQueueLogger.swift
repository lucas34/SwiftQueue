//
// Created by Lucas Nelaupe on 18/4/18.
//

import Foundation

/// Specify different importance of logging
public enum LogLevel: Int {

    /// Basic information about scheduling, running job and completion
    case verbose = 1
    /// Important but non fatal information
    case warning = 2
    /// Something went wrong during the scheduling or the execution
    case error = 3

}

public extension LogLevel {

    /// Describe type of level in human-way
    public var description: String {
        switch self {
        case .verbose:
            return "verbose"
        case .warning:
            return "warning"
        case .error:
            return "error"
        }
    }
}

/// Protocol to implement for implementing your custom logger
public protocol SwiftQueueLogger {

    /// Function called by the library to log an event
    func log(_ level: LogLevel, jobId: @autoclosure () -> String, message: @autoclosure () -> String)

}

/// Class to compute the log and print to the console
open class ConsoleLogger: SwiftQueueLogger {

    private let min: LogLevel

    /// Define minimum level to log. By default, it will log everything
    public init(min: LogLevel = .verbose) {
        self.min = min
    }

    /// Check for log level and create the output message
    public final func log(_ level: LogLevel, jobId: @autoclosure () -> String, message: @autoclosure () -> String) {
        if min.rawValue <= level.rawValue {
            printComputed(output: "[SwiftQueue] level=\(level.description) jobId=\(jobId()) message=\(message())")
        }
    }

    /// Print with default `print()` function. Can be override to changed the output
    open func printComputed(output: String) {
        print(output)
    }

}

/// Class to ignore all kind of logs
public class NoLogger: SwiftQueueLogger {

    /// Singleton instance to avoid multiple instance across all queues
    public static let shared = NoLogger()

    private init() {}

    /// Default implementation that will not log anything
    public func log(_ level: LogLevel, jobId: @autoclosure () -> String, message: @autoclosure () -> String) {
        // Nothing to do
    }
}
