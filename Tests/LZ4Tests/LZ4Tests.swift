import XCTest
import class Foundation.Bundle
import LZ4

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
    }

    func testUtilityFileCompress() {
//        LZ4Utils.compressFileAndWriteToDestination(inputPath: "/Users/chris/Desktop/install.log", outputPath: "/Users/chris/Desktop/install.log.lz4")
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
