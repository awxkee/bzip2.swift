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

public extension Data {
    
    /**
     - Returns **Data**: compressed data
     - Throws: if error occured then throws **BZipError**
     */
    func bz2() throws -> Data {
        return try BZip2.compress(self)
    }
    
    /**
     - Returns **Data**: decompress data
     - Throws: if error occured then throws **BZipError**
     */
    func fromBZ2() throws -> Data {
        return try BZip2.decompress(self)
    }
    
}
