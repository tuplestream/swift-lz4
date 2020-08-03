import XCTest
import class Foundation.Bundle
import LZ4

extension Array where Element == UInt8 {

    func toString() -> String {
        return String(bytes: self, encoding: .utf8)!
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
//            inputBuffer.deallocate()
        }
        let outputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
        outputBuffer.initialize(repeating: 0, count: size)

        let os = OutputStream(toBuffer: outputBuffer, capacity: size * 2)
        os.open()

        let output = LZ4FrameOutputStream(sink: os)

        let firstWrittenCall = output.write(inputBuffer, maxLength: size)
        XCTAssertEqual(7, firstWrittenCall) // on first write, we'll just be flushing the header

        output.close()
        os.close()

//        let d = Data(buffer: UnsafeMutableBufferPointer(start: outputBuffer, count: output.totalBytesWritten))
//        let inputStream = InputStream(data: d)
//        inputStream.open()
//        let decompressor = LZ4FrameInputStream(source: inputStream)
//
//        defer {
//            inputStream.close()
//            decompressor.close()
//        }
//
//        var outputString = ""
//
//        while let bytes = decompressor.next() {
//            outputString += bytes.toString()
//        }
//
//        XCTAssertEqual(inputString, outputString)
    }

//    func testDecompression() {
//        let file = InputStream(fileAtPath: "/Users/chris/Desktop/install.log.lz4")!
//        file.open()
//
//        let decompressor = LZ4FrameInputStream(source: file)
//
//        var outputString = ""
//
//        while let decompressedBytes = decompressor.next() {
//            outputString += decompressedBytes.toString()
//        }
//
//        file.close()
//        decompressor.close()
//    }
}
