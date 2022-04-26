//
//  File.swift
//  
//
//  Created by Radzivon Bartoshyk on 26/04/2022.
//

import Foundation
import bzip2objc

public class BZip2 {
    
    /***
     - Parameter data: Data to compress
     - Returns **Data**: compressed data
     - Throws: if error occured then throws **BZipError**
     ***/
    public static func compress(_ data: Data) throws -> Data {
        try BZipCompression.compressedData(with: data, blockSize: BZipDefaultBlockSize, workFactor: BZipDefaultWorkFactor)
    }
    
    /***
     - Parameter data: Data to decompress
     - Returns **Data**: decompress data
     - Throws: if error occured then throws **BZipError**
     ***/
    public static func decompress(_ data: Data) throws -> Data {
        try BZipCompression.decompressedData(with: data)
    }
    
}
