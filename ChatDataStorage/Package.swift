// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChatDataStorage",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "ChatDataStorage",
            targets: ["ChatDataStorage", "ChatDataKit"]),
    ],
    targets: [
        .target(
            name: "ChatDataStorage", dependencies: ["ChatDataKit"]),
        .target(name: "ChatDataKit"),
        .testTarget(
            name: "ChatDataStorageTests",
            dependencies: ["ChatDataStorage"]
        ),
    ]
)
