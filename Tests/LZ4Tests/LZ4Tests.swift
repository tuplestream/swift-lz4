import XCTest
import class Foundation.Bundle
import LZ4

final class LZ4Tests: XCTestCase {

    func testCompression() {
        let inputString = "the quick brown fox jumps over the lazy dog"
        let size = inputString.utf8.count
        let inputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)

        inputString.withCString { (baseAddress) in
            let asUnsigned = UnsafeRawPointer(baseAddress).assumingMemoryBound(to: UInt8.self)
            inputBuffer.initialize(from: asUnsigned, count: size)
        }
        defer {
            inputBuffer.deallocate()
        }
        let outputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
        outputBuffer.initialize(repeating: 0, count: size)
        let os = OutputStream(toBuffer: outputBuffer, capacity: size)
        os.open()

        let output = LZ4FrameOutputStream(sink: os)

        let w = output.write(inputBuffer, maxLength: size)
        print("\(w)")

        output.close()
        os.close()
    }

    func testDecompression() {
//        let compressedInput = InputStream(fileAtPath: "/Users/cmow0001/os/swift-lz4-runner/Tests/examples/compressed.txt.lz4")
//        compressedInput?.open()
//        let decompressor = LZ4FrameInputStream(source: compressedInput!)
//
//        let size = 1024
//        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
//        buffer.initialize(repeating: 0, count: size)
//        defer {
//            buffer.deallocate()
//        }
//
//        decompressor.read(buffer, maxLength: size)
    }
}

//func compressFile(file: String) {

//    let out = OutputStream.init(toFileAtPath: file + ".compressed", append: false)
//    out?.open()
//    let os = LZ4FrameOutputStream(sink: out!, bufferSize: bufSize)
//
//    while true {
//        let read = fread(bi, 1, bufSize, fd)
//        if read == 0 {
//            break
//        }
//
//        os.write(bi, maxLength: read)
//    }
//
//    os.finish()
//    os.close()
//    out?.close()
//
////    let tailSize = LZ4F_compressEnd(ctx.pointee, bo, outBufCapacity, nil)
////    print("\(tailSize)")
//
////    fwrite(bo, 1, tailSize, targetFd)
//}
//
//compressFile(file: "/Users/cmow0001/Desktop/testing.log")
