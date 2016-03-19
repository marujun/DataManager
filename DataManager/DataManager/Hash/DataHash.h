//
//  DataHash.h
//  HappyIn
//
//  Created by marujun on 16/3/10.
//  Copyright © 2016年 MaRuJun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface NSData (DataHash)

- (NSString *)md5;

- (NSString *)sha1;

- (NSString *)sha512;

- (NSString *)crc32;

@end

@interface NSString (DataHash)

- (NSString *)md5;

- (NSString *)sha1;

- (NSString *)sha512;

- (NSString *)crc32;

@end

@interface NSFileManager (DataHash)

+ (NSString *)fileMD5AtPath:(NSString *)filePath;

+ (NSString *)fileSHA1AtPath:(NSString *)filePath;

+ (NSString *)fileSHA512AtPath:(NSString *)filePath;

+ (NSString *)fileCRC32AtPath:(NSString *)filePath;

@end

@interface ALAssetRepresentation (DataHash)

- (NSString *)md5;

- (NSString *)sha1;

- (NSString *)sha512;

- (NSString *)crc32;

@end
