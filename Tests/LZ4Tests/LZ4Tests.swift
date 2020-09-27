/*
 Copyright 2020 TupleStream OÜ

 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import XCTest
import class Foundation.Bundle
import LZ4

extension Array where Element == UInt8 {

    func toString() -> String {
        return String(bytes: self, encoding: .utf8)!
    }
}

class StringOutputStream: OutputStream {

    private var outputString: String = ""

    override func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        let data = Data(bytes: buffer, count: len)
        outputString += String(data: data, encoding: .utf8)!
        return len
    }

    override var description: String {
        get {
            return outputString
        }
    }

    var size: Int {
        return outputString.count
    }
}

class LZ4Tests: XCTestCase {

    func testCompressionDecompressionSmallInput() {
        let inputString = "the quick brown fox jumps over the lazy dog"
        let size = inputString.utf8.count

        // compression
        let inputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)

        inputString.withCString { (baseAddress) in
            let asUnsigned = UnsafeRawPointer(baseAddress).assumingMemoryBound(to: UInt8.self)
            inputBuffer.initialize(from: asUnsigned, count: size)
        }
        defer {
            inputBuffer.deallocate()
        }
        let outputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size * 2)
        outputBuffer.initialize(repeating: 0, count: size)

        let os = OutputStream(toBuffer: outputBuffer, capacity: size * 2)
        os.open()

        let output = LZ4FrameOutputStream(sink: os)

        let firstWriteCall = output.write(inputBuffer, maxLength: size)
        XCTAssertEqual(7, firstWriteCall) // on first write, we'll just be flushing the header

        output.close()

        XCTAssertEqual(58, output.totalBytesWritten)

        let d = Data(buffer: UnsafeMutableBufferPointer(start: outputBuffer, count: output.totalBytesWritten))
        let inputStream = InputStream(data: d)
        inputStream.open()

        // decompression
        let decompressor = LZ4FrameInputStream(source: inputStream)

        defer {
            inputStream.close()
            decompressor.close()
            outputBuffer.deallocate()
        }

        var outputString = ""

        while let bytes = decompressor.next() {
            outputString += bytes.toString()
        }

        // did we get back what we put in?
        XCTAssertEqual(inputString, outputString)
    }

    func testDecompression() {
        let file = InputStream(fileAtPath: "/Users/chris/Desktop/install.log.lz4")!
        file.open()

        let decompressor = LZ4FrameInputStream(source: file)
        defer { decompressor.close() }

        let output = StringOutputStream()
        decompressor.readAll(sink: output)

        file.close()

        print(decompressor.bytesRead)
        print(output.size)
    }
}
