//
//  LZ4.swift
//  
//
//  Created by Chris Mowforth on 01/03/2020.
//

import Foundation
import Logging
import lz4Native

public final class LZ4 {
    public static let defaultBufferSize: Int = 1 << 16
}

public final class LZ4FrameOutputStream: OutputStream {

    private let logger = Logger(label: "LZ4OutputStream")

    private let bufferSize: Int
    private let frameInfo: LZ4F_frameInfo_t
    private let outBufCapacity: Int

    private var ctx: UnsafeMutablePointer<OpaquePointer?>
    private var prefs: LZ4F_preferences_t
    private var headerWritten: Bool
    private var outputBuffer: UnsafeMutablePointer<UInt8>
    private let sink: OutputStream

    public override convenience required init(toMemory: ()) {
        let os = OutputStream(toMemory: ())
        self.init(sink: os)
    }

    public init(sink: OutputStream, bufferSize: Int = LZ4.defaultBufferSize) {
        self.bufferSize = bufferSize
        self.headerWritten = false
        self.frameInfo = LZ4F_frameInfo_t(blockSizeID: LZ4F_max256KB, blockMode: LZ4F_blockLinked, contentChecksumFlag: LZ4F_noContentChecksum, frameType: LZ4F_frame, contentSize: 0, dictID: 0, blockChecksumFlag: LZ4F_noBlockChecksum)
        self.prefs = LZ4F_preferences_t(frameInfo: frameInfo, compressionLevel: 0, autoFlush: 0, favorDecSpeed: 0, reserved: (0,0,0))
        self.outBufCapacity = LZ4F_compressBound(bufferSize, &prefs)

        self.ctx = UnsafeMutablePointer<OpaquePointer?>.allocate(capacity: MemoryLayout<LZ4F_compressionContext_t>.size)
        let creation = LZ4F_createCompressionContext(ctx, UInt32(LZ4F_VERSION))
        if LZ4F_isError(creation) != 0 {
            logger.critical("Couldn't create LZ4F compression context")
        }
        self.outputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: outBufCapacity)
        outputBuffer.initialize(repeating: 0, count: outBufCapacity)
        self.sink = sink
        super.init(toBuffer: outputBuffer, capacity: outBufCapacity)
    }

    public override func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        var headerSize = 0
        if !headerWritten {
            headerSize = LZ4F_compressBegin(ctx.pointee, outputBuffer, outBufCapacity, &prefs)
            if LZ4F_isError(headerSize) != 0 {
                logger.critical("Unable to generate LZ4 header")
                return -1
            }

            let written = sink.write(outputBuffer, maxLength: headerSize)
            if written <= 0 {
                // header write failed
                logger.warning("Unable to write LZ4 header!")
                return written
            }
            headerWritten = true
        }

        let compressed = LZ4F_compressUpdate(ctx.pointee, outputBuffer, outBufCapacity, buffer, len, nil)
        if LZ4F_isError(compressed as LZ4F_errorCode_t) != 0 {
            logger.error("oh no")
        }

        if compressed > 0 {
            let written = sink.write(outputBuffer, maxLength: compressed)
            if written <= 0 {
                return written
            }
        }

        return headerSize + compressed
    }

    private func finish() -> Int {
        let compressed = LZ4F_compressEnd(ctx.pointee, outputBuffer, outBufCapacity, nil)
        return sink.write(outputBuffer, maxLength: compressed)
    }

    public override func close() {
        if finish() <= 0 {
            logger.error("Unable to write end of LZ4 stream!")
        }

        outputBuffer.deallocate()
        LZ4F_freeCompressionContext(ctx.pointee)
    }
}

public struct BlockFormatError: Error {}

public final class LZ4FrameInputStream: Sequence, IteratorProtocol {

    private let headerSize = 7

    private let logger = Logger(label: "LZ4InputStream")

    private var ctx: UnsafeMutablePointer<OpaquePointer?>
    private var headerRead: Bool

    private let scratchbuffer: UnsafeMutablePointer<UInt8>
    private let iteratorBuffer: UnsafeMutablePointer<UInt8>
    private let headerBuffer: UnsafeMutablePointer<UInt8>
    private let source: InputStream
    private var blockSize: size_t?
    private var dstSize: size_t

    public init(source: InputStream) {
        self.ctx = UnsafeMutablePointer<OpaquePointer?>.allocate(capacity: MemoryLayout<LZ4F_compressionContext_t>.size)
        let creation = LZ4F_createDecompressionContext(ctx, UInt32(LZ4F_VERSION))
        if LZ4F_isError(creation) != 0 {
            logger.critical("Couldn't create LZ4F decompression context")
        }

        self.headerRead = false
        self.source = source
        self.headerBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: headerSize)
        headerBuffer.initialize(repeating: 0, count: headerSize)
        self.scratchbuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: LZ4.defaultBufferSize)
        scratchbuffer.initialize(repeating: 0, count: LZ4.defaultBufferSize)
        self.iteratorBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: LZ4.defaultBufferSize)
        iteratorBuffer.initialize(repeating: 0, count: LZ4.defaultBufferSize)
        self.dstSize = 0
    }

    public func next() -> [UInt8]? {
        readHeader()
        var ret = 1
        let rawAmountRead = source.read(scratchbuffer, maxLength: LZ4.defaultBufferSize)

        if rawAmountRead < 0 {
            logger.error("Unable to read stream")
            return nil
        }

        if rawAmountRead == 0 {
            logger.debug("Reached end of stream")
            return nil
        }

        var srcStartPtr = scratchbuffer
        let srcEndPtr = scratchbuffer.advanced(by: rawAmountRead)
        var srcSize = scratchbuffer.distance(to: srcEndPtr)

        while ret != 0 {
            dstSize = blockSize!
            ret = LZ4F_decompress(ctx.pointee, iteratorBuffer, &dstSize, srcStartPtr, &srcSize, nil)

            if lz4Error(ret) {
                return nil
            }

            if dstSize != 0 {
                // flush output- TODO
               return []
            }

            assert(srcStartPtr.distance(to: srcEndPtr) == 0)

            // allocate a buffer big enough for
            let bigger = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: ret + srcSize)
        }

        let _ = lz4Error(ret)

        return nil
    }

    public func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        return 0
    }

    private func readHeader() {
        if headerRead {
            return
        }

        let rawAmountRead = source.read(headerBuffer, maxLength: headerSize)

        let frameInfo = UnsafeMutablePointer<LZ4F_frameInfo_t>.allocate(capacity: MemoryLayout<LZ4F_frameInfo_t>.size)
        let consumed = UnsafeMutablePointer<Int>.allocate(capacity: headerSize)
        consumed.initialize(to: rawAmountRead)
        let info = LZ4F_getFrameInfo(ctx.pointee, frameInfo, headerBuffer, consumed)
        if lz4Error(info) {
            logger.error("Error reading LZ4 header: \(String(cString: LZ4F_getErrorName(info)))")
            return
        }

        self.blockSize = try! LZ4FrameInputStream.getBlockSize(frameInfo.pointee)

        assert(self.blockSize! > 0)

        frameInfo.deallocate()
        consumed.deallocate()
        headerRead = true
    }

    private func lz4Error(_ err: LZ4F_errorCode_t) -> Bool {
        if LZ4F_isError(err) != 0 {
            logger.error("LZ4 Frame error: \(String(cString: LZ4F_getErrorName(err)))")
            return true
        }
        return false
    }

    fileprivate static func getBlockSize(_ frameInfo: LZ4F_frameInfo_t) throws -> size_t {
        switch frameInfo.blockSizeID {
        case LZ4F_default, LZ4F_max64KB:
            return 1 << 16
        case LZ4F_max256KB:
            return 1 << 18
        case LZ4F_max1MB:
            return 1 << 20
        case LZ4F_max4MB:
            return 1 << 22
        default:
            throw BlockFormatError()
        }
    }

    public func close() {
        scratchbuffer.deallocate()
        LZ4F_freeDecompressionContext(ctx.pointee)
    }
}
