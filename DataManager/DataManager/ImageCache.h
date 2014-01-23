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

@interface UIImage (ImageCache)

/* ********************----------*****************************
   1、UIImage 的扩展方法，用于缓存图片；如果图片已下载则使用本地图片
   2、下载完成之后会执行回调，并可查看下载进度
 ********************----------******************************/

+ (void)imageWithURL:(NSString *)url callback:(void(^)(UIImage *image))callback;

+ (void)imageWithURL:(NSString *)url
             process:(void (^)(double readBytes, double totalBytes))process
            callback:(void(^)(UIImage *image))callback;

/*通过URL获取缓存图片在本地对应的路径*/
+ (NSString *)getImagePathWithURL:(NSString *)url;

@end

@interface UIImageView (ImageCache)

/*设置UIImageView的图片的URL,下载失败设置图片为空*/
- (void)setImageURL:(NSString *)url;

/*设置UIImageView的图片的URL,下载失败则使用默认图片设置*/
- (void)setImageURL:(NSString *)url defaultImage:(UIImage *)defaultImage;

/*设置UIImageView的图片的URL,下载完成之后先设置图片然后执行回调函数*/
- (void)setImageURL:(NSString *)url callback:(void(^)(UIImage *image))callback;

@end

@interface UIButton (ImageCache)

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
