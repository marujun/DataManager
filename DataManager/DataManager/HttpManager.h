//
//  HttpManager.h
//  HLMagic
//
//  Created by marujun on 14-1-17.
//  Copyright (c) 2014年 jizhi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import "AFNetworking.h"

@interface NSString (HttpManager)
- (NSString *)md5;
- (NSString *)sha1;
- (NSString *)encode;
- (NSString *)decode;
- (id)object;
@end

@interface NSObject (HttpManager)
- (NSString *)json;
@end

@interface NSURL (HttpManager)
/*!
 @brief 返回URL的接口名称，会去除掉URL中的参数
 */
- (NSString *)interface;
@end

@interface HttpManager : NSObject

/*!
 @property
 @brief  所有请求操作的管理器
 */
@property(nonatomic, strong) AFHTTPRequestOperationManager *operationManager;

+ (instancetype)defaultManager;

/*  -------判断当前的网络类型----------
 1、NotReachable     - 没有网络连接
 2、ReachableViaWWAN - 移动网络(2G、3G)
 3、ReachableViaWiFi - WIFI网络
 */
- (AFNetworkReachabilityStatus)networkStatus;

+ (NSMutableDictionary *)getRequestBodyWithParams:(NSDictionary *)params;

//AFHTTPRequestOperation可以暂停、重新开启、取消 [operation pause]、[operation resume];、[operation cancel];

//GET 请求
- (AFHTTPRequestOperation *)getRequestToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, id result))complete;

//读取本地缓存数据
- (void)localCacheToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, id result))complete;

//未联网时使用缓存数据
- (AFHTTPRequestOperation *)getCacheToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, id result))complete;

//POST 请求
- (AFHTTPRequestOperation *)postRequestToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, id result))complete;

/*
 files : 需要上传的文件数组，数组里为多个字典
 字典里的key:
 1、name: 文件名称（如：demo.jpg）
 2、file: 文件   （支持四种数据类型：NSData、UIImage、NSURL、NSString）NSURL、NSString为文件路径
 3、key : 文件对应字段的key（默认：file）
 4、type: 文件类型（默认：image/jpeg）
 示例： @[@{@"file":_headImg.currentBackgroundImage,@"name":@"head.jpg"}];
 */
- (AFHTTPRequestOperation *)uploadToUrl:(NSString *)url
                                 params:(NSDictionary *)params
                                  files:(NSArray *)files
                               complete:(void (^)(BOOL successed,id result))complete;


//可以查看进度 process_block
- (AFHTTPRequestOperation *)uploadToUrl:(NSString *)url
                                 params:(NSDictionary *)params
                                  files:(NSArray *)files
                                process:(void (^)(long writedBytes, long totalBytes))process
                               complete:(void (^)(BOOL successed, id result))complete;
/*
 filePath : 下载文件的存储路径
 response : 接口返回的不是文件而是json数据
 process  : 进度
 */
- (AFHTTPRequestOperation *)downloadFromUrl:(NSString *)url
                                   filePath:(NSString *)filePath
                                   complete:(void (^)(BOOL successed, id result))complete;

- (AFHTTPRequestOperation *)downloadFromUrl:(NSString *)url
                                     params:(NSDictionary *)params
                                   filePath:(NSString *)filePath
                                    process:(void (^)(long readBytes, long totalBytes))process
                                   complete:(void (^)(BOOL successed, id result))complete;

@end
