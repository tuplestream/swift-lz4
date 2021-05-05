/*
 Copyright 2020 TupleStream OÜ

 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import Foundation

// MARK: Protocols
public protocol ByteStream {

    func close()
}

public extension ByteStream {

    func close() {
        // no-op default implementation
    }
}

public protocol ReadableStream: ByteStream {

    func read(_ buffer: UnsafeMutablePointer<UInt8>, length: Int) -> Int
}

public protocol GreedyStream {

    func readAll(sink: WriteableStream) -> Int
}

public protocol WriteableStream: ByteStream {

    func write(_ data: UnsafePointer<UInt8>, length: Int) -> Int
}

public typealias BidirectionalStream = ReadableStream & WriteableStream

public class BufferedMemoryStream: BidirectionalStream, Equatable, GreedyStream {

    public var internalRepresentation: Data = Data()
    private var readerIndex: Int = 0

    public init(startData: Data? = nil) {
        if let data = startData {
            self.internalRepresentation = data
        }
    }

    public func write(_ data: UnsafePointer<UInt8>, length: Int) -> Int {
        internalRepresentation += Data(bytes: data, count: length)
        return length
    }

    public func read(_ buffer: UnsafeMutablePointer<UInt8>, length: Int) -> Int {
        if readerIndex == size {
            return 0 // EOF
        }

        let maxTransferrable = min(size - readerIndex, length)
        internalRepresentation.copyBytes(to: buffer, from: readerIndex..<maxTransferrable)
        readerIndex += maxTransferrable

        return maxTransferrable
    }

    public func readAll(sink: WriteableStream) -> Int {
        let bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: internalRepresentation.count)
        defer { bytes.deallocate() }

        internalRepresentation.copyBytes(to: bytes, count: size)
        let written = sink.write(bytes, length: size)
        assert(written == size)
        return written
    }

    public var size: Int {
        get {
            return internalRepresentation.count
        }
    }

    public static func == (lhs: BufferedMemoryStream, rhs: BufferedMemoryStream) -> Bool {
        return lhs.internalRepresentation == rhs.internalRepresentation
    }
}
