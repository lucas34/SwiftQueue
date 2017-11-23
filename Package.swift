// swift-tools-version:4.0
import PackageDescription

let package = Package(
        name: "SwiftQueue",
        products: [
            .library(name: "SwiftQueue", targets: ["SwiftQueue"]),
        ],
        dependencies: [
            .package(url: "https://github.com/lucas34/Reachability.swift.git", .upToNextMajor(from: "5.0.0")),
        ],
        targets: [
            .target(
                    name: "SwiftQueue",
                    dependencies: ["Reachability"]),
            .testTarget(
                    name: "SwiftQueueTests",
                    dependencies: ["SwiftQueue"]),
        ],
        swiftLanguageVersions: [3, 4]
)
