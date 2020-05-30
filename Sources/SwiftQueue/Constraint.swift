// The MIT License (MIT)
//
// Copyright (c) 2019 Lucas Nelaupe
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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

protocol CodableConstraint: Encodable {

    /**
        Build constraint when deserialize
        Return nil if the constraint does not apply
    */
    init?(from decoder: Decoder) throws

}

internal class SimpleConstraint: JobConstraint {

    func willSchedule(queue: SqOperationQueue, operation: SqOperation) throws {}

    func willRun(operation: SqOperation) throws {}

    func run(operation: SqOperation) -> Bool { true }

}
