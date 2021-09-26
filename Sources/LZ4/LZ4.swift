/*
 Copyright 2020 TupleStream OÜ

 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import Foundation
import Logging
import lz4Native

public final class LZ4 {
    public static let defaultBufferSize: Int = 1 << 16

}

protocol LZ4Capable {

    var logger: Logger { get }
    func lz4Error(_ err: LZ4F_errorCode_t) -> Bool
}

extension LZ4Capable {

    func lz4Error(_ err: LZ4F_errorCode_t) -> Bool {
        if LZ4F_isError(err) != 0 {
            logger.error("LZ4 Frame error: \(String(cString: LZ4F_getErrorName(err)))")
            return true
        }
        return false
    }
}

public final class LZ4FrameOutputStream: LZ4Capable {

    internal let logger = Logger(label: "LZ4OutputStream")

    private let frameInfo: LZ4F_frameInfo_t
    public let outputBufferCapacity: Int

    private let ctx: UnsafeMutablePointer<OpaquePointer?>
    private var prefs: LZ4F_preferences_t
    private var headerWritten: Bool
    private let outputBuffer: UnsafeMutablePointer<UInt8>
    private let sink: WriteableStream
    private var bytesWritten: Int = 0
    private var closed: Bool = false

    public init(sink: WriteableStream, bufferSize: Int = LZ4.defaultBufferSize) {
        self.headerWritten = false
        self.frameInfo = LZ4F_frameInfo_t(blockSizeID: LZ4F_max4MB, blockMode: LZ4F_blockLinked, contentChecksumFlag: LZ4F_noContentChecksum, frameType: LZ4F_frame, contentSize: 0, dictID: 0, blockChecksumFlag: LZ4F_noBlockChecksum)
        self.prefs = LZ4F_preferences_t(frameInfo: frameInfo, compressionLevel: 0, autoFlush: 0, favorDecSpeed: 0, reserved: (0,0,0))
        self.outputBufferCapacity = LZ4F_compressBound(bufferSize, &prefs)

        self.ctx = UnsafeMutablePointer<OpaquePointer?>.allocate(capacity: MemoryLayout<LZ4F_compressionContext_t>.size)
        let creation = LZ4F_createCompressionContext(ctx, UInt32(LZ4F_VERSION))
        if LZ4F_isError(creation) != 0 {
            logger.critical("Couldn't create LZ4F compression context")
        }
        self.outputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: outputBufferCapacity)
        outputBuffer.initialize(repeating: 0, count: outputBufferCapacity)
        self.sink = sink
    }

    public var totalBytesWritten: Int {
        get {
            return bytesWritten
        }
    }

    public func write(_ buffer: UnsafePointer<UInt8>, length: Int) -> Int {
        var headerSize = 0
        if !headerWritten {
            headerSize = LZ4F_compressBegin(ctx.pointee, outputBuffer, outputBufferCapacity, &prefs)
            if lz4Error(headerSize) {
                logger.critical("Unable to generate LZ4 header")
                return -1
            }

            let written = sink.write(outputBuffer, length: headerSize)
            if written <= 0 {
                // header write failed
                logger.warning("Unable to write LZ4 header!")
                return written
            }
            headerWritten = true
        }

        let compressed = LZ4F_compressUpdate(ctx.pointee, outputBuffer, outputBufferCapacity, buffer, length, nil)
        if lz4Error(compressed) {
            return -1
        }

        if compressed > 0 {
            let written = sink.write(outputBuffer, length: compressed)
            if written <= 0 {
                return written
            }
        }

        let total = headerSize + compressed
        bytesWritten += total
        return total
    }

    private func finish() -> Int {
        let compressed = LZ4F_compressEnd(ctx.pointee, outputBuffer, outputBufferCapacity, nil)

        if lz4Error(compressed) {
            return -1
        }

        return sink.write(outputBuffer, length: compressed)
    }

    public private(set) var isClosed: Bool = false

    public func close() {
        precondition(!isClosed)
        let trailer = finish()

        outputBuffer.deallocate()
        LZ4F_freeCompressionContext(ctx.pointee)

        if trailer <= 0 {
            logger.error("Unable to write end of LZ4 stream!")
            return
        }

        bytesWritten += trailer
        isClosed = true
    }
}

public struct BlockFormatError: Error {}

public final class LZ4FrameInputStream: LZ4Capable, GreedyStream {

    private static let headerSize = 7

    internal let logger = Logger(label: "LZ4InputStream")

    private var ctx: UnsafeMutablePointer<OpaquePointer?>
    private var headerRead: Bool

    private let scratchbuffer: UnsafeMutablePointer<UInt8>
    private var iteratorBuffer: UnsafeMutablePointer<UInt8>?
    private let headerBuffer: UnsafeMutablePointer<UInt8>
    private let source: ReadableStream
    private var blockSize: size_t?
    private var dstSize: size_t
    public var bytesRead: Int = 0

    public init(source: ReadableStream) {
        self.ctx = UnsafeMutablePointer<OpaquePointer?>.allocate(capacity: MemoryLayout<LZ4F_compressionContext_t>.size)
        let creation = LZ4F_createDecompressionContext(ctx, UInt32(LZ4F_VERSION))
        if LZ4F_isError(creation) != 0 {
            logger.critical("Couldn't create LZ4F decompression context")
        }

        self.headerRead = false
        self.source = source
        self.headerBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: LZ4FrameInputStream.headerSize)
        headerBuffer.initialize(repeating: 0, count: LZ4FrameInputStream.headerSize)
        self.scratchbuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: LZ4.defaultBufferSize)
        scratchbuffer.initialize(repeating: 0, count: LZ4.defaultBufferSize)
        self.dstSize = 0
    }

    public func readAll(sink: WriteableStream) -> Int {
        readHeader()
        var ret = 1
        var totalTransferred = 0

        // decompression
        while ret != 0 {
            // read raw bytes from source
            let rawAmountRead = source.read(scratchbuffer, length: LZ4.defaultBufferSize)
            bytesRead += rawAmountRead

            assert(rawAmountRead >= 0, "Unable to read stream")

            if rawAmountRead == 0 {
                logger.debug("Reached end of stream")
                return 0
            }

            // start & end boundaries
            let srcEndPtr = scratchbuffer.advanced(by: rawAmountRead)
            var srcStartPtr = scratchbuffer

            while srcStartPtr < srcEndPtr && ret != 0 {
                dstSize = blockSize!
                var srcSize = srcStartPtr.distance(to: srcEndPtr)

                ret = LZ4F_decompress(ctx.pointee, iteratorBuffer, &dstSize, srcStartPtr, &srcSize, nil)

                if lz4Error(ret) {
                    return totalTransferred
                }

                if dstSize != 0 {
                    // flush
                    totalTransferred += sink.write(iteratorBuffer!, length: dstSize)
                }

                // update input bounds
                srcStartPtr = srcStartPtr.advanced(by: srcSize)
            }

            assert(srcStartPtr <= srcEndPtr)

            if srcStartPtr < srcEndPtr {
                logger.warning("Unhandled trailing LZ4 frame!")
            }
        }

        return totalTransferred
    }

    public func next() -> [UInt8]? {
        readHeader()
        var ret = 1

        // decompression
        while ret != 0 {
            // read raw bytes from source
            let rawAmountRead = source.read(scratchbuffer, length: LZ4.defaultBufferSize)

            assert(rawAmountRead >= 0, "Unable to read stream")

            if rawAmountRead == 0 {
                logger.debug("Reached end of stream")
                return nil
            }

            // start & end boundaries
            let srcEndPtr = scratchbuffer.advanced(by: rawAmountRead)
            var srcStartPtr = scratchbuffer

            while srcStartPtr < srcEndPtr && ret != 0 {
                dstSize = blockSize!
                var srcSize = srcStartPtr.distance(to: srcEndPtr)

                ret = LZ4F_decompress(ctx.pointee, iteratorBuffer, &dstSize, srcStartPtr, &srcSize, nil)

                if lz4Error(ret) {
                    return nil
                }

                if dstSize != 0 {
                    // flush output- TODO
                    let range = UnsafeMutableBufferPointer(start: iteratorBuffer!, count: dstSize)
                    return Array(range)
                }

                // update input bounds
                srcStartPtr = srcStartPtr.advanced(by: srcSize)
            }

            assert(srcStartPtr <= srcEndPtr)
        }

        return nil
    }

    private func readHeader() {
        if headerRead {
            return
        }

        let rawAmountRead = source.read(headerBuffer, length: LZ4FrameInputStream.headerSize)

        assert(rawAmountRead > 0, "Not enough source data to read header")

        let frameInfo = UnsafeMutablePointer<LZ4F_frameInfo_t>.allocate(capacity: MemoryLayout<LZ4F_frameInfo_t>.size)
        let consumed = UnsafeMutablePointer<Int>.allocate(capacity: LZ4FrameInputStream.headerSize)

        defer {
            consumed.deallocate()
            frameInfo.deallocate()
        }

        consumed.initialize(to: rawAmountRead)
        let info = LZ4F_getFrameInfo(ctx.pointee, frameInfo, headerBuffer, consumed)
        if lz4Error(info) {
            logger.error("Error reading LZ4 header: \(String(cString: LZ4F_getErrorName(info)))")
            return
        }

        self.blockSize = try! LZ4FrameInputStream.getBlockSize(frameInfo.pointee)

        assert(self.blockSize! > 0)

        self.iteratorBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: blockSize!)
        iteratorBuffer!.initialize(repeating: 0, count: blockSize!)

        headerRead = true
        bytesRead += LZ4FrameInputStream.headerSize
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
        if let ib = iteratorBuffer {
            ib.deallocate()
        }
        LZ4F_freeDecompressionContext(ctx.pointee)
    }
}
