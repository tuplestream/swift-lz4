/*
 Copyright 2020 TupleStream OÜ

 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import Foundation
import LZ4
import NIO
import NIOFoundationCompat

extension InputStream: ReadableStream {

    public func read(_ buffer: UnsafeMutablePointer<UInt8>, length: Int) -> Int {
        return self.read(buffer, maxLength: length)
    }
}

public extension ByteBuffer {

    mutating func lz4Compress() -> ByteBuffer {
        if self.readableBytes == 0 {
            return self
        }

        let sink = BufferedMemoryStream()
        let writer = LZ4FrameOutputStream(sink: sink)

        while self.readableBytes > 0 {
            let toWrite = min(self.readableBytes, writer.outputBufferCapacity)
            let _ = writer.write(self.readBytes(length: toWrite)!, length: toWrite)
        }

        writer.close()
        sink.close()
        return ByteBuffer(data: sink.internalRepresentation)
    }

    func lz4Decompress() -> ByteBuffer {
        if self.readableBytes == 0 {
            return self
        }

        let source = BufferedMemoryStream(startData: Data(buffer: self, byteTransferStrategy: .noCopy))
        let decompressor = LZ4FrameInputStream(source: source)

        defer { decompressor.close() }
        let sink = BufferedMemoryStream()

        let totalRead = decompressor.readAll(sink: sink)

        if totalRead <= 0 {
            return ByteBuffer()
        }

        return ByteBuffer(data: sink.internalRepresentation)
    }
}

public final class ByteBufferLZ4Writer {

    private let sink: BufferedMemoryStream
    private let writer: LZ4FrameOutputStream

    public init() {
        self.sink = BufferedMemoryStream()
        self.writer = LZ4FrameOutputStream(sink: sink)
    }

    public func write(_ buffer: ByteBuffer) {
        if buffer.readableBytes == 0 {
            return
        }
        let _ = writer.write(buffer.getBytes(at: 0, length: buffer.readableBytes)!, length: buffer.readableBytes)
    }

    public func getCompressed() -> ByteBuffer? {
        if writer.isClosed {
            return nil
        }

        writer.close()
        sink.close()
        return ByteBuffer(data: sink.internalRepresentation)
    }
}
