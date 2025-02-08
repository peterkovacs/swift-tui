// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftTUI",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftTUI",
            targets: ["SwiftTUI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.6.0"),
        .package(url: "https://github.com/peterkovacs/swift-snapshot-testing", branch: "main"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.3"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftTUI",
            dependencies: [
                "CUnicode",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
            ]
        ),
        .target(name: "CUnicode"),
        .testTarget(
            name: "SwiftTUITests",
            dependencies: [
                "SwiftTUI",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            exclude: [
                "__Snapshots__"
            ]
        ),
    ]
)
