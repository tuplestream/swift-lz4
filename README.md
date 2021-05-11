# LZ4 For Swift

[![CircleCI](https://img.shields.io/circleci/build/github/tuplestream/swift-lz4)](https://app.circleci.com/pipelines/github/tuplestream/swift-lz4)
[![Gitter](https://badges.gitter.im/tuplestream/community.svg)](https://gitter.im/tuplestream/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

This is an LZ4 implementation that directly wraps Yann Collet's [C implementation](https://github.com/lz4/lz4). It is completely separate from Apple's own [Compression framework](https://developer.apple.com/documentation/compression) and additionally is tested on Linux.

## Getting started

#### Installing liblz4

You need the lz4 library present for this package to link against. You can get it:

* By building from source: grab it from [here](https://github.com/lz4/lz4), cd into the cloned folder and follow the [installation instructions](https://github.com/lz4/lz4#installation)
* By installing via a package manager, e.g. on recent versions of Ubuntu this can be done via `apt-get install zlib1g-dev`

#### Adding the package

swift-lz4 uses [SwiftPM](https://swift.org/package-manager/) as its build tool. Add the package in the usual way, first with a new `dependencies` clause:

```swift
dependencies: [
    .package(url: "https://github.com/tuplestream/swift-lz4.git", from: "0.1.0")
]
```

then add the `LZ4` module to your target dependencies:

```swift
dependencies: [.product(name: "LZ4", package: "swift-lz4"),]
```

#### Integrating in your code

```swift
// 1) Import the LZ4 module
import LZ4
// 2) Import the higher level LZ4NIO module if you want to work with ByteBuffers
import LZ4NIO
```

#### Simple example

```swift
// 3) Using NIO extensions is the most convenient way to get started
import NIO
import LZ4NIO

let allocator = ByteBufferAllocator()
let inputBuffer = allocator.buffer(string: "hello, world")
// return another ByteBuffer with LZ4 compression applied
let compressedBuffer = inputBuffer.lz4Compress()

let decompressed = compressedBuffer.lz4Decompress()

// "hello, world"
print(decompressed.readString(length: decompressed.readableBytes))
```

## Local development

### Building and testing

Requirements:

* Swift 5.3 toolchain
* liblz4 (detailed above)

Building swift-lz4 is like any other Swift package.

* clone the repository: `https://github.com/tuplestream/swift-lz4.git` (feel free to fork it)
* cd into the repository root and build: `cd swift-lz4 && swift build`

### Contributing

Create a branch off `master` and submit a pull request.

### Cross-platform compatibility

Swift-lz4 is designed to run on Linux as well as MacOS. You can build and test it on Linux via the tuplestream base Docker image (you will need the Docker runtime installed on your machine) by running the `linux-test.bash` script in the repository root. CircleCI also runs these tests on PR builds.
