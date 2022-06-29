// The MIT License (MIT)
//
// Copyright (c) 2022 Lucas Nelaupe
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
