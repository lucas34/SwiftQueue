//
// Created by Lucas Nelaupe on 26/5/20.
//

import Foundation

internal final class TagConstraint: SimpleConstraint, CodableConstraint {

    internal var tags: Set<String>

    required init(tags: Set<String>) {
        self.tags = tags
    }

    convenience init?(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: TagConstraintKey.self)
        if container.contains(.tags) {
            try self.init(tags: container.decode(Set<String>.self, forKey: .tags))
        } else { return nil }
    }

    func insert(tag: String) {
        tags.insert(tag)
    }

    func contains(tag: String) -> Bool {
        return tags.contains(tag)
    }

    private enum TagConstraintKey: String, CodingKey {
        case tags
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: TagConstraintKey.self)
        try container.encode(tags, forKey: .tags)
    }
}
