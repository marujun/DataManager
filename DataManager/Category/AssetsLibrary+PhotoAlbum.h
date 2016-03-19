//
//  AssetsLibrary+PhotoAlbum.h
//  USEvent
//
//  Created by marujun on 15/11/19.
//  Copyright © 2015年 MaRuJun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface PHPhotoLibrary (PhotoAlbum)

/** 通过名称去查找相册，如果相册不存在则新建一个相册 */
- (void)topLevelUserCollectionWithTitle:(NSString *)title completionHandler:(void(^)(PHAssetCollection *collection, NSError *error))completionHandler;

/** 通过名称去查找相册，如果相册不存在则返回nil */
- (PHAssetCollection *)existingTopLevelUserCollectionWithTitle:(NSString *)title;

/** 把图片保存到相册，如果相册不存在则新建一个相册 */
- (void)saveImage:(UIImage *)image toAlbum:(NSString *)toAlbum completionHandler:(void(^)(PHAsset *asset, NSError *error))completionHandler;

/** 把图片文件保存到相册(需提供文件路径)，如果相册不存在则新建一个相册 */
- (void)saveImageFromFilePath:(NSString *)filePath toAlbum:(NSString *)toAlbum completionHandler:(void(^)(PHAsset *asset, NSError *error))completionHandler;

@end


@interface ALAssetsLibrary (PhotoAlbum)

- (void)saveImage:(UIImage *)image toAlbum:(NSString *)toAlbum completionBlock:(void (^)(NSError* error))completionBlock;

- (void)addAssetURL:(NSURL *)assetURL toAlbum:(NSString *)toAlbum completionBlock:(void (^)(NSError* error))completionBlock;

@end
