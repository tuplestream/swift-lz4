/*
 Copyright 2020 TupleStream OÜ

 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import Foundation

import XCTest
import class Foundation.Bundle
import LZ4

class StreamsTests: XCTestCase {

    func testCopyingString() {
        let input = "hello, world"
        let s0 = StringStream(string: input)
        XCTAssertEqual(s0.size, 12)
        XCTAssertEqual(input, s0.description)

        let s1 = StringStream()
        XCTAssertNotEqual(s0, s1)

        XCTAssertEqual(input.count, s0.readAll(sink: s1))
        XCTAssertEqual(input, s1.description)
        XCTAssertEqual(s0, s1)
    }

    func testWriteBufferToStringStream() {
        let foo  = "the quick brown fox jumps over the lazy dog"
        let raw = foo.data(using: .utf8)!

        let first = StringStream()

        let bytesWritten = raw.withUnsafeBytes {
            first.write($0, length: raw.count)
        }

        XCTAssertEqual(foo.count, bytesWritten)
        XCTAssertEqual(foo, first.description)
        XCTAssertEqual(foo.count, first.size)

        let second = StringStream()
        XCTAssertEqual(foo.count, first.readAll(sink: second))

        XCTAssertEqual(foo, second.description)
    }

//    func testFileWrite() {
//        let fileStream = FileStream(filename: "/Users/chris/Desktop/test.txt")
//        defer { fileStream.close() }
//
//        let data = "the quick brown fox jumps over the lazy dog".data(using: .utf8)!
//
//        data.withUnsafeBytes({
//            fileStream.write($0, length: data.count)
//        })
//    }
}
