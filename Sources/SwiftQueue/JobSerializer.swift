//
// Created by Lucas Nelaupe on 19/4/18.
//

import Foundation

public class DecodableSerializer: JobInfoSerialiser {

    public init() {}

    public func serialise(info: JobInfo) throws -> String {
        let encoded = try JSONEncoder().encode(info)
        guard let utf8 = String(data: encoded, encoding: .utf8) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unable to convert decoded data to utf-8")
            )
        }
        return utf8
    }

    public func deserialize(json: String) throws -> JobInfo {
        guard let data = json.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unable to convert decoded data to utf-8")
            )
        }
        return try JSONDecoder().decode(JobInfo.self, from: data)
    }

}
