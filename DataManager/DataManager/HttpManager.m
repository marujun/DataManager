//
//  HttpManager.m
//  HLMagic
//
//  Created by marujun on 14-1-17.
//  Copyright (c) 2014年 jizhi. All rights reserved.
//

#import "HttpManager.h"

@implementation NSString (HttpManager)
- (NSString *)md5
{
    if(self == nil || [self length] == 0){
        return nil;
    }
    const char *value = [self UTF8String];
    
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, (CC_LONG)strlen(value), outputBuffer);
    
    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++){
        [outputString appendFormat:@"%02x",outputBuffer[count]];
    }
    
    return outputString;
}
- (NSString *)encode
{
    NSString *outputStr = (NSString *)
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                              (CFStringRef)self,
                                                              NULL,
                                                              NULL,
                                                              kCFStringEncodingUTF8));
    return outputStr;
}
- (NSString *)decode
{
    NSMutableString *outputStr = [NSMutableString stringWithString:self];
    [outputStr replaceOccurrencesOfString:@"+" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, [outputStr length])];
    return [outputStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}
- (id)object
{
    id object = nil;
    @try {
        NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];;
        object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    }
    @catch (NSException *exception) {
        NSLog(@"%s [Line %d] JSON字符串转换成对象出错了-->\n%@",__PRETTY_FUNCTION__, __LINE__,exception);
    }
    @finally {
    }
    return object;
}
@end
@implementation NSObject (HttpManager)
- (NSString *)json
{
    NSString *jsonStr = @"";
    @try {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:0 error:nil];
        jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    @catch (NSException *exception) {
        NSLog(@"%s [Line %d] 对象转换成JSON字符串出错了-->\n%@",__PRETTY_FUNCTION__, __LINE__,exception);
    }
    @finally {
    }
    return jsonStr;
}
@end

@implementation HttpManager

- (id)init{
    self = [super init];
	if (self) {
    }
    return self;
}


+ (HttpManager *)defaultManager
{
    static dispatch_once_t pred = 0;
    __strong static id defaultHttpManager = nil;
    dispatch_once( &pred, ^{
        
        defaultHttpManager = [[self alloc] init];
    });
    return defaultHttpManager;
}

- (void)getRequestToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, NSDictionary *result))complete
{
    params = [[HttpManager getRequestBodyWithParams:params] copy];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer.acceptableContentTypes = nil;
    
    [manager GET:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        ALog(@"get request url:  %@  \nget responseObject:  %@",[operation.request.URL.absoluteString decode], responseObject);
        if (complete) {
            complete(true,responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        ALog(@"get request url:  %@ \nget error :  %@",[operation.request.URL.absoluteString decode], error);
        if (complete) {
            complete(false,nil);
        }
    }];
}

- (void)postRequestToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, NSDictionary *result))complete
{
    params = [[HttpManager getRequestBodyWithParams:params] copy];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer.acceptableContentTypes = nil;
    
    [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        ALog(@"post request url:  %@  \npost params:  %@\npost responseObject:  %@",operation.request.URL,params,responseObject);
        if (complete) {
            complete(true,responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        ALog(@"post request url:  %@  \npost params:  %@\npost error :  %@",operation.request.URL,params,error);
        if (complete) {
            complete(false,nil);
        }
    }];
}

- (AFHTTPRequestOperation *)uploadToUrl:(NSString *)url
                                 params:(NSDictionary *)params
                                  files:(NSArray *)files
                               complete:(void (^)(BOOL successed, NSDictionary *result))complete
{
    return [self uploadToUrl:url params:params files:files process:nil complete:complete];
}

- (AFHTTPRequestOperation *)uploadToUrl:(NSString *)url
                                 params:(NSDictionary *)params
                                  files:(NSArray *)files
                                process:(void (^)(int64_t writedBytes, int64_t totalBytes))process
                               complete:(void (^)(BOOL successed, NSDictionary *result))complete
{
    params = [[HttpManager getRequestBodyWithParams:params] copy];
    ALog(@"post request url:  %@  \npost params:  %@",url,params);
    
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    
    NSMutableURLRequest *request = [serializer multipartFormRequestWithMethod:@"POST" URLString:url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        for (NSDictionary *fileItem in files) {
            id value = [fileItem objectForKey:@"file"];    //支持四种数据类型：NSData、UIImage、NSURL、NSString
            NSString *name = @"file";                                   //字段名称
            NSString *fileName = [fileItem objectForKey:@"name"];       //文件名称
            NSString *mimeType = [fileItem objectForKey:@"type"];       //文件类型
            mimeType = mimeType ? mimeType : @"image/jpeg";
            
            if ([value isKindOfClass:[NSData class]]) {
                [formData appendPartWithFileData:value name:name fileName:fileName mimeType:mimeType];
            }else if ([value isKindOfClass:[UIImage class]]) {
                [formData appendPartWithFileData:UIImageJPEGRepresentation(value, 0.5) name:name fileName:fileName mimeType:mimeType];
            }else if ([value isKindOfClass:[NSURL class]]) {
                [formData appendPartWithFileURL:value name:name fileName:fileName mimeType:mimeType error:nil];
            }else if ([value isKindOfClass:[NSString class]]) {
                [formData appendPartWithFileURL:[NSURL URLWithString:value]  name:name fileName:fileName mimeType:mimeType error:nil];
            }
        }
    } error:nil];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer.acceptableContentTypes = nil;
    
    AFHTTPRequestOperation *operation = nil;
    operation = [manager HTTPRequestOperationWithRequest:request
                                                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                     ALog(@"post responseObject:  %@",responseObject);
                                                     if (complete) {
                                                         complete(true,responseObject);
                                                     }
                                                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                     ALog(@"post error :  %@",error);
                                                     if (complete) {
                                                         complete(false,nil);
                                                     }
                                                 }];
    
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        NSLog(@"upload process: %.2lld%% (%lld/%lld)",100*totalBytesWritten/totalBytesExpectedToWrite,totalBytesWritten,totalBytesExpectedToWrite);
        if (process) {
            process(totalBytesWritten,totalBytesExpectedToWrite);
        }
    }];
    
    [operation start];
    
    return operation;
}

- (AFHTTPRequestOperation *)downloadFromUrl:(NSString *)url
                                   filePath:(NSString *)filePath
                                   complete:(void (^)(BOOL successed, NSDictionary *response))complete
{
    return [self downloadFromUrl:url params:nil filePath:filePath process:nil complete:complete];
}

- (AFHTTPRequestOperation *)downloadFromUrl:(NSString *)url
                                     params:(NSDictionary *)params
                                   filePath:(NSString *)filePath
                                    process:(void (^)(int64_t readBytes, int64_t totalBytes))process
                                   complete:(void (^)(BOOL successed, NSDictionary *response))complete
{
    params = [[HttpManager getRequestBodyWithParams:params] copy];
    
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    NSMutableURLRequest *request = [serializer requestWithMethod:@"GET" URLString:url parameters:params error:nil];
    ALog(@"get request url: %@",[request.URL.absoluteString decode]);
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer.acceptableContentTypes = nil;
    
    NSString *tmpPath = [filePath stringByAppendingString:@".tmp"];
    operation.outputStream=[[NSOutputStream alloc] initToFileAtPath:tmpPath append:NO];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *mimeTypeArray = @[@"text/html", @"application/json"];
        NSError *moveError = nil;
        if ([mimeTypeArray containsObject:operation.response.MIMEType]) {
            //返回的是json格式数据
            responseObject = [NSData dataWithContentsOfFile:tmpPath];
            responseObject = [NSJSONSerialization JSONObjectWithData:responseObject options:2 error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
            ALog(@"get responseObject:  %@",responseObject);
        }else{
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            [[NSFileManager defaultManager] moveItemAtPath:tmpPath toPath:filePath error:&moveError];
        }
        
        if (complete && !moveError) {
            complete(true,responseObject);
        }else{
            complete?complete(false,responseObject):nil;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        ALog(@"get error :  %@",error);
        [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
        if (complete) {
            complete(false,nil);
        }
    }];
    
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        NSLog(@"download process: %.2lld%% (%lld/%lld)",100*totalBytesRead/totalBytesExpectedToRead,totalBytesRead,totalBytesExpectedToRead);
        if (process) {
            process(totalBytesRead,totalBytesExpectedToRead);
        }
    }];
    
    [operation start];
    
    return operation;
}

+ (NSMutableDictionary *)getRequestBodyWithParams:(NSDictionary *)params
{
    NSMutableDictionary *requestBody = params?[params mutableCopy]:[[NSMutableDictionary alloc] init];
    
    for (NSString *key in [params allKeys]){
        id value = [params objectForKey:key];
        if ([value isKindOfClass:[NSDate class]]) {
            [requestBody setValue:@([value timeIntervalSince1970]*1000) forKey:key];
        }
        if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]]) {
            [requestBody setValue:[value json] forKey:key];
        }
    }
    
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:@"token"];
    if (token){
        [requestBody setObject:token forKey:@"token"];
    }
    [requestBody setObject:@"ios" forKey:@"genus"];
    
    return requestBody;
}

+ (NetworkStatus)networkStatus
{
    Reachability *reachability = [Reachability reachabilityWithHostname:@"www.apple.com"];
    // NotReachable     - 没有网络连接
    // ReachableViaWWAN - 移动网络(2G、3G)
    // ReachableViaWiFi - WIFI网络
    return [reachability currentReachabilityStatus];
}

@end
