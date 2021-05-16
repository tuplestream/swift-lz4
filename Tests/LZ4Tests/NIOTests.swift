/*
 Copyright 2021 TupleStream OÜ

 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/

import XCTest
import class Foundation.Bundle
import NIO
import LZ4NIO

class NIOTests: XCTestCase {

    static let allocator = ByteBufferAllocator()

    func testEndToEndEmptyBuffer() {
        let emptyInput = NIOTests.allocator.buffer(bytes: [])
        let compressed = emptyInput.lz4Compress()
        let decompressed = compressed.lz4Decompress()

        XCTAssertEqual(compressed, decompressed)
        XCTAssertEqual(emptyInput, compressed)

        XCTAssertEqual(0, compressed.readableBytes)
        XCTAssertEqual(0, decompressed.readableBytes)
    }

    func testDecompressSimpleString() {
        let stringData = "the quick brown fox jumps over the lazy dog 🐶"
        let startBuffer = NIOTests.allocator.buffer(string: stringData)

        let compressed = startBuffer.lz4Compress()

        XCTAssertEqual(63, compressed.readableBytes)

        var decompressed = compressed.lz4Decompress()
        let decompressedString = decompressed.readString(length: decompressed.readableBytes)

        XCTAssertEqual(stringData, decompressedString!)
    }
}
