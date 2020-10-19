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
