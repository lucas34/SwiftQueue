//
// Created by Lucas Nelaupe on 19/4/18.
//

import Foundation

/// Implementation of `JobInfoSerializer` with `JSONEncoder` and `JSONDecoder`
public class DecodableSerializer: JobInfoSerialiser {

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// Init DecodableSerializer with custom instance of `JSONEncoder` and  `JSONDecoder`
    public init(encoder: JSONEncoder = JSONEncoder(), decoder: JSONDecoder = JSONDecoder()) {
        self.encoder = encoder
        self.decoder = decoder
    }

    /// Convert `JobInfo` to Json with `JSONEncoder`
    public func serialise(info: JobInfo) throws -> String {
        let encoded = try encoder.encode(info)
        guard let string = String(data: encoded, encoding: .utf8) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unable to convert decoded data to utf-8")
            )
        }
        return string
    }

    /// Convert string to `JobInfo` with `JSONDecoder`
    public func deserialize(json: String) throws -> JobInfo {
        guard let data = json.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unable to convert decoded data to utf-8")
            )
        }
        return try decoder.decode(JobInfo.self, from: data)
    }

}
