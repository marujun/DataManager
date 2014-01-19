//
//  ImageCache.m
//  CoreDataUtil
//
//  Created by 马汝军 on 14-1-18.
//  Copyright (c) 2014年 马汝军. All rights reserved.
//

#import "ImageCache.h"
#import "HttpManager.h"

@implementation UIImage (ImageCache)

+ (void)imageWithURL:(NSString *)url callback:(void(^)(UIImage *image))callback
{
    [self imageWithURL:url process:nil callback:callback];
}

+ (void)imageWithURL:(NSString *)url
             process:(void (^)(double readBytes, double totalBytes))process
            callback:(void(^)(UIImage *image))callback
{
    NSString *filePath = [self getImagePathWithURL:url];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        callback ? callback([UIImage imageWithContentsOfFile:filePath]) : nil;
    }else{
        [[HttpManager defaultManager] downloadFileWithUrl:url
                                                   params:nil
                                                 filePath:filePath
                                                  process:process
                                                 complete:^(BOOL successed, NSDictionary *result) {
                                                     if (callback) {
                                                         if (successed && !result) {
                                                             callback([UIImage imageWithContentsOfFile:filePath]);
                                                         }else{
                                                             callback(nil);
                                                         }
                                                     }
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
- (void)setImageURL:(NSString *)url
{
    [self setImageURL:url callback:nil];
}
- (void)setImageURL:(NSString *)url defaultImage:(UIImage *)defaultImage
{
    [UIImage imageWithURL:url callback:^(UIImage *image) {
        self.image = image?image:defaultImage;
    }];
}
- (void)setImageURL:(NSString *)url callback:(void(^)(UIImage *image))callback
{
    [UIImage imageWithURL:url callback:^(UIImage *image) {
        self.image = image;
        callback ? callback(image) : nil;
    }];
}

@end

@implementation UIButton (ImageCache)

- (void)setImageURL:(NSString *)url forState:(UIControlState)state
{
    [self setImageURL:url forState:state defaultImage:nil];
}
- (void)setImageURL:(NSString *)url forState:(UIControlState)state defaultImage:(UIImage *)defaultImage
{
    [UIImage imageWithURL:url callback:^(UIImage *image) {
        [self setImage:image?image:defaultImage forState:state];
    }];
}
- (void)setImageURL:(NSString *)url forState:(UIControlState)state callback:(void(^)(UIImage *image))callback
{
    [UIImage imageWithURL:url callback:^(UIImage *image) {
        [self setImage:image forState:state];
        callback ? callback(image) : nil;
    }];
}


- (void)setBackgroundImageURL:(NSString *)url forState:(UIControlState)state
{
    [self setBackgroundImageURL:url forState:state defaultImage:nil];
}
- (void)setBackgroundImageURL:(NSString *)url forState:(UIControlState)state defaultImage:(UIImage *)defaultImage
{
    [UIImage imageWithURL:url callback:^(UIImage *image) {
        [self setBackgroundImage:image?image:defaultImage forState:state];
    }];
}
- (void)setBackgroundImageURL:(NSString *)url forState:(UIControlState)state callback:(void(^)(UIImage *image))callback
{
    [UIImage imageWithURL:url callback:^(UIImage *image) {
        [self setBackgroundImage:image forState:state];
        callback ? callback(image) : nil;
    }];
}

@end
