// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LZ4",
    products: [
        .library(name: "LZ4", targets: ["LZ4"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    ],
    targets: [
        .systemLibrary(name: "lz4Native", pkgConfig: "liblz4"),
        .target(
            name: "LZ4",
            dependencies: ["Logging", "lz4Native"]),
        .testTarget(
            name: "LZ4Tests",
            dependencies: ["LZ4"]),
    ]
)
