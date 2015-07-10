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

@interface NSData (ImageCache)

/* ********************----------*****************************
 1、NSData 的扩展方法，用于缓存文件；如果文件已下载则使用本地文件
 2、下载完成之后会执行回调，并可查看下载进度
 ********************----------******************************/

+ (void)dataWithURL:(NSString *)url callback:(void(^)(NSData *data))callback;

+ (void)dataWithURL:(NSString *)url
           identify:(NSString *)identify
           callback:(void(^)(NSData *data))callback;

+ (void)dataWithURL:(NSString *)url
           identify:(NSString *)identify
            process:(void (^)(long readBytes, long totalBytes))process
           callback:(void(^)(NSData *data))callback;

/*通过URL获取缓存文件在本地对应的路径*/
+ (NSString *)diskCachePathWithURL:(NSString *)url;

/*缓存文件对应的文件夹*/
+ (NSString *)diskCacheDirectory;

/*计算NSData的MD5值(已加上时间戳，保证相同的data在不同时刻MD5值不相同)*/
- (NSString *)md5;

@end


@interface UIImage (ImageCache)
@property(nonatomic, strong)NSString *cache_url;

/* ********************----------*****************************
 1、UIImage 的扩展方法，用于缓存图片；如果图片已下载则使用本地图片
 2、下载完成之后会执行回调，并可查看下载进度
 ********************----------******************************/

+ (void)imageWithURL:(NSString *)url callback:(void(^)(UIImage *image))callback;

+ (void)imageWithURL:(NSString *)url
            identify:(NSString *)identify
            callback:(void(^)(UIImage *image))callback;

+ (void)imageWithURL:(NSString *)url
            identify:(NSString *)identify
             process:(void (^)(long readBytes, long totalBytes))process
            callback:(void(^)(UIImage *image))callback;

/*通过URL获取缓存图片在本地对应的路径*/
+ (NSString *)diskCachePathWithURL:(NSString *)url;

/*缓存图片对应的文件夹*/
+ (NSString *)diskCacheDirectory;

/*把图片保存到缓存文件夹*/
+ (void)storeImage:(UIImage *)image forUrl:(NSString *)url;

@end

@interface UIImageView (ImageCache)
@property(nonatomic, strong) NSString *cache_url;
@property(nonatomic, strong) NSString *cache_identify;

/*设置UIImageView的图片的URL,下载失败设置图片为空*/
- (void)setImageURL:(NSString *)url;

/*设置UIImageView的图片的URL,下载失败则使用默认图片设置*/
- (void)setImageURL:(NSString *)url defaultImage:(UIImage *)defaultImage;

/*设置UIImageView的图片的URL,下载完成之后先设置图片然后执行回调函数*/
- (void)setImageURL:(NSString *)url callback:(void(^)(UIImage *image))callback;

@end

@interface UIButton (ImageCache)
@property(nonatomic, strong) NSString *cache_url;
@property(nonatomic, strong) NSString *cache_identify;

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

@interface NSFileManager (ImageCache)

/*单个文件的大小*/
+ (long long)fileSizeAtPath:(NSString*)filePath;

/*遍历文件夹获得文件夹大小，返回多少M*/
+ (float)folderSizeAtPath:(NSString*)folderPath;

/*计算文件的MD5值(已加上时间戳，保证相同的文件在不同时刻MD5值不相同)*/
+ (NSString *)fileMd5AtPath:(NSString *)path;

@end

@interface ImageCacheManager : NSObject

+ (instancetype)defaultManager;

//获取一个view对应的identify
+ (NSString *)identifyOfView:(UIView *)view;

/*自动清除6天没被查看的图片*/
- (void)autoCleanImageCache;

- (void)synchronizeVistDateList;

/*通过URL提高下载任务的优先级*/
- (void)improvePriorityForUrl:(NSString *)url;
- (void)improvePriorityForUrlArray:(NSArray *)urlArray;

/*通过URL取消正在下载的任务*/
- (void)cancelLoadingUrl:(NSString *)url;

/*提高整个identify对应下载任务的优先级*/
- (void)openOperationForIdentify:(NSString *)identify;

@end
