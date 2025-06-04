// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UniqueHybridLogicalClock",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .watchOS(.v9),
        .tvOS(.v16),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "UniqueHybridLogicalClock",
            targets: ["UniqueHybridLogicalClock"]),
    ],
    targets: [
        .target(
            name: "UniqueHybridLogicalClock"),
        .testTarget(
            name: "UniqueHybridLogicalClockTests",
            dependencies: ["UniqueHybridLogicalClock"]),
    ]
)