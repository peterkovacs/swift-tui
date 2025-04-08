// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "KeyParser",
    platforms: [
        .macOS(.v15),
    ],
    dependencies: [
        .package(path: "../../"),
    ],
    targets: [
        .executableTarget(
            name: "KeyParser",
            dependencies: [
                .product(name: "SwiftTUI", package: "swift-tui")
            ]
        ),
    ]
)
