//
//  BZipCompression.m
//  
//
//  Created by Radzivon Bartoshyk on 26/04/2022.
//

#import "BZipCompression.h"

NSString * const BZipErrorDomain = @"com.radzivon.bartoshyk";
NSUInteger const BZipCompressionBufferSize = 1024;
NSInteger const BZipDefaultBlockSize = 7;
NSInteger const BZipDefaultWorkFactor = 0;

@implementation BZipCompression

+ (NSData * _Nullable)compressedDataWithData:(NSData * _Nonnull )data blockSize:(NSInteger)blockSize workFactor:(NSInteger)workFactor error:(NSError **)error
{
    if (!data) {
        if (error) {
            *error = [NSError errorWithDomain:BZipErrorDomain code:BZipErrorNilInputDataError userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Input data cannot be `nil`.", nil) }];
        }
        return nil;
    }
    if ([data length] == 0) return data;
    
    bz_stream stream;
    bzero(&stream, sizeof(stream));
    stream.next_in = (char *)[data bytes];
    stream.avail_in = (unsigned int)[data length];
    
    NSMutableData *buffer = [NSMutableData dataWithLength:BZipCompressionBufferSize];
    stream.next_out = [buffer mutableBytes];
    stream.avail_out = BZipCompressionBufferSize;
    
    int bzret;
    bzret = BZ2_bzCompressInit(&stream, (int)blockSize, 0, (int)workFactor);
    if (bzret != BZ_OK) {
        if (error) {
            *error = [NSError errorWithDomain:BZipErrorDomain code:bzret userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"`BZ2_bzCompressInit` failed", nil) }];
        }
        return nil;
    }
    
    NSMutableData *compressedData = [NSMutableData data];
    do {
        bzret = BZ2_bzCompress(&stream, (stream.avail_in) ? BZ_RUN : BZ_FINISH);
        if (bzret < BZ_OK) {
            if (error) {
                *error = [NSError errorWithDomain:BZipErrorDomain code:bzret userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"`BZ2_bzCompress` failed", nil) }];
            }
            return nil;
        }
        
        [compressedData appendBytes:[buffer bytes] length:(BZipCompressionBufferSize - stream.avail_out)];
        stream.next_out = [buffer mutableBytes];
        stream.avail_out = BZipCompressionBufferSize;
    } while (bzret != BZ_STREAM_END);
    
    BZ2_bzCompressEnd(&stream);
    
    return compressedData;
}

+ (NSData *)decompressedDataWithData:(NSData *)data error:(NSError **)error
{
    if (!data) {
        if (error) {
            *error = [NSError errorWithDomain:BZipErrorDomain code:BZipErrorNilInputDataError userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Input data cannot be `nil`.", nil) }];
        }
        return nil;
    }
    if ([data length] == 0) return data;
    
    bz_stream stream;
    bzero(&stream, sizeof(stream));
    stream.next_in = (char *)[data bytes];
    stream.avail_in = (unsigned int)[data length];
    
    NSMutableData *buffer = [NSMutableData dataWithLength:BZipCompressionBufferSize];
    stream.next_out = [buffer mutableBytes];
    stream.avail_out = BZipCompressionBufferSize;
    
    int bzret;
    bzret = BZ2_bzDecompressInit(&stream, 0, NO);
    if (bzret != BZ_OK) {
        if (error) {
            *error = [NSError errorWithDomain:BZipErrorDomain code:bzret userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"`BZ2_bzDecompressInit` failed", nil) }];
        }
        return nil;
    }
    
    NSMutableData *decompressedData = [NSMutableData data];
    do {
        bzret = BZ2_bzDecompress(&stream);
        if (bzret < BZ_OK) {
            if (error) {
                *error = [NSError errorWithDomain:BZipErrorDomain code:bzret userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"`BZ2_bzDecompress` failed", nil) }];
            }
            return nil;
        }
        
        [decompressedData appendBytes:[buffer bytes] length:(BZipCompressionBufferSize - stream.avail_out)];
        stream.next_out = [buffer mutableBytes];
        stream.avail_out = BZipCompressionBufferSize;
    } while (bzret != BZ_STREAM_END);
    
    BZ2_bzDecompressEnd(&stream);
    
    return decompressedData;
}

+ (void* _Nullable)decompressFileAtPath:(NSString *)sourcePath toFileAtPath:(NSString *)destinationPath progress:(NSProgress **)progress error:(NSError **)error
{
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:sourcePath isDirectory:&isDirectory]) {
        *error = [NSError errorWithDomain:BZipErrorDomain code:BZipErrorInvalidSourcePath userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Decompression failed because the source path given does not exist.", nil) }];
        return;
    }
    if (isDirectory) {
        *error = [NSError errorWithDomain:BZipErrorDomain code:BZipErrorInvalidSourcePath userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Decompression failed because the source path given is a directory.", nil) }];
        return;
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:destinationPath isDirectory:&isDirectory]) {
        *error = [NSError errorWithDomain:BZipErrorDomain code:BZipErrorInvalidDestinationPath userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Decompression failed because the destination path given already exists.", nil) }];
        return;
    }
    if (isDirectory) {
        *error = [NSError errorWithDomain:BZipErrorDomain code:BZipErrorInvalidDestinationPath userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Decompression failed because the destination path given is a directory.", nil) }];
        return;
    }
    
    NSError *attributesError = nil;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:sourcePath error:&attributesError];
    if (!attributes) {
        *error = [NSError errorWithDomain:BZipErrorDomain code:BZipErrorFileManagementFailure userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Decompression failed because the size of the source path .", nil), NSUnderlyingErrorKey: attributesError }];
        return;
    }
    unsigned long long sourceFileSize = [[attributes objectForKey:NSFileSize] unsignedLongLongValue];
    
    BOOL success = [[NSFileManager defaultManager] createFileAtPath:destinationPath contents:nil attributes:nil];
    if (!success) {
        *error = [NSError errorWithDomain:BZipErrorDomain code:BZipErrorUnableToCreateDestinationPath userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Decompression failed because the destination path could not be created.", nil) }];
        return;
    }
    
    NSProgress *decompressionProgress = [NSProgress progressWithTotalUnitCount:sourceFileSize];
    decompressionProgress.kind = NSProgressKindFile;
    decompressionProgress.cancellable = YES;
    decompressionProgress.pausable = NO;
    if (progress) {
        *progress = decompressionProgress;
    }
    
    
    unsigned long long totalBytesProcessed = 0;
    
    bz_stream stream;
    bzero(&stream, sizeof(stream));
    NSFileHandle *inputFileHandle = [NSFileHandle fileHandleForReadingAtPath:sourcePath];
    if (!inputFileHandle) {
        *error = [NSError errorWithDomain:BZipErrorDomain code:BZipErrorInvalidSourcePath userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Decompression failed because a readable file handle for the source path could not be created.", nil) }];
        return;
    }
    
    NSFileHandle *outputFileHandle = [NSFileHandle fileHandleForWritingAtPath:destinationPath];
    if (!outputFileHandle) {
        *error = [NSError errorWithDomain:BZipErrorDomain code:BZipErrorInvalidDestinationPath userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Decompression failed because a writable file handle for the destination path could not be created.", nil) }];
        return;
    }
    
    NSMutableData *compressedDataBuffer = [NSMutableData new];
    int bzret = BZ_OK;
    bzret = BZ2_bzDecompressInit(&stream, 0, NO);
    if (bzret != BZ_OK) {
        *error = [NSError errorWithDomain:BZipErrorDomain code:bzret userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Decompression failed because `BZ2_bzDecompressInit` returned an error.", nil) }];
        return;
    } else {
        while (true) {
            if (decompressionProgress.isCancelled) {
                *error = [NSError errorWithDomain:BZipErrorDomain code:BZipErrorOperationCancelled userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Decompression failed because the operation was cancelled.", nil) }];
                break;
            }
            NSData *inputChunk = [inputFileHandle readDataOfLength:BZipCompressionBufferSize];
            if ([inputChunk length] == 0) {
                // No data left to read -- all done
                break;
            }
            [compressedDataBuffer appendData:inputChunk];
            
            totalBytesProcessed += [inputChunk length];
            [decompressionProgress setCompletedUnitCount:totalBytesProcessed];
            stream.next_in = (char *)[compressedDataBuffer bytes];
            stream.avail_in = (unsigned int)[compressedDataBuffer length];
            
            NSMutableData *decompressedDataBuffer = [NSMutableData dataWithLength:BZipCompressionBufferSize];
            while (true) {
                stream.next_out = [decompressedDataBuffer mutableBytes];
                stream.avail_out = BZipCompressionBufferSize;
                
                bzret = BZ2_bzDecompress(&stream);
                if (bzret < BZ_OK) {
                    *error = [NSError errorWithDomain:BZipErrorDomain code:bzret userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Decompression failed because `BZ2_bzDecompress` returned an error.", nil) }];
                    break;
                }
                NSData *decompressedData = [NSMutableData dataWithBytes:[decompressedDataBuffer bytes] length:(BZipCompressionBufferSize - stream.avail_out)];
                [outputFileHandle writeData:decompressedData];
                
                if ((BZipCompressionBufferSize - stream.avail_out) == 0) {
                    // Save the remaining bits for the next iteration
                    [compressedDataBuffer setData:[NSData dataWithBytes:stream.next_in length:stream.avail_in]];
                    break;
                }
                
                if (bzret == BZ_STREAM_END) {
                    break;
                }
            }
            
            if (bzret == BZ_STREAM_END || error) {
                break;
            }
        }
        
        BZ2_bzDecompressEnd(&stream);
    }
    
    [inputFileHandle closeFile];
    [outputFileHandle closeFile];
    
    if (error) {
        [[NSFileManager defaultManager] removeItemAtPath:destinationPath error:nil];
    }
}

@end
