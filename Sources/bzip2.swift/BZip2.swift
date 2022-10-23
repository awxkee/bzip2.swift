//
//  File.swift
//  
//
//  Created by Radzivon Bartoshyk on 26/04/2022.
//

import Foundation
#if SWIFT_PACKAGE
import bzip2objc
#endif

// Will return size of passed input stream for compressing or decompressing
public typealias BZip2ProgressHandler = (Int64) -> Void

public class BZip2 {
    
    public static let BZipCompressionBufferSize: Int = 1024 * 10
    public static let BZipDefaultBlockSize: UInt = 7
    public static let BZipWorkFactor: Int32 = 0

    public static func compress(data: Data, to: URL,
                                minimumReportingBlock: Int64 = 1024 * 100,
                                progressHandler: BZip2ProgressHandler? = nil) throws {
        let inputStream = InputStream(data: data)
        guard let outputStream = OutputStream(url: to, append: false) else {
            throw BZip2CannotOpenURLError(url: to)
        }
        do {
            return try compress(src: inputStream, dst: outputStream,
                                minimumReportingBlock: minimumReportingBlock,
                                progressHandler: progressHandler)
        } catch {
            inputStream.close()
            outputStream.close()
            throw error
        }
    }

    public static func compress(from: URL, to: URL,
                                minimumReportingBlock: Int64 = 1024 * 100,
                                progressHandler: BZip2ProgressHandler? = nil) throws {
        guard let inputStream = InputStream(url: from) else {
            throw BZip2CannotOpenURLError(url: from)
        }
        guard let outputStream = OutputStream(url: to, append: false) else {
            throw BZip2CannotOpenURLError(url: to)
        }
        do {
            return try compress(src: inputStream, dst: outputStream,
                                minimumReportingBlock: minimumReportingBlock,
                                progressHandler: progressHandler)
        } catch {
            inputStream.close()
            outputStream.close()
            throw error
        }
    }

    public static func decompress(src: URL,
                                  minimumReportingBlock: Int64 = 1024 * 100,
                                  progressHandler: BZip2ProgressHandler? = nil) throws -> Data {
        guard let inputStream = InputStream(url: src) else {
            throw BZip2CannotOpenURLError(url: src)
        }
        let outputStream = OutputStream(toMemory: ())
        do {
            try decompress(src: inputStream, dst: outputStream,
                           minimumReportingBlock: minimumReportingBlock,
                           progressHandler: progressHandler)
            guard let content = outputStream.property(forKey: Stream.PropertyKey.dataWrittenToMemoryStreamKey) as? NSData else {
                throw BZip2WritingFromStreamSignalledError()
            }
            return content as Data
        } catch {
            inputStream.close()
            outputStream.close()
            throw error
        }
    }

    public static func decompress(src: InputStream, dst: OutputStream,
                                  minimumReportingBlock: Int64 = 1024 * 100,
                                  progressHandler: BZip2ProgressHandler? = nil) throws {
        var stream = bz_stream()
        bzero(&stream, MemoryLayout<bz_stream>.size)
        guard let srcBuffer = malloc(BZipCompressionBufferSize) else {
            throw BZip2OutOfMemoryError(requiredSize: BZipCompressionBufferSize)
        }
        guard let dstBuffer = malloc(BZipCompressionBufferSize) else {
            throw BZip2OutOfMemoryError(requiredSize: BZipCompressionBufferSize)
        }
        src.open()
        dst.open()
        var readData = BZipCompressionBufferSize
        stream.next_in = srcBuffer.assumingMemoryBound(to: CChar.self)
        stream.next_out = dstBuffer.assumingMemoryBound(to: CChar.self)
        stream.avail_out = UInt32(BZipCompressionBufferSize)
        var status = BZ2_bzDecompressInit(&stream, 0, 0)
        guard status == BZ_OK else {
            var errnum: Int32 = status
            if let string = BZ2_bzerror(&stream, &errnum), let swiftString = String(utf8String: string) {
                throw BZip2UnderlyingError(code: status, message: swiftString)
            }
            throw BZip2InitializationError()
        }
        var compressedSize: Int64 = 0
        var lastReportedSize: Int64 = 0
        while readData == BZipCompressionBufferSize {
            readData = src.read(srcBuffer, maxLength: BZipCompressionBufferSize)
            compressedSize += Int64(readData)
            if readData == -1 {
                free(srcBuffer)
                free(dstBuffer)
                src.close()
                dst.close()
                BZ2_bzDecompressEnd(&stream)
                throw BZip2InvalidInputStreamError()
            }
            stream.avail_in = UInt32(readData)
            status = BZ2_bzDecompress(&stream)
            if status < BZ_OK {
                var errnum: Int32 = status
                if let string = BZ2_bzerror(&stream, &errnum), let swiftString = String(utf8String: string) {
                    throw BZip2UnderlyingError(code: status, message: swiftString)
                }
                throw BZip2CompressionError(code: status)
            }
            dst.write(dstBuffer, maxLength: BZip2.BZipCompressionBufferSize - Int(stream.avail_out))
            if let progressHandler, compressedSize - lastReportedSize >= minimumReportingBlock {
                lastReportedSize = compressedSize
                progressHandler(compressedSize)
            }
        }
        free(srcBuffer)
        free(dstBuffer)
        src.close()
        dst.close()
        BZ2_bzDecompressEnd(&stream)
    }


    public static func compress(src: InputStream, dst: OutputStream,
                                minimumReportingBlock: Int64 = 1024 * 100,
                                progressHandler: BZip2ProgressHandler? = nil) throws {
        var stream = bz_stream()
        bzero(&stream, MemoryLayout<bz_stream>.size)
        guard let srcBuffer = malloc(BZipCompressionBufferSize) else {
            throw BZip2OutOfMemoryError(requiredSize: BZipCompressionBufferSize)
        }
        guard let dstBuffer = malloc(BZipCompressionBufferSize) else {
            throw BZip2OutOfMemoryError(requiredSize: BZipCompressionBufferSize)
        }
        src.open()
        dst.open()
        var readData = BZipCompressionBufferSize
        stream.next_in = srcBuffer.assumingMemoryBound(to: CChar.self)
        stream.next_out = dstBuffer.assumingMemoryBound(to: CChar.self)
        stream.avail_out = UInt32(BZipCompressionBufferSize)
        var status = BZ2_bzCompressInit(&stream, Int32(BZip2.BZipDefaultBlockSize), 0, BZipWorkFactor)
        guard status == BZ_OK else {
            var errnum: Int32 = status
            if let string = BZ2_bzerror(&stream, &errnum), let swiftString = String(utf8String: string) {
                throw BZip2UnderlyingError(code: status, message: swiftString)
            }
            throw BZip2InitializationError()
        }
        var compressedSize: Int64 = 0
        var lastReportedSize: Int64 = 0
        while readData == BZipCompressionBufferSize {
            readData = src.read(srcBuffer, maxLength: BZipCompressionBufferSize)
            compressedSize += Int64(readData)
            if readData == -1 {
                free(srcBuffer)
                free(dstBuffer)
                src.close()
                dst.close()
                BZ2_bzCompressEnd(&stream)
                throw BZip2InvalidInputStreamError()
            }
            stream.avail_in = UInt32(readData)
            status = BZ2_bzCompress(&stream, readData == BZipCompressionBufferSize ? BZ_RUN : BZ_FINISH)
            if status < BZ_OK {
                var errnum: Int32 = status
                if let string = BZ2_bzerror(&stream, &errnum), let swiftString = String(utf8String: string) {
                    throw BZip2UnderlyingError(code: status, message: swiftString)
                }
                throw BZip2CompressionError(code: status)
            }
            let length = BZip2.BZipCompressionBufferSize - Int(stream.avail_out)
            dst.write(dstBuffer, maxLength: length)
            if let progressHandler, compressedSize - lastReportedSize >= minimumReportingBlock {
                lastReportedSize = compressedSize
                progressHandler(compressedSize)
            }
        }
        free(srcBuffer)
        free(dstBuffer)
        src.close()
        dst.close()
        BZ2_bzCompressEnd(&stream)
    }
    
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
            var errnum: Int32 = status
            if let string = BZ2_bzerror(&stream, &errnum), let swiftString = String(utf8String: string) {
                throw BZip2UnderlyingError(code: status, message: swiftString)
            }
            throw BZip2InitializationError()
        }
        var compressedData = Data()
        repeat {
            status = BZ2_bzCompress(&stream, stream.avail_in != 0 ? BZ_RUN : BZ_FINISH)
            if status < BZ_OK {
                var errnum: Int32 = status
                if let string = BZ2_bzerror(&stream, &errnum), let swiftString = String(utf8String: string) {
                    throw BZip2UnderlyingError(code: status, message: swiftString)
                }
                throw BZip2CompressionError(code: status)
            }
            buffer.withUnsafeBytes { pointer in
                compressedData.append(UnsafePointer<UInt8>(pointer.bindMemory(to: UInt8.self).baseAddress!), count: BZip2.BZipCompressionBufferSize - Int(stream.avail_out))
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
            var errnum: Int32 = status
            if let string = BZ2_bzerror(&stream, &errnum), let swiftString = String(utf8String: string) {
                throw BZip2UnderlyingError(code: status, message: swiftString)
            }
            throw BZip2InitializationError()
        }
        var decompressedData = Data()
        repeat {
            status = BZ2_bzDecompress(&stream)
            if status < BZ_OK {
                var errnum: Int32 = status
                if let string = BZ2_bzerror(&stream, &errnum), let swiftString = String(utf8String: string) {
                    throw BZip2UnderlyingError(code: status, message: swiftString)
                }
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
