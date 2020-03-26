import XCTest
import class Foundation.Bundle
import LZ4

final class LZ4Tests: XCTestCase {

    func testCompression() {
        let os = OutputStream(toMemory: ())
        os.open()
        let output = LZ4FrameOutputStream(sink: os)
        let inputString = "the quick brown fox jumps over the lazy dog"
        let bi = UnsafeMutablePointer<UInt8>.allocate(capacity: inputString.count)
    }
}

//import Foundation
//
//let bufSize = 16 * 1024
//
//func compressFile(file: String) {
//
//    // file descriptors
//    let fd = fopen(file, "r")
//
//    // FD buffers
//    let bi = UnsafeMutablePointer<UInt8>.allocate(capacity: bufSize)
//    bi.initialize(repeating: 0, count: bufSize)
//    defer { if let f = fd {
//        fclose(fd)
//        bi.deallocate()
//    }}
//
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
