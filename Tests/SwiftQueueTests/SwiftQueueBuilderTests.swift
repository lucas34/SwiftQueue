//
// Created by Lucas Nelaupe on 12/10/17.
//

import Foundation

import XCTest
import Dispatch
@testable import SwiftQueue

class SwiftQueueBuilderTests: XCTestCase {

    let serializers: [JobInfoSerializer] = [
        V1Serializer(),
        DecodableSerializer()
    ]

    public func testBuilderJobType() throws {
        for serializer in serializers {
            let type = UUID().uuidString

            let jobInfo = try toJobInfo(serializer, type: type, JobBuilder(type: type))
            XCTAssertEqual(jobInfo?.type, type)
        }
    }

    public func testBuilderSingleInstance() throws {
        for serializer in serializers {
            let type = UUID().uuidString
            let uuid = UUID().uuidString

            let jobInfo = try toJobInfo(serializer, type: type, JobBuilder(type: type).singleInstance(forId: uuid))
            XCTAssertEqual(jobInfo?.uuid, uuid)
            XCTAssertEqual(jobInfo?.override, false)
        }
    }

    public func testBuilderSingleInstanceOverride() throws {
        for serializer in serializers {
            let type = UUID().uuidString
            let uuid = UUID().uuidString

            let jobInfo = try toJobInfo(serializer, type: type, JobBuilder(type: type).singleInstance(forId: uuid, override: true))
            XCTAssertEqual(jobInfo?.uuid, uuid)
            XCTAssertEqual(jobInfo?.override, true)
        }
    }

    public func testBuilderGroup() throws {
        for serializer in serializers {
            let type = UUID().uuidString
            let groupName = UUID().uuidString

            let jobInfo = try toJobInfo(serializer, type: type, JobBuilder(type: type).group(name: groupName))
            XCTAssertEqual(jobInfo?.group, groupName)
        }
    }

    public func testBuilderDelay() throws {
        for serializer in serializers {
            let type = UUID().uuidString
            let delay: Double = 1234

            let jobInfo = try toJobInfo(serializer, type: type, JobBuilder(type: type).delay(time: delay))
            XCTAssertEqual(jobInfo?.delay, delay)
        }
    }

    public func testBuilderDeadlineCodable() throws {
        let type = UUID().uuidString
        let deadline = Date(timeIntervalSinceNow: TimeInterval(30))

        let jobInfo = try toJobInfo(DecodableSerializer(), type: type, JobBuilder(type: type).deadline(date: deadline))
        XCTAssertEqual(jobInfo?.deadline, deadline)
    }

    public func testBuilderDeadlineV1() throws {
        let type = UUID().uuidString
        let deadline = Date(timeIntervalSinceNow: TimeInterval(30))

        let jobInfo = try toJobInfo(V1Serializer(), type: type, JobBuilder(type: type).deadline(date: deadline))
        /// V1 have a precision loss
        XCTAssertEqual(jobInfo?.deadline.map(dateFormatter.string), Optional(deadline).map(dateFormatter.string))
    }

    public func testBuilderPeriodicUnlimited() throws {
        for serializer in serializers {
            let type = UUID().uuidString
            let interval: Double = 12341

            let jobInfo = try toJobInfo(serializer, type: type, JobBuilder(type: type).periodic(limit: .unlimited, interval: interval))
            XCTAssertEqual(jobInfo?.maxRun, Limit.unlimited)
            XCTAssertEqual(jobInfo?.interval, interval)
        }
    }

    public func testBuilderPeriodicLimited() throws {
        for serializer in serializers {
            let type = UUID().uuidString
            let limited: Double = 123
            let interval: Double = 12342

            let jobInfo = try toJobInfo(serializer, type: type, JobBuilder(type: type).periodic(limit: .limited(limited), interval: interval))
            XCTAssertEqual(jobInfo?.maxRun, Limit.limited(limited))
            XCTAssertEqual(jobInfo?.interval, interval)
        }
    }

    public func testBuilderInternetAny() throws {
        for serializer in serializers {

            let type = UUID().uuidString
            let network: NetworkType = .any

            let jobInfo = try toJobInfo(serializer, type: type, JobBuilder(type: type).internet(atLeast: network))
            XCTAssertEqual(jobInfo?.requireNetwork, network)
        }
    }

    public func testBuilderInternetCellular() throws {
        for serializer in serializers {
            let type = UUID().uuidString
            let network: NetworkType = .cellular

            let jobInfo = try toJobInfo(serializer, type: type, JobBuilder(type: type).internet(atLeast: network))
            XCTAssertEqual(jobInfo?.requireNetwork, network)
        }
    }

    public func testBuilderInternetWifi() throws {
        for serializer in serializers {
            let type = UUID().uuidString
            let network: NetworkType = .wifi

            let jobInfo = try toJobInfo(serializer, type: type, JobBuilder(type: type).internet(atLeast: network))
            XCTAssertEqual(jobInfo?.requireNetwork, network)
        }
    }

    public func testBuilderRetryUnlimited() throws {
        for serializer in serializers {
            let type = UUID().uuidString

            let jobInfo = try toJobInfo(serializer, type: type, JobBuilder(type: type).retry(limit: .unlimited))
            XCTAssertEqual(jobInfo?.retries, Limit.unlimited)
        }
    }

    public func testBuilderRetryLimited() throws {
        for serializer in serializers {
            let type = UUID().uuidString
            let limited: Double = 123

            let jobInfo = try toJobInfo(serializer, type: type, JobBuilder(type: type).retry(limit: .limited(limited)))
            XCTAssertEqual(jobInfo?.retries, Limit.limited(limited))
        }
    }

    public func testBuilderAddTag() throws {
        for serializer in serializers {
            let type = UUID().uuidString
            let tag1 = UUID().uuidString
            let tag2 = UUID().uuidString

            let jobInfo = try toJobInfo(serializer, type: type, JobBuilder(type: type).addTag(tag: tag1).addTag(tag: tag2))
            XCTAssertEqual(jobInfo?.tags.contains(tag1), true)
            XCTAssertEqual(jobInfo?.tags.contains(tag2), true)
        }
    }

    public func testBuilderWith() throws {
        for serializer in serializers {
            try assertUnicode(serializer, expected: UUID().uuidString)
            try assertUnicode(serializer, expected: "Hello world")
            try assertUnicode(serializer, expected: "Powerلُلُصّبُلُلصّبُررً ॣ ॣh ॣ ॣ冗")
            try assertUnicode(serializer, expected: "🏳0🌈")
            try assertUnicode(serializer, expected: "🤪🤯🧐")
            try assertUnicode(serializer, expected: "జ్ఞ‌ా")
        }
    }

    public func testBuilderWithFreeArgs() {
        for serializer in serializers {
            let type = UUID().uuidString
            let params: [String: Any] = [UUID().uuidString: [UUID().uuidString: self]]

            let creator = TestCreator([type: TestJob()])
            let manager = SwiftQueueManagerBuilder(creator: creator)
                    .set(persister: NoSerializer.shared)
                    .set(serializer: serializer)
                    .build()

            // No assert expected
            // This is just to test if the serialization failed on self
            JobBuilder(type: type).with(params: params).schedule(manager: manager)
        }
    }

    public func testBuilderRequireCharging() throws {
        for serializer in serializers {

            let type = UUID().uuidString

            let jobInfo = try toJobInfo(serializer, type: type, JobBuilder(type: type).requireCharging(value: true))
            XCTAssertEqual(jobInfo?.requireCharging, true)
        }
    }

    private func toJobInfo(_ serializer: JobInfoSerializer, type: String, _ builder: JobBuilder) throws -> JobInfo? {
        let creator = TestCreator([type: TestJob()])

        let persister = PersisterTracker(key: UUID().uuidString)

        let manager = SwiftQueueManagerBuilder(creator: creator)
                .set(persister: persister)
                .set(serializer: serializer)
                .build()

        builder.persist(required: true).schedule(manager: manager)

        return try serializer.deserialize(json: persister.putData[0])
    }

    private func assertUnicode(_ serializer: JobInfoSerializer, expected: String, file: StaticString = #file, line: UInt = #line) throws {
        let type = UUID().uuidString

        let params: [String: Any] = [UUID().uuidString: expected]

        let jobInfo = try toJobInfo(serializer, type: type, JobBuilder(type: type).with(params: params))
        XCTAssertTrue(NSDictionary(dictionary: params).isEqual(to: jobInfo?.params), file: file, line: line)
    }

}
