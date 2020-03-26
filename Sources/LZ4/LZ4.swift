//
//  lz4.swift
//  
//
//  Created by Chris Mowforth on 01/03/2020.
//

import Foundation
import Logging
import lz4Native

public final class LZ4FrameOutputStream : OutputStream {

    private let logger = Logger(label: "LZ4")

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

    public init(sink: OutputStream, bufferSize: Int = 1024 * 32) {
        self.bufferSize = bufferSize
        self.frameInfo = LZ4F_frameInfo_t(blockSizeID: LZ4F_max256KB, blockMode: LZ4F_blockLinked, contentChecksumFlag: LZ4F_noContentChecksum, frameType: LZ4F_frame, contentSize: 0, dictID: 0, blockChecksumFlag: LZ4F_noBlockChecksum)
        self.prefs = LZ4F_preferences_t(frameInfo: frameInfo, compressionLevel: 0, autoFlush: 0, favorDecSpeed: 0, reserved: (0,0,0))
        self.outBufCapacity = LZ4F_compressBound(bufferSize, &prefs)

        self.ctx = UnsafeMutablePointer<OpaquePointer?>.allocate(capacity: MemoryLayout<LZ4F_compressionContext_t>.size)
        let creation = LZ4F_createCompressionContext(ctx, UInt32(LZ4F_VERSION))
        if LZ4F_isError(creation) != 0 {
            logger.critical("Couldn't create context")
        }
        self.headerWritten = false
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

    func finish() -> Int {
        let compressed = LZ4F_compressEnd(ctx.pointee, outputBuffer, outBufCapacity, nil)
        return sink.write(outputBuffer, maxLength: compressed)
    }

    public override func close() {
        LZ4F_freeCompressionContext(ctx.pointee)
        outputBuffer.deallocate()
    }
}
