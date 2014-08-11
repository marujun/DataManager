//
//  ImageCache.h
//  CoreDataUtil
//
//  Created by marujun on 14-1-18.
//  Copyright (c) 2014年 jizhi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIImageView.h>
#import <UIKit/UIButton.h>
#import <objc/runtime.h>
#include <sys/stat.h>
#include <dirent.h>

#define ADD_DYNAMIC_PROPERTY(PROPERTY_TYPE,PROPERTY_NAME,SETTER_NAME) \
@dynamic PROPERTY_NAME ; \
static char kProperty##PROPERTY_NAME; \
- ( PROPERTY_TYPE ) PROPERTY_NAME{ \
return ( PROPERTY_TYPE ) objc_getAssociatedObject(self, &(kProperty##PROPERTY_NAME ) ); \
} \
- (void) SETTER_NAME :( PROPERTY_TYPE ) PROPERTY_NAME{ \
objc_setAssociatedObject(self, &kProperty##PROPERTY_NAME , PROPERTY_NAME , OBJC_ASSOCIATION_RETAIN); \
} \

@interface UIImage (ImageCache)
@property(nonatomic, strong)NSString *lastCacheUrl;

/* ********************----------*****************************
 1、UIImage 的扩展方法，用于缓存图片；如果图片已下载则使用本地图片
 2、下载完成之后会执行回调，并可查看下载进度
 ********************----------******************************/

+ (void)imageWithURL:(NSString *)url callback:(void(^)(UIImage *image))callback;

+ (void)imageWithURL:(NSString *)url
             process:(void (^)(NSInteger readBytes, NSInteger totalBytes))process
            callback:(void(^)(UIImage *image))callback;

/*通过URL获取缓存图片在本地对应的路径*/
+ (NSString *)getImagePathWithURL:(NSString *)url;

/*缓存图片对应的文件夹*/
+ (NSString *)cacheDirectory;

@end

@interface UIImageView (ImageCache)
@property(nonatomic, strong)NSString *lastCacheUrl;

/*设置UIImageView的图片的URL,下载失败设置图片为空*/
- (void)setImageURL:(NSString *)url;

/*设置UIImageView的图片的URL,下载失败则使用默认图片设置*/
- (void)setImageURL:(NSString *)url defaultImage:(UIImage *)defaultImage;

/*设置UIImageView的图片的URL,下载完成之后先设置图片然后执行回调函数*/
- (void)setImageURL:(NSString *)url callback:(void(^)(UIImage *image))callback;

@end

@interface UIButton (ImageCache)
@property(nonatomic, strong)NSString *lastCacheUrl;

/*设置按钮的图片的URL,下载失败设置图片为空*/
- (void)setImageURL:(NSString *)url forState:(UIControlState)state;

/*设置按钮的图片的URL,下载失败则使用默认图片设置*/
- (void)setImageURL:(NSString *)url forState:(UIControlState)state defaultImage:(UIImage *)defaultImage;

/*设置按钮的图片的URL,下载完成之后先设置图片然后执行回调函数*/
- (void)setImageURL:(NSString *)url forState:(UIControlState)state callback:(void(^)(UIImage *image))callback;



/*设置按钮的背景图片的URL,下载失败设置图片为空*/
- (void)setBackgroundImageURL:(NSString *)url forState:(UIControlState)state;

/*设置按钮的背景图片的URL,下载失败则使用默认图片设置*/
- (void)setBackgroundImageURL:(NSString *)url forState:(UIControlState)state defaultImage:(UIImage *)defaultImage;

/*设置按钮的背景图片的URL,下载完成之后先设置图片然后执行回调函数*/
- (void)setBackgroundImageURL:(NSString *)url forState:(UIControlState)state callback:(void(^)(UIImage *image))callback;

@end

@interface NSData (ImageCache)

/*计算NSData的MD5值*/
- (NSString *)md5;

@end

@interface NSFileManager (ImageCache)

/*单个文件的大小*/
+ (long long)fileSizeAtPath:(NSString*)filePath;

/*遍历文件夹获得文件夹大小，返回多少M*/
+ (float)folderSizeAtPath:(NSString*)folderPath;

/*计算文件的MD5值(比较两个文件是否一样)*/
+ (NSString *)fileMd5AtPath:(NSString *)path;

@end
