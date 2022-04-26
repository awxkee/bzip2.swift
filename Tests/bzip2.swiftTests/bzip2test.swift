//
//  File.swift
//  
//
//  Created by Radzivon Bartoshyk on 26/04/2022.
//

import Foundation
import XCTest
import bzip2_swift

class BZip2CompressionTests: XCTestCase {

    func testCompress(_ testName: String) throws {
        let bundle = """
6. Contact information
----------------------

    If you have questions, bug reports, patches etc. related to XZ Utils,
    contact Lasse Collin <lasse.collin@tukaani.org> (in Finnish or English).
    I'm sometimes slow at replying. If you haven't got a reply within two
    weeks, assume that your email has got lost and resend it or use IRC.

    You can find me also from #tukaani on Freenode; my nick is Larhzu.
    The channel tends to be pretty quiet, so just ask your question and
    someone may wake up.
"""
        let initialData = bundle.data(using: .utf8)!
        let compressedData = try BZip2.compress(initialData)
        let redecompressedData = try BZip2.decompress(compressedData)
        XCTAssertEqual(redecompressedData, initialData)
        if initialData.count > 0 { // Compression ratio is always bad for empty file.
            let compressionRatio = Double(initialData.count) / Double(compressedData.count)
            print(String(format: "BZip2.\(testName)_compressionRatio = %.3f", compressionRatio))
        }
    }
    
    func test() throws {
        try testCompress("XZ")
    }

}
