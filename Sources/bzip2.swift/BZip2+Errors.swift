//
//  File.swift
//  
//
//  Created by Radzivon Bartoshyk on 26/04/2022.
//

import Foundation

struct BZip2InitializationError: Error { }

public struct BZip2CannotOpenURLError: LocalizedError {
    let url: URL

    public var errorDescription: String? {
        if url.scheme != "file" {
            return "Only 'file' scheme is supported. Can't open URL: \(url.absoluteString)"
        } else {
            return "Can't open URL: \(url.absoluteString)"
        }
    }
}

struct BZip2CompressionError: LocalizedError {
    let code: Int32
    var errorDescription: String? {
        "BZip2 compression error with code: \(code)"
    }
    
}

struct BZip2UnderlyingError: LocalizedError {
    let code: Int32
    let message: String
    var errorDescription: String? {
        "BZip2 compression error with \(code): \(message)"
    }
}


struct BZip2DecompressionError: LocalizedError {
    let code: Int32
    var errorDescription: String? {
        "BZip2 compression error with code: \(code)"
    }
    
}

public struct BZip2OutOfMemoryError: LocalizedError {
    let requiredSize: Int

    public var errorDescription: String? {
        "Can't allocate memory in size: \(requiredSize)"
    }
}

public struct BZip2InvalidInputStreamError: LocalizedError {
    public var errorDescription: String? {
        "Invalid input stream was provided"
    }
}

public struct BZip2ReadingFromStreamSignalledError: LocalizedError {
    public var errorDescription: String? {
        "While reading of stream error was occur"
    }
}

public struct BZip2WritingFromStreamSignalledError: LocalizedError {
    public var errorDescription: String? {
        "While writing of stream error was occur"
    }
}
