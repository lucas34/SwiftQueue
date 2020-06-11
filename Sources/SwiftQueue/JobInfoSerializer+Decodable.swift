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

/// `JSONEncoder` and `JSONDecoder` to serialize JobInfo
public class DecodableSerializer: JobInfoSerializer {

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// Init decodable with custom `JSONEncoder` and `JSONDecoder`
    public init(maker: ConstraintMaker, encoder: JSONEncoder = JSONEncoder(), decoder: JSONDecoder = JSONDecoder()) {
        self.encoder = encoder
        self.decoder = decoder
        self.encoder.userInfo[.constraintMaker] = maker
        self.decoder.userInfo[.constraintMaker] = maker
    }

    public func serialize(info: JobInfo) throws -> String {
        try String.fromUTF8(data: encoder.encode(info))
    }

    public func deserialize(json: String) throws -> JobInfo {
        try decoder.decode(JobInfo.self, from: json.utf8Data())
    }

}

internal extension KeyedDecodingContainer {

    func decode(_ type: Data.Type, forKey key: KeyedDecodingContainer.Key) throws -> Data {
        try self.decode(String.self, forKey: key).utf8Data()
    }

    func decode(_ type: [String: Any].Type, forKey key: KeyedDecodingContainer.Key) throws -> [String: Any] {
        let data = try self.decode(Data.self, forKey: key)
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [key],
                    debugDescription: "Decoded value is not a dictionary")
            )
        }
        return dict
    }

}

internal extension KeyedEncodingContainer {

    mutating func encode(_ value: [String: Any], forKey key: KeyedEncodingContainer.Key) throws {
        let data = try JSONSerialization.data(withJSONObject: value)
        try self.encode(String.fromUTF8(data: data, key: [key]), forKey: key)
    }

}

extension CodingUserInfoKey {
    internal static let constraintMaker: CodingUserInfoKey = CodingUserInfoKey(rawValue: "constraints")!
}
