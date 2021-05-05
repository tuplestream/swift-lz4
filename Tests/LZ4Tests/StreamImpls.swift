/*
 Copyright 2020 TupleStream OÜ

 See the LICENSE file for license information
 SPDX-License-Identifier: Apache-2.0
*/
import Foundation
import LZ4

extension BufferedMemoryStream {

    convenience init(string: String) {
        self.init(startData: string.data(using: .utf8))
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
