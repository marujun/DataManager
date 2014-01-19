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
@end

@interface HttpManager : NSObject

+ (HttpManager *)defaultManager;

//GET 请求
- (void)getRequestToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, NSDictionary *result))complete;
//POST 请求
- (void)postRequestToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, NSDictionary *result))complete;

/*
 files : 需要上传的文件数组，数组里为多个字典
 字典里的key: 
 1、name: 文件名称（如：demo.jpg）
 2、file: 文件   （支持四种数据类型：NSData、UIImage、NSURL、NSString）NSURL、NSString为文件路径
 3、type: 文件类型（默认：image/jpeg）
 示例： @[@{@"file":_headImg.currentBackgroundImage,@"name":@"head.jpg"}];
*/

//AFHTTPRequestOperation可以暂停、重新开启、取消 [operation pause]、[operation resume];、[operation cancel];
- (AFHTTPRequestOperation *)postRequestToUrl:(NSString *)url
                                      params:(NSDictionary *)params
                                       files:(NSArray *)files
                                    complete:(void (^)(BOOL successed, NSDictionary *result))complete;
//可以查看进度 process_block
- (AFHTTPRequestOperation *)postRequestToUrl:(NSString *)url
                                      params:(NSDictionary *)params
                                       files:(NSArray *)files
                                     process:(void (^)(double writedBytes, double totalBytes))process
                                    complete:(void (^)(BOOL successed, NSDictionary *result))complete;
/*
  filePath : 下载文件的存储路径
  response : 接口返回的不是文件而是json数据
  process  : 进度
*/
- (AFHTTPRequestOperation *)downloadFileWithUrl:(NSString *)url
                                         params:(NSDictionary *)params
                                       filePath:(NSString *)filePath
                                        process:(void (^)(double readBytes, double totalBytes))process
                                       complete:(void (^)(BOOL successed, NSDictionary *response))complete;

@end
