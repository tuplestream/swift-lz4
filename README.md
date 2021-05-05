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
```

#### Compression

```
TODO
```


#### Decompression

```
TODO
```
