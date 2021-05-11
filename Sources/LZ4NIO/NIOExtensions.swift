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

    func lz4Compress() -> ByteBuffer {
        if self.readableBytes == 0 {
            return self
        }

        let sink = BufferedMemoryStream()
        let writer = LZ4FrameOutputStream(sink: sink)

        let written = writer.write(self.getBytes(at: 0, length: self.readableBytes)!, length: self.readableBytes)
        assert(written == 7, "expected 7-byte header to be written initially")

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
//        using InputStream as source works, still not sure why
//        let source = InputStream(fileAtPath: "/Users/chris/Desktop/out.lz4")
//        source?.open()
//        let decompressor = LZ4FrameInputStream(source: source!)
        defer { decompressor.close() }
        let sink = BufferedMemoryStream()

        let totalRead = decompressor.readAll(sink: sink)

        print("TOTAL READ = \(totalRead)")

        return ByteBuffer(data: sink.internalRepresentation)
    }
}
