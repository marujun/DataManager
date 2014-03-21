//
//  ImageCache.m
//  CoreDataUtil
//
//  Created by marujun on 14-1-18.
//  Copyright (c) 2014年 jizhi. All rights reserved.
//

#import "ImageCache.h"
#import "HttpManager.h"

static NSMutableArray *downloadTaskArray_ImageCache;
static BOOL isDownloading_ImageCache;

@implementation UIImage (ImageCache)
ADD_DYNAMIC_PROPERTY(NSString *,lastCacheUrl,setLastCacheUrl);

+ (void)imageWithURL:(NSString *)url callback:(void(^)(UIImage *image))callback
{
    [self imageWithURL:url process:nil callback:callback];
}

+ (void)imageWithURL:(NSString *)url
             process:(void (^)(NSInteger readBytes, NSInteger totalBytes))process
            callback:(void(^)(UIImage *image))callback
{
    if (!downloadTaskArray_ImageCache) {
        downloadTaskArray_ImageCache = [[NSMutableArray alloc] init];
    }
    
    NSString *filePath = [self getImagePathWithURL:url];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        UIImage *lastImage = [UIImage imageWithContentsOfFile:filePath];
        lastImage.lastCacheUrl = url?url:@"";
        callback ? callback(lastImage) : nil;
    }else{
        NSMutableDictionary *task = [[NSMutableDictionary alloc] init];
        url?[task setObject:url forKey:@"url"]:nil;
        process?[task setObject:process forKey:@"process"]:nil;
        callback?[task setObject:callback forKey:@"callback"]:nil;
        [downloadTaskArray_ImageCache addObject:task];
        
        [self startDownload];
    }
}

+ (void)startDownload
{
    if (downloadTaskArray_ImageCache.count && !isDownloading_ImageCache) {
        NSDictionary *lastObj = [downloadTaskArray_ImageCache lastObject];
        [self downloadWithURL:lastObj[@"url"] process:lastObj[@"process"] callback:lastObj[@"callback"]];
    }
}

+ (void)downloadWithURL:(NSString *)url
                process:(void (^)(NSInteger readBytes, NSInteger totalBytes))process
               callback:(void(^)(UIImage *image))callback
{
    NSString *filePath = [self getImagePathWithURL:url];
    NSMutableDictionary *task = [[NSMutableDictionary alloc] init];
    url?[task setObject:url forKey:@"url"]:nil;
    process?[task setObject:process forKey:@"process"]:nil;
    callback?[task setObject:callback forKey:@"callback"]:nil;
    isDownloading_ImageCache = true;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        UIImage *lastImage = [UIImage imageWithContentsOfFile:filePath];
        lastImage.lastCacheUrl = url?url:@"";
        callback ? callback(lastImage) : nil;
        
        [downloadTaskArray_ImageCache removeObject:task];
        isDownloading_ImageCache = false;
        [self startDownload];
    }else{
        [[HttpManager defaultManager] downloadFromUrl:url
                                               params:nil
                                             filePath:filePath
                                              process:process
                                             complete:^(BOOL successed, NSDictionary *result) {
                                                 if (callback) {
                                                     if (successed && !result) {
                                                         UIImage *lastImage = [UIImage imageWithContentsOfFile:filePath];
                                                         lastImage.lastCacheUrl = url?url:@"";
                                                         callback ? callback(lastImage) : nil;
                                                     }else{
                                                         callback(nil);
                                                     }
                                                 }
                                                 [downloadTaskArray_ImageCache removeObject:task];
                                                 isDownloading_ImageCache = false;
                                                 [self startDownload];
                                             }];
    }
}

+ (NSString *)getImagePathWithURL:(NSString *)url
{
    //先创建个缓存文件夹
    NSString *directory = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/imgcache"];
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    if (![defaultManager fileExistsAtPath:directory]) {
        [defaultManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return [directory stringByAppendingPathComponent:[url md5]];
}

@end

@implementation UIImageView (ImageCache)
ADD_DYNAMIC_PROPERTY(NSString *,lastCacheUrl,setLastCacheUrl);

- (void)setImageURL:(NSString *)url
{
    [self setImageURL:url callback:nil];
}
- (void)setImageURL:(NSString *)url defaultImage:(UIImage *)defaultImage
{
    defaultImage ? self.image=defaultImage : nil;
    self.lastCacheUrl = url;
    
    [UIImage imageWithURL:url callback:^(UIImage *image) {
        if ([image.lastCacheUrl isEqualToString:self.lastCacheUrl]) {
            image ? self.image=image : nil;
        }
    }];
}
- (void)setImageURL:(NSString *)url callback:(void(^)(UIImage *image))callback
{
    self.lastCacheUrl = url;
    
    [UIImage imageWithURL:url callback:^(UIImage *image) {
        if ([image.lastCacheUrl isEqualToString:self.lastCacheUrl]) {
            image ? self.image=image : nil;
        }
        callback ? callback(image) : nil;
    }];
}

@end

@implementation UIButton (ImageCache)
ADD_DYNAMIC_PROPERTY(NSString *,lastCacheUrl,setLastCacheUrl);

- (void)setImageURL:(NSString *)url forState:(UIControlState)state
{
    [self setImageURL:url forState:state defaultImage:nil];
}
- (void)setImageURL:(NSString *)url forState:(UIControlState)state defaultImage:(UIImage *)defaultImage
{
    defaultImage ? [self setImage:defaultImage forState:state] : nil;
    self.lastCacheUrl = url;
    
    [UIImage imageWithURL:url callback:^(UIImage *image) {
        if ([image.lastCacheUrl isEqualToString:self.lastCacheUrl]) {
            image ? [self setImage:image forState:state] : nil;
        }
    }];
}
- (void)setImageURL:(NSString *)url forState:(UIControlState)state callback:(void(^)(UIImage *image))callback
{
    self.lastCacheUrl = url;
    
    [UIImage imageWithURL:url callback:^(UIImage *image) {
        if ([image.lastCacheUrl isEqualToString:self.lastCacheUrl]) {
            image ? [self setImage:image forState:state] : nil;
        }
        callback ? callback(image) : nil;
    }];
}


- (void)setBackgroundImageURL:(NSString *)url forState:(UIControlState)state
{
    [self setBackgroundImageURL:url forState:state defaultImage:nil];
}
- (void)setBackgroundImageURL:(NSString *)url forState:(UIControlState)state defaultImage:(UIImage *)defaultImage
{
    defaultImage ? [self setBackgroundImage:defaultImage forState:state] : nil;
    self.lastCacheUrl = url;
    
    [UIImage imageWithURL:url callback:^(UIImage *image) {
        if ([image.lastCacheUrl isEqualToString:self.lastCacheUrl]) {
            image ? [self setBackgroundImage:image forState:state] : nil;
        }
    }];
}
- (void)setBackgroundImageURL:(NSString *)url forState:(UIControlState)state callback:(void(^)(UIImage *image))callback
{
    self.lastCacheUrl = url;
    
    [UIImage imageWithURL:url callback:^(UIImage *image) {
        if ([image.lastCacheUrl isEqualToString:self.lastCacheUrl]) {
            image ? [self setBackgroundImage:image forState:state] : nil;
        }
        callback ? callback(image) : nil;
    }];
}

@end
