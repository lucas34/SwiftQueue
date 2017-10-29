//
// Created by Lucas Nelaupe on 10/08/2017.
// Copyright (c) 2017 lucas34. All rights reserved.
//

import Foundation

internal protocol JobConstraint {

    func schedule(queue: SwiftQueue, operation: SwiftQueueJob) throws

    func run(operation: SwiftQueueJob) throws -> Bool

}

public class ConstraintError: Swift.Error {}
