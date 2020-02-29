import Foundation
import lz4

let bufSize = 16 * 1024

func compressFile(file: String) {
    var ctx = UnsafeMutablePointer<OpaquePointer?>.allocate(capacity: MemoryLayout<LZ4F_compressionContext_t>.size)
    let creation = LZ4F_createCompressionContext(ctx, UInt32(LZ4F_VERSION))
    if LZ4F_isError(creation) != 0 {
        print("Couldn't create context")
        exit(1)
    }
    defer {
        LZ4F_freeCompressionContext(ctx.pointee)
    }

    let frameInfo = LZ4F_frameInfo_t(blockSizeID: LZ4F_max256KB, blockMode: LZ4F_blockLinked, contentChecksumFlag: LZ4F_noContentChecksum, frameType: LZ4F_frame, contentSize: 0, dictID: 0, blockChecksumFlag: LZ4F_noBlockChecksum)
    var prefs = LZ4F_preferences_t(frameInfo: frameInfo, compressionLevel: 0, autoFlush: 0, favorDecSpeed: 0, reserved: (0,0,0))
    let outBufCapacity = LZ4F_compressBound(bufSize, &prefs)
    
    // file descriptors
    let fd = fopen(file, "r")
    let targetFd = fopen(file + ".compressed", "w")

    // FD buffers
    let bi = UnsafeMutablePointer<UInt8>.allocate(capacity: bufSize)
    bi.initialize(repeating: 0, count: bufSize)
    defer { if let f = fd {
        fclose(fd)
        bi.deallocate()
    }}

    let bo = UnsafeMutablePointer<UInt8>.allocate(capacity: outBufCapacity)
    bi.initialize(repeating: 0, count: outBufCapacity)
    defer { if let f = targetFd {
        fclose(targetFd)
        bo.deallocate()
    }}

    let headerSize = LZ4F_compressBegin(ctx.pointee, bo, outBufCapacity, &prefs)
    if LZ4F_isError(headerSize) != 0 {
        print("oh noes, couldn't write header")
    }

    let written = fwrite(bo, headerSize, 1, targetFd)
    if written != 1 {
        print("couldn't write header to file!")
    }

    while true {
        let read = fread(bi, 1, bufSize, fd)
        if read == 0 {
            break
        }

        let compressed = LZ4F_compressUpdate(ctx.pointee, bo, outBufCapacity, bi, read, nil)

        fwrite(bo, 1, compressed, targetFd)
    }

    let tailSize = LZ4F_compressEnd(ctx.pointee, bo, outBufCapacity, nil)
    print("\(tailSize)")

    fwrite(bo, 1, tailSize, targetFd)
}

compressFile(file: "/Users/cmow0001/Desktop/testing.log")
