//
//  ImageCache.m
//  CoreDataUtil
//
//  Created by marujun on 14-1-18.
//  Copyright (c) 2014年 jizhi. All rights reserved.
//

#import "ImageCache.h"
#import "HttpManager.h"

static NSMutableArray *downloadTaskArray_ic;
static NSMutableDictionary *urlClassify_ic;
static BOOL isDownloading_ic;

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
    if (!downloadTaskArray_ic) {
        downloadTaskArray_ic = [[NSMutableArray alloc] init];
    }
    if (!urlClassify_ic) {
        urlClassify_ic = [[NSMutableDictionary alloc] init];
    }
    url = url ? url : @"";
    
    NSString *filePath = [self getImagePathWithURL:url];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        UIImage *lastImage = [UIImage imageWithContentsOfFile:filePath];
        lastImage.lastCacheUrl = url;
        callback ? callback(lastImage) : nil;
    }else{
        //添加到下载列表里
        NSMutableDictionary *task = [[NSMutableDictionary alloc] init];
        [task setObject:url forKey:@"url"];
        process?[task setObject:process forKey:@"process"]:nil;
        callback?[task setObject:callback forKey:@"callback"]:nil;
        [downloadTaskArray_ic addObject:task];
        
        //按URL分类（避免同时添加多个相似下载任务）
        NSMutableArray *targetArray = urlClassify_ic[url]?:[NSMutableArray array];
        [targetArray addObject:task];
        [urlClassify_ic setObject:targetArray forKey:url];
        
        [self startDownload];
    }
}

+ (void)startDownload
{
    if (downloadTaskArray_ic.count && !isDownloading_ic) {
        NSString *url = [downloadTaskArray_ic lastObject][@"url"];
        NSString *filePath = [self getImagePathWithURL:url];
        
        isDownloading_ic = true;
        [[HttpManager defaultManager] downloadFromUrl:url
                                               params:nil
                                             filePath:filePath
                                              process:^(NSInteger readBytes, NSInteger totalBytes) {
                                                  for (NSDictionary*taskItem in urlClassify_ic[url]) {
                                                      void(^processBlock)(NSInteger, NSInteger) = taskItem[@"process"];
                                                      processBlock?processBlock(readBytes,totalBytes):nil;
                                                  }
                                              }
                                             complete:^(BOOL successed, NSDictionary *result) {
                                                 UIImage *lastImage = nil;
                                                 if (successed && !result) {
                                                     lastImage = [UIImage imageWithContentsOfFile:filePath];
                                                     lastImage.lastCacheUrl = url;
                                                 }
                                                 
                                                 for (NSDictionary*taskItem in urlClassify_ic[url]) {
                                                     void(^callbackBlock)(UIImage *) = taskItem[@"callback"];
                                                     callbackBlock?callbackBlock(lastImage):nil;
                                                     [downloadTaskArray_ic removeObject:taskItem];
                                                 }
                                                 [urlClassify_ic removeObjectForKey:url];
                                                 
                                                 isDownloading_ic = false;
                                                 [self startDownload];
                                             }];
    }
}

+ (NSString *)getImagePathWithURL:(NSString *)url
{
    //先创建个缓存文件夹
    NSString *directory = [self cacheDirectory];
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    if (![defaultManager fileExistsAtPath:directory]) {
        [defaultManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return [directory stringByAppendingPathComponent:[url md5]];
}

+ (NSString *)cacheDirectory
{
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/imgcache"];
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
    self.image = defaultImage;
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
    [self setImage:defaultImage forState:state];
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
    [self setBackgroundImage:defaultImage forState:state];
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
