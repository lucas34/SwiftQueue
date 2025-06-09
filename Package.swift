// swift-tools-version:5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftQueue",
    platforms: [
        .macOS(.v11),
        .iOS(.v13),
        .macCatalyst(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "SwiftQueue",
            targets: ["SwiftQueue"])
    ],
    dependencies: [
        // Add external dependencies here if needed
    ],
    targets: [
        .target(
            name: "SwiftQueue",
            dependencies: []),
        .testTarget(
            name: "SwiftQueueTests",
            dependencies: ["SwiftQueue"])
    ],
    swiftLanguageVersions: [.v5]
)