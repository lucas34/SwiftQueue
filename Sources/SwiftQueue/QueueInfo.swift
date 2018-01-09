//
// Created by Yunarta Kartawahyudi on 10/1/18.
//

import Foundation

/// Queue info snapshot
public struct QueueInfo {

    /// Job queue group name
    public var name: String

    /// Current queue count
    public var queueCount: Int

    /// Whether the queue is suspended
    public var isSuspended: Bool
}
