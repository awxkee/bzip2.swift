//
//  File.swift
//  
//
//  Created by Radzivon Bartoshyk on 26/04/2022.
//

import Foundation

struct BZip2InitializationError: Error, Equatable { }
struct BZip2CompressionError: LocalizedError, Equatable {
    let code: Int32
    var errorDescription: String? {
        "BZip2 compression error with code: \(code)"
    }
    
}
struct BZip2DecompressionError: LocalizedError, Equatable {
    let code: Int32
    var errorDescription: String? {
        "BZip2 compression error with code: \(code)"
    }
    
}

