//
//  ImageCache.h
//  CoreDataUtil
//
//  Created by marujun on 14-1-18.
//  Copyright (c) 2014年 jizhi. All rights reserved.
//

#import <UIKit/UIKit.h>
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
objc_setAssociatedObject(self, &kProperty##PROPERTY_NAME , PROPERTY_NAME , OBJC_ASSOCIATION_RETAIN_NONATOMIC); \
} \

#define dispatch_main_sync_safe(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_sync(dispatch_get_main_queue(), block);\
}

#define dispatch_main_async_safe(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}

#define dispatch_main_after(delayInSeconds,block)\
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC), dispatch_get_main_queue(),block);

#define  ImageCacheIdentifyDefault    @"identify_default"
#define  ImageCacheIdentifyImprove    @"identify_improve"

@interface NSData (ImageCache)
@property(nonatomic, strong) NSNumber *disk_exist;

/* ********************----------*****************************
 1、NSData 的扩展方法，用于缓存文件；如果文件已下载则使用本地文件
 2、下载完成之后会执行回调，并可查看下载进度
 ********************----------******************************/

+ (void)dataWithURL:(NSString *)url completed:(void(^)(NSData *data))completed;

+ (void)dataWithURL:(NSString *)url
           identify:(NSString *)identify
          completed:(void(^)(NSData *data))completed;

+ (void)dataWithURL:(NSString *)url
           identify:(NSString *)identify
            process:(void (^)(int64_t readBytes, int64_t totalBytes))process
          completed:(void(^)(NSData *data))completed;

/** 通过URL获取缓存文件在本地对应的路径 */
+ (NSString *)diskCachePathWithURL:(NSString *)url;

/** 缓存文件对应的文件夹 */
+ (NSString *)diskCacheDirectory;

/** 获取图片的类型 */
+ (NSString *)contentTypeForImageData:(NSData *)data;

@end

@interface UIImage (ImageCache)
@property(nonatomic, strong) NSString *cache_url;
@property(nonatomic, strong) NSNumber *disk_exist;

/* ********************----------*****************************
 1、UIImage 的扩展方法，用于缓存图片；如果图片已下载则使用本地图片
 2、下载完成之后会执行回调，并可查看下载进度
 ********************----------******************************/

+ (void)imageWithURL:(NSString *)url completed:(void(^)(UIImage *image))completed;

+ (void)imageWithURL:(NSString *)url
            identify:(NSString *)identify
           completed:(void(^)(UIImage *image))completed;

+ (void)imageWithURL:(NSString *)url
            identify:(NSString *)identify
             process:(void (^)(int64_t readBytes, int64_t totalBytes))process
           completed:(void(^)(UIImage *image))completed;

/** 通过URL获取缓存图片在本地对应的路径 */
+ (NSString *)diskCachePathWithURL:(NSString *)url;

/** 缓存图片对应的文件夹 */
+ (NSString *)diskCacheDirectory;

/** 把图片保存到缓存文件夹 */
+ (void)storeImage:(UIImage *)image forUrl:(NSString *)url;

@end

@interface UIImageView (ImageCache)
@property(nonatomic, strong) NSString *cache_url;
@property(nonatomic, strong) NSString *cache_identify;

/** 设置UIImageView的图片的URL,下载失败设置图片为空 */
- (void)setImageWithURL:(NSString *)url;

/** 设置UIImageView的图片的URL,下载失败则使用默认图片设置 */
- (void)setImageWithURL:(NSString *)url placeholderImage:(UIImage *)placeholder;

/** 设置UIImageView的图片的URL,下载完成之后先设置图片然后执行回调函数 */
- (void)setImageWithURL:(NSString *)url completed:(void(^)(UIImage *image))completed;

/** 设置UIImageView的图片的URL,下载完成之后先设置图片然后执行回调函数,可指定该视图对应ViewController ID */
- (void)setImageWithURL:(NSString *)url identify:(NSString *)identify completed:(void(^)(UIImage *image))completed;

@end

@interface UIButton (ImageCache)
@property(nonatomic, strong) NSString *cache_url;
@property(nonatomic, strong) NSString *cache_identify;

/** 设置按钮的图片的URL,下载失败设置图片为空 */
- (void)setImageWithURL:(NSString *)url forState:(UIControlState)state;

/** 设置按钮的图片的URL,下载失败则使用默认图片设置 */
- (void)setImageWithURL:(NSString *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder;

/** 设置按钮的图片的URL,下载完成之后先设置图片然后执行回调函数 */
- (void)setImageWithURL:(NSString *)url forState:(UIControlState)state completed:(void(^)(UIImage *image))completed;

/** 设置按钮的图片的URL,下载完成之后先设置图片然后执行回调函数,可指定该视图对应ViewController ID */
- (void)setImageWithURL:(NSString *)url forState:(UIControlState)state identify:(NSString *)identify completed:(void(^)(UIImage *image))completed;

/** 设置按钮的背景图片的URL,下载失败设置图片为空 */
- (void)setBackgroundImageWithURL:(NSString *)url forState:(UIControlState)state;

/** 设置按钮的背景图片的URL,下载失败则使用默认图片设置 */
- (void)setBackgroundImageWithURL:(NSString *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder;

/** 设置按钮的背景图片的URL,下载完成之后先设置图片然后执行回调函数 */
- (void)setBackgroundImageWithURL:(NSString *)url forState:(UIControlState)state completed:(void(^)(UIImage *image))completed;

/** 设置按钮的背景图片的URL,下载完成之后先设置图片然后执行回调函数,可指定该视图对应ViewController ID */
- (void)setBackgroundImageWithURL:(NSString *)url forState:(UIControlState)state identify:(NSString *)identify completed:(void(^)(UIImage *image))completed;

@end

@interface NSFileManager (ImageCache)

/** 单个文件的大小 */
+ (long long)fileSizeAtPath:(NSString*)filePath;

/** 遍历文件夹获得文件夹大小，返回多少M */
+ (CGFloat)folderSizeAtPath:(NSString*)folderPath;

@end

@class AFHTTPRequestOperation;

@interface ImageCacheManager : NSObject

@property (strong, nonatomic, readonly) NSString *downloadingUrl;
@property (strong, nonatomic, readonly) NSURLSessionDownloadTask *requestOperation;
@property (strong, nonatomic, readonly) NSCache *imageMemoryCache;

+ (instancetype)defaultManager;

/** 获取一个view对应的identify */
+ (NSString *)identifyOfView:(UIView *)view;

/** 通过URL提高下载任务的优先级 */
- (void)bringURLToFront:(NSString *)url;

/** 通过给定的URL数组提高下载任务的优先级 */
- (void)bringURLArrayToFront:(NSArray *)urlArray;

/** 通过URL取消正在下载的任务 */
- (void)cancelLoadingURL:(NSString *)url;

/** 提高整个identify对应下载任务的优先级 */
- (void)bringIdentifyToFront:(NSString *)identify;

@end
