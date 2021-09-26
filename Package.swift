// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-lz4",
    platforms: [
        .macOS(.v11),
    ],
    products: [
        .library(name: "LZ4", targets: ["LZ4"]),
        .library(name: "LZ4NIO", targets: ["LZ4NIO"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
    ],
    targets: [
        .systemLibrary(name: "lz4Native", pkgConfig: "liblz4"),
        .target(
            name: "LZ4",
            dependencies: [
                .byName(name: "lz4Native"),
                .product(name: "Logging", package: "swift-log")
            ]),
        .target(
            name: "LZ4NIO",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOFoundationCompat", package: "swift-nio"),
                .byName(name: "LZ4")
            ]
        ),
        .testTarget(
            name: "LZ4Tests",
            dependencies: [
                .byName(name: "LZ4"),
                .byName(name: "LZ4NIO"),
            ]),
    ]
)
