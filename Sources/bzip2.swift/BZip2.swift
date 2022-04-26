//
//  File.swift
//  
//
//  Created by Radzivon Bartoshyk on 26/04/2022.
//

import Foundation
import bzip2objc

public class BZip2 {
    
    public static let BZipCompressionBufferSize: Int = 1024
    public static let BZipDefaultBlockSize: UInt = 7
    public static let BZipWorkFactor: Int32 = 0
    
    /***
     - Parameter toCompressData: Data to compress
     - Returns **Data**: compressed data
     - Throws **BZip2InitializationError: when BZ2 initialization failed
     - Throws **BZip2CompressionError**: when compression failed
     ***/
    public static func compress(_ toCompressData: Data) throws -> Data {
        guard !toCompressData.isEmpty else {
            return Data()
        }
        var stream = bz_stream()
        bzero(&stream, MemoryLayout<bz_stream>.size)
        toCompressData.withUnsafeBytes { pointer in
            stream.next_in = UnsafeMutablePointer<CChar>(mutating: pointer.bindMemory(to: CChar.self).baseAddress!)
            stream.avail_in = UInt32(toCompressData.count)
        }
        var buffer = Data(capacity: BZip2.BZipCompressionBufferSize)
        buffer.withUnsafeMutableBytes { pointer in
            stream.next_out = UnsafeMutablePointer<CChar>(mutating: pointer.bindMemory(to: CChar.self).baseAddress!)
            stream.avail_out = UInt32(BZip2.BZipCompressionBufferSize)
        }

        var status = BZ2_bzCompressInit(&stream, Int32(BZip2.BZipDefaultBlockSize), 0, BZipWorkFactor)
        guard status == BZ_OK else {
            throw BZip2InitializationError()
        }
        var compressedData = Data()
        repeat {
            status = BZ2_bzCompress(&stream, stream.avail_in != 0 ? BZ_RUN : BZ_FINISH)
            if status < BZ_OK {
                throw BZip2CompressionError(code: status)
            }
            buffer.withUnsafeBytes { pointer in
                compressedData.append(UnsafePointer<UInt8>.init(pointer.bindMemory(to: UInt8.self).baseAddress!), count: BZip2.BZipCompressionBufferSize - Int(stream.avail_out))
            }

            buffer.withUnsafeMutableBytes { pointer in
                stream.next_out = UnsafeMutablePointer<CChar>(mutating: pointer.bindMemory(to: CChar.self).baseAddress!)
                stream.avail_out = UInt32(BZip2.BZipCompressionBufferSize)
            }
        } while status != BZ_STREAM_END
        BZ2_bzCompressEnd(&stream)
        return compressedData
    }
    
    /***
     - Parameter toDecompressData: Data to decompress
     - Returns **Data**: decompress data
     - Throws **BZip2InitializationError: when BZ2 initialization failed
     - Throws **BZip2DecompressionError**: when decompression failed
     ***/
    public static func decompress(_ toDecompressData: Data) throws -> Data {
        guard !toDecompressData.isEmpty else {
            return toDecompressData
        }
        
        var stream = bz_stream()
        bzero(&stream, MemoryLayout<bz_stream>.size)
        toDecompressData.withUnsafeBytes { pointer in
            stream.next_in = UnsafeMutablePointer<CChar>(mutating: pointer.bindMemory(to: CChar.self).baseAddress!)
            stream.avail_in = UInt32(toDecompressData.count)
        }
        var buffer = Data(capacity: BZip2.BZipCompressionBufferSize)
        buffer.withUnsafeMutableBytes { pointer in
            stream.next_out = UnsafeMutablePointer<CChar>(mutating: pointer.bindMemory(to: CChar.self).baseAddress!)
            stream.avail_out = UInt32(BZip2.BZipCompressionBufferSize)
        }
        
        var status = BZ2_bzDecompressInit(&stream, 0, 0)
        guard status == BZ_OK else {
            throw BZip2InitializationError()
        }
        var decompressedData = Data()
        repeat {
            status = BZ2_bzDecompress(&stream)
            if status < BZ_OK {
                throw BZip2DecompressionError(code: status)
            }
            buffer.withUnsafeBytes { pointer in
                let length = BZip2.BZipCompressionBufferSize - Int(stream.avail_out)
                decompressedData.append(UnsafePointer<UInt8>.init(pointer.bindMemory(to: UInt8.self).baseAddress!), count: length)
            }
            buffer.withUnsafeMutableBytes { pointer in
                stream.next_out = UnsafeMutablePointer<CChar>(mutating: pointer.bindMemory(to: CChar.self).baseAddress!)
                stream.avail_out = UInt32(BZip2.BZipCompressionBufferSize)
            }
        } while status != BZ_STREAM_END
        BZ2_bzDecompressEnd(&stream)
        return decompressedData
    }
    
}
