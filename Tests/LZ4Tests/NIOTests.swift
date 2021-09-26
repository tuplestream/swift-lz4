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

    func testEndToEndEmptyBuffer() {
        var emptyInput = ByteBuffer()
        let compressed = emptyInput.lz4Compress()
        let decompressed = compressed.lz4Decompress()

        XCTAssertTrue(emptyInput == compressed)
        XCTAssertEqual(compressed, decompressed)
        XCTAssertEqual(emptyInput, compressed)

        XCTAssertEqual(0, compressed.readableBytes)
        XCTAssertEqual(0, decompressed.readableBytes)
    }

    func testDecompressSimpleString() {
        let stringData = "the quick brown fox jumps over the lazy dog 🐶"
        var startBuffer = ByteBuffer(string: stringData)

        let compressed = startBuffer.lz4Compress()

        XCTAssertEqual(63, compressed.readableBytes)

        var decompressed = compressed.lz4Decompress()
        let decompressedString = decompressed.readString(length: decompressed.readableBytes)

        XCTAssertEqual(stringData, decompressedString!)
    }

    func testByteBufferWriter() {
        let writer = ByteBufferLZ4Writer()

        writer.write(ByteBuffer(string: "hello"))
        writer.write(ByteBuffer(string: "world"))

        let compressed = writer.getCompressed()
        XCTAssertNotNil(compressed)
        // (if we call getCompressed() a second time on the writer we'll get nothing back
        XCTAssertNil(writer.getCompressed())

        var decompressed = compressed!.lz4Decompress()

        let decompressedString = decompressed.readString(length: decompressed.readableBytes, encoding: .utf8)

        XCTAssertEqual("helloworld", decompressedString!)
    }

    func testCompressionDecompressionLargeInput() {
        var data = ByteBuffer()
        var string: String = ""
        for _ in 0...50000 {
            string += randomString(length: 16)
        }

        data.writeString(string)
        let compressed = data.lz4Compress()

        var decompressed = compressed.lz4Decompress()
        let decompressedString = decompressed.readString(length: decompressed.readableBytes)
        XCTAssertEqual(string, decompressedString)
    }

    private func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }
}
