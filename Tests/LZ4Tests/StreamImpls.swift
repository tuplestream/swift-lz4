/*
 Copyright 2020 TupleStream OÜ

 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import Foundation
import LZ4

public class BufferedMemoryStream: BidirectionalStream, Equatable, GreedyStream {

    internal var internalRepresentation: Data = Data()
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
        precondition(sink.write(bytes, length: size) == size)
        readerIndex = size

        return size
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

// Convenience implementation for unit testing
public class StringStream: BufferedMemoryStream, CustomStringConvertible {

    public init(string: String = "") {
        super.init(startData: string.data(using: .utf8))
    }

    public var description: String {
        get {
            return String(data: internalRepresentation, encoding: .utf8)!
        }
    }
}

public class FileStream: WriteableStream {

    let fp: UnsafeMutablePointer<FILE>
    public var size = 0

    public init(filename: String) {
        self.fp = fopen(filename, "w")
    }

    public func close() {
        fclose(fp)
    }

    public func write(_ data: UnsafePointer<UInt8>, length: Int) -> Int {
        let written = fwrite(data, 1, length, fp)
        size += written
        return written
    }
}
