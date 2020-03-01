import Foundation
import Logging
import lz4

public class LZ4FrameOutputStream : OutputStream {

    private let bufferSize: Int
    private let frameInfo: LZ4F_frameInfo_t
    private let outBufCapacity: Int

    private var ctx: UnsafeMutablePointer<OpaquePointer?>
    private var prefs: LZ4F_preferences_t
    private var headerWritten: Bool
    private var outputBuffer: UnsafeMutablePointer<UInt8>
    private var sink: OutputStream

    init(sink: OutputStream, bufferSize: Int = 1024 * 16) {
        self.bufferSize = bufferSize
        self.frameInfo = LZ4F_frameInfo_t(blockSizeID: LZ4F_max256KB, blockMode: LZ4F_blockLinked, contentChecksumFlag: LZ4F_noContentChecksum, frameType: LZ4F_frame, contentSize: 0, dictID: 0, blockChecksumFlag: LZ4F_noBlockChecksum)
        self.prefs = LZ4F_preferences_t(frameInfo: frameInfo, compressionLevel: 0, autoFlush: 0, favorDecSpeed: 0, reserved: (0,0,0))
        self.outBufCapacity = LZ4F_compressBound(bufferSize, &prefs)

        self.ctx = UnsafeMutablePointer<OpaquePointer?>.allocate(capacity: MemoryLayout<LZ4F_compressionContext_t>.size)
        let creation = LZ4F_createCompressionContext(ctx, UInt32(LZ4F_VERSION))
        if LZ4F_isError(creation) != 0 {
            print("Couldn't create context")
            exit(1)
        }
        self.headerWritten = false
        self.outputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: outBufCapacity)
        outputBuffer.initialize(repeating: 0, count: outBufCapacity)
        self.sink = sink
        super.init(toBuffer: outputBuffer, capacity: bufferSize)
    }

    public override func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        if !headerWritten {
            let headerSize = LZ4F_compressBegin(ctx.pointee, outputBuffer, outBufCapacity, &prefs)
            if LZ4F_isError(headerSize) != 0 {
                print("oh noes, couldn't write header")
            }
            headerWritten = true
            
            if headerSize > 0 {
                sink.write(outputBuffer, maxLength: headerSize)
            }
            return headerSize
        }

        let compressed = LZ4F_compressUpdate(ctx.pointee, outputBuffer, outBufCapacity, buffer, len, nil)
        if LZ4F_isError(compressed as LZ4F_errorCode_t) == 1 {
            print("oh no")
        }

        if compressed > 0 {
            sink.write(outputBuffer, maxLength: compressed)
        }
        
        return compressed
    }

    func finish() -> Int {
        let compressed = LZ4F_compressEnd(ctx.pointee, outputBuffer, outBufCapacity, nil)
//        bytesAvailable(buffer: outputBuffer, count: compressed)
        sink.write(outputBuffer, maxLength: compressed)
        return compressed
    }

    public override func close() {
        LZ4F_freeCompressionContext(ctx.pointee)
        outputBuffer.deallocate()
    }
}

let bufSize = 16 * 1024

func compressFile(file: String) {

//    var ctx = UnsafeMutablePointer<OpaquePointer?>.allocate(capacity: MemoryLayout<LZ4F_compressionContext_t>.size)
//    let creation = LZ4F_createCompressionContext(ctx, UInt32(LZ4F_VERSION))
//    if LZ4F_isError(creation) != 0 {
//        print("Couldn't create context")
//        exit(1)
//    }
//    defer {
//        LZ4F_freeCompressionContext(ctx.pointee)
//    }
//
//    let frameInfo = LZ4F_frameInfo_t(blockSizeID: LZ4F_max256KB, blockMode: LZ4F_blockLinked, contentChecksumFlag: LZ4F_noContentChecksum, frameType: LZ4F_frame, contentSize: 0, dictID: 0, blockChecksumFlag: LZ4F_noBlockChecksum)
//    var prefs = LZ4F_preferences_t(frameInfo: frameInfo, compressionLevel: 0, autoFlush: 0, favorDecSpeed: 0, reserved: (0,0,0))
//    let outBufCapacity = LZ4F_compressBound(bufSize, &prefs)

    // file descriptors
    let fd = fopen(file, "r")
//    let targetFd = fopen(file + ".compressed", "w")

    // FD buffers
    let bi = UnsafeMutablePointer<UInt8>.allocate(capacity: bufSize)
    bi.initialize(repeating: 0, count: bufSize)
    defer { if let f = fd {
        fclose(fd)
        bi.deallocate()
    }}

//    let bo = UnsafeMutablePointer<UInt8>.allocate(capacity: outBufCapacity)
//    bo.initialize(repeating: 0, count: outBufCapacity)
//    defer { if let f = targetFd {
//        fclose(targetFd)
//        bo.deallocate()
//    }}
    let out = OutputStream.init(toFileAtPath: file + ".compressed", append: false)
    out?.open()
    let os = LZ4FrameOutputStream(sink: out!)

//    let headerSize = LZ4F_compressBegin(ctx.pointee, bo, outBufCapacity, &prefs)
//    if LZ4F_isError(headerSize) != 0 {
//        print("oh noes, couldn't write header")
//    }

//    let written = fwrite(bo, headerSize, 1, targetFd)
//    if written != 1 {
//        print("couldn't write header to file!")
//    }

    while true {
        let read = fread(bi, 1, bufSize, fd)
        if read == 0 {
            break
        }
        
        let compressed = os.write(bi, maxLength: read)
        let foo = String.init(bytesNoCopy: bi, length: read, encoding: String.Encoding.utf8, freeWhenDone: false)
        
//        print("\(compressed) - \(foo!)")

//        let compressed = LZ4F_compressUpdate(ctx.pointee, bo, outBufCapacity, bi, read, nil)

//        fwrite(bo, 1, compressed, targetFd)
    }
    
    os.finish()
    os.close()
    out?.close()

//    let tailSize = LZ4F_compressEnd(ctx.pointee, bo, outBufCapacity, nil)
//    print("\(tailSize)")

//    fwrite(bo, 1, tailSize, targetFd)
}

compressFile(file: "/Users/cmow0001/Desktop/testing.log")
