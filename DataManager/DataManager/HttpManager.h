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

@interface HttpResponse : DBObject

@property (nonatomic, assign) BOOL is_cache;                   //是否是缓存数据

@property (nonatomic, strong) NSURL *request_url;              //请求的链接
@property (nonatomic, strong) NSDictionary *request_params;    //请求的参数

@property (nonatomic, strong) id payload;                      //返回的结果
@property (nonatomic, strong) NSString *hint;                  //提示语
@property (nonatomic, strong) NSError *error;                  //错误信息
@property (nonatomic, strong) NSDate *date;                    //返回结果的时间

@property (nonatomic, strong) id extra;                         //用户自定义的额外信息

@end

@interface HttpManager : NSObject

/*!
 @property
 @brief  所有请求操作的管理器
 */
@property(nonatomic, strong, readonly) AFHTTPSessionManager *sessionManager;

+ (instancetype)defaultManager;

/*  -------判断当前的网络类型----------
 1、NotReachable     - 没有网络连接
 2、ReachableViaWWAN - 移动网络(2G、3G)
 3、ReachableViaWiFi - WIFI网络
 */
- (AFNetworkReachabilityStatus)networkStatus;

+ (NSMutableDictionary *)getRequestBodyWithParams:(NSDictionary *)params;

//AFHTTPRequestOperation可以暂停、重新开启、取消 [operation pause]、[operation resume]、[operation cancel];

/** GET 请求 */
- (NSURLSessionDataTask *)getRequestToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, HttpResponse *response))complete;

/** 读取本地缓存数据 */
- (void)localCacheToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, HttpResponse *response))complete;

/** 通过keypath更新本地缓存数据，删除某个节点数据value赋值为nil；例：user.hobby[1].title */
- (void)updateLocalCacheToUrl:(NSString *)url params:(NSDictionary *)params keyPath:(NSString *)keyPath value:(id)value;

/** GET 请求并添加到缓存，未联网时使用缓存数据 */
- (NSURLSessionDataTask *)getCacheToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, HttpResponse *response))complete;

/** POST 请求 */
- (NSURLSessionDataTask *)postRequestToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, HttpResponse *response))complete;

/** POST 请求并添加到缓存，未联网时使用缓存数据 */
- (NSURLSessionDataTask *)postCacheToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, HttpResponse *response))complete;

/*
 files : 需要上传的文件数组，数组里为多个字典
 字典里的key:
 1、name: 文件名称（如：demo.jpg）
 2、file: 文件   （支持四种数据类型：NSData、UIImage、NSURL、NSString）NSURL、NSString为文件路径
 3、key : 文件对应字段的key（默认：file）
 4、type: 文件类型（默认：image/jpeg）
 示例： @[@{@"file":_headImg.currentBackgroundImage,@"name":@"head.jpg"}];
 */
- (NSURLSessionUploadTask *)uploadToUrl:(NSString *)url
                                 params:(NSDictionary *)params
                                  files:(NSArray *)files
                               complete:(void (^)(BOOL successed, HttpResponse *response))complete;


//可以查看进度 process_block
- (NSURLSessionUploadTask *)uploadToUrl:(NSString *)url
                                 params:(NSDictionary *)params
                                  files:(NSArray *)files
                                process:(void (^)(int64_t writedBytes, int64_t totalBytes))process
                               complete:(void (^)(BOOL successed, HttpResponse *response))complete;
/**
 filePath : 下载文件的存储路径
 response : 接口返回的不是文件而是json数据
 process  : 进度
 */
- (NSURLSessionDownloadTask *)downloadFromUrl:(NSString *)url
                                   filePath:(NSString *)filePath
                                   complete:(void (^)(BOOL successed, HttpResponse *response))complete;

- (NSURLSessionDownloadTask *)downloadFromUrl:(NSString *)url
                                     params:(NSDictionary *)params
                                   filePath:(NSString *)filePath
                                    process:(void (^)(int64_t readBytes, int64_t totalBytes))process
                                   complete:(void (^)(BOOL successed, HttpResponse *response))complete;

@end
