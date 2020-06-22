//
//  LZ4Utils.swift
//  
//
//  Created by Chris Mowforth on 10/06/2020.
//

import Foundation

public final class LZ4Utils {

    public static func compressFileAndWriteToDestination(inputPath: String, outputPath: String) {
        let fileInput = InputStream(fileAtPath: inputPath)
        let fileOutput = OutputStream(toFileAtPath: outputPath, append: false)
        if let fi = fileInput, let fo = fileOutput {
            fi.open()
            fo.open()

            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: LZ4.defaultBufferSize)
            buffer.initialize(repeating: 0, count: LZ4.defaultBufferSize)

            let compressor = LZ4FrameOutputStream(sink: fo)

            var total = 0
            while true {
                let r = fi.read(buffer, maxLength: LZ4.defaultBufferSize)
                if r <= 0 {
                    break
                }
                compressor.write(buffer, maxLength: r)
            }

            fi.close()
            compressor.close()
            fo.close()
            buffer.deallocate()
        }
    }
}
