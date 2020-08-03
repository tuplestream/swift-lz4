import XCTest
import class Foundation.Bundle
import LZ4

extension Array where Element == UInt8 {

    func toString() -> String {
        return String(bytes: self, encoding: .utf8)!
    }
}

final class LZ4Tests: XCTestCase {

    func testCompression() {
//        let inputString = "the quick brown fox jumps over the lazy dog"
//        let size = inputString.utf8.count
//        let inputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
//
//        inputString.withCString { (baseAddress) in
//            let asUnsigned = UnsafeRawPointer(baseAddress).assumingMemoryBound(to: UInt8.self)
//            inputBuffer.initialize(from: asUnsigned, count: size)
//        }
//        defer {
//            inputBuffer.deallocate()
//        }
//        let outputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
//        outputBuffer.initialize(repeating: 0, count: size)
//        let os = OutputStream(toBuffer: outputBuffer, capacity: size)
//        os.open()
//
//        let output = LZ4FrameOutputStream(sink: os)
//
//        let w = output.write(inputBuffer, maxLength: size)
//        print("\(w)")
//
//        output.close()
//        os.close()
    }

    func testDecompression() {
        let file = InputStream(fileAtPath: "/Users/chris/Desktop/install.log.lz4")!
        file.open()

        let decomp = LZ4FrameInputStream(source: file)

        let out = decomp.next()

        file.close()
        decomp.close()

        print(out!.toString())
    }
}
