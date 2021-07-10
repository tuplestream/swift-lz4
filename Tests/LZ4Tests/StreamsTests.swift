/*
 Copyright 2020 TupleStream OÜ

 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import Foundation

import XCTest
import class Foundation.Bundle
import LZ4

public class StreamsTests: XCTestCase {

    func testCopyingString() {
        let input = "hello, world"
        let s0 = BufferedMemoryStream(string: input)
        XCTAssertEqual(s0.size, 12)
        XCTAssertEqual(input, s0.description)

        let s1 = BufferedMemoryStream(string: "")
        XCTAssertNotEqual(s0, s1)

        XCTAssertEqual(input.count, s0.readAll(sink: s1))
        XCTAssertEqual(input, s1.description)
        XCTAssertEqual(s0, s1)
        XCTAssertEqual(s0.internalRepresentation, s1.internalRepresentation)
    }

    func testWriteBufferToStringStream() {
        let foo  = "the quick brown fox jumps over the lazy dog"
        let raw = foo.data(using: .utf8)!

        let first = BufferedMemoryStream(string: "")

        let bytesWritten = first.write(raw.bytes, length: raw.bytes.count)

        XCTAssertEqual(foo.count, bytesWritten)
        XCTAssertEqual(foo, first.description)
        XCTAssertEqual(foo.count, first.size)

        let second = BufferedMemoryStream(string: "")
        XCTAssertEqual(foo.count, first.readAll(sink: second))

        XCTAssertEqual(foo, second.description)
    }
}
