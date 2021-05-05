/*
 Copyright 2020 TupleStream OÜ

 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import XCTest
import class Foundation.Bundle
import LZ4

class LZ4Tests: XCTestCase {

    func testCompressionDecompressionSmallInput() {
        let inputString = "the quick brown fox jumps over the lazy dog"
        let sink = FileStream(filename: "/tmp/test-swift-lz.lz4")
        let compressor = LZ4FrameOutputStream(sink: sink)

        // compression
        let data = inputString.data(using: .utf8)!

        let firstWrite = data.withUnsafeBytes({
            compressor.write($0, length: data.count)
        })

        XCTAssertEqual(7, firstWrite) // on first write, we'll just be flushing the header

        compressor.close()
        sink.close()

        XCTAssertEqual(58, compressor.totalBytesWritten)
        XCTAssertEqual(58, sink.size)

        let wibble = InputStream(fileAtPath: "/tmp/test-swift-lz.lz4")!
        wibble.open()

        let decompressor = LZ4FrameInputStream(source: wibble)
        defer { decompressor.close() }

        let finalOutput = BufferedMemoryStream()

        let t = decompressor.readAll(sink: finalOutput)
        XCTAssertEqual(data.count, t)

        XCTAssertEqual(inputString.count, finalOutput.description.count)
        XCTAssertEqual(inputString, finalOutput.description)

        remove("/tmp/test-swift-lz.lz4")
    }
}
