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
- (NSString *)sha1
{
    const char *ptr = [self UTF8String];
    
    int i =0;
    size_t len = strlen(ptr);
    Byte byteArray[len];
    while (i!=len)
    {
        unsigned eachChar = *(ptr + i);
        unsigned low8Bits = eachChar & 0xFF;
        
        byteArray[i] = low8Bits;
        i++;
    }
    
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(byteArray, (CC_LONG)len, digest);
    
    NSMutableString *hex = [NSMutableString string];
    for (int i=0; i<20; i++)
        [hex appendFormat:@"%02x", digest[i]];
    
    NSString *immutableHex = [NSString stringWithString:hex];
    
    return immutableHex;
}
- (NSString *)encode
{
    NSString *outputStr = (NSString *)
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                              (CFStringRef)self,
                                                              NULL,
                                                              (CFStringRef)@"!*'();:@&amp;=+$,/?%#[]",
                                                              kCFStringEncodingUTF8));
    outputStr = [outputStr stringByReplacingOccurrencesOfString:@"<null>" withString:@""];
    return outputStr;
}
- (NSString *)decode
{
    NSString *outputStr = (NSString *)
    CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(
                                                                              kCFAllocatorDefault,
                                                                              (__bridge CFStringRef)self,
                                                                              CFSTR(""),
                                                                              kCFStringEncodingUTF8));
    return outputStr;
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
        if ([NSJSONSerialization isValidJSONObject:self]) {
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:0  error:nil];
            jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }else{
             NSLog(@"data was not a proper JSON object, check All objects are NSString, NSNumber, NSArray, NSDictionary, or NSNull !!!!!");
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%s [Line %d] 对象转换成JSON字符串出错了-->\n%@",__PRETTY_FUNCTION__, __LINE__,exception);
    }
    return jsonStr;
}
@end
@implementation NSURL (HttpManager)
- (NSString *)interface
{
    if(self.port){
        return [NSString stringWithFormat:@"%@://%@:%@%@",self.scheme,self.host,self.port,self.path];
    }
    return [NSString stringWithFormat:@"%@://%@%@",self.scheme,self.host,self.path];
}
@end


@interface HttpManager ()
{
    NSDictionary *errCodeDic;
}
@end

@implementation HttpManager

- (id)init
{
    self = [super init];
	if (self) {
        NSURL *baseURL = [NSURL URLWithString:@"http://www.baidu.com"];
        _operationManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
        _operationManager.responseSerializer.acceptableContentTypes = nil;
        
        [_operationManager.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            FLOG(@"AFNetworkReachabilityStatus: %@", AFStringFromNetworkReachabilityStatus(status));
        }];
        [_operationManager.reachabilityManager startMonitoring];
        
        
        NSURLCache *urlCache = [NSURLCache sharedURLCache];
        [urlCache setMemoryCapacity:50*1024*1024];  /* 设置内存缓存的大小为50M*/
        [urlCache setDiskCapacity:200*1024*1024];   /* 设置文件缓存的大小为200M*/
        [NSURLCache setSharedURLCache:urlCache];
    }
    return self;
}

- (AFNetworkReachabilityStatus)networkStatus
{
    return [_operationManager.reachabilityManager networkReachabilityStatus];
}

+ (instancetype)defaultManager
{
    static dispatch_once_t pred = 0;
    __strong static id defaultHttpManager = nil;
    dispatch_once( &pred, ^{
        defaultHttpManager = [[self alloc] init];
    });
    return defaultHttpManager;
}

- (AFHTTPRequestOperation *)getRequestToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, id result))complete
{
    return [self requestToUrl:url method:@"GET" useCache:NO params:params complete:complete];
}

- (AFHTTPRequestOperation *)getCacheToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, id result))complete
{
    return [self requestToUrl:url method:@"GET" useCache:YES params:params complete:complete];
}

- (AFHTTPRequestOperation *)postRequestToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, id result))complete
{
    return [self requestToUrl:url method:@"POST" useCache:NO params:params complete:complete];
}

- (NSMutableURLRequest *)requestWithUrl:(NSString *)url method:(NSString *)method useCache:(BOOL)useCache params:(NSDictionary *)params
{
    NSMutableDictionary *requestParams = [params mutableCopy];
    BOOL needVerify = [self isNeedVerifyForUrl:url];
    if(needVerify){
        if (!requestParams || !requestParams[@"isCacheRequest"]) {
            requestParams = [HttpManager getRequestBodyWithParams:params];
        }
        [requestParams removeObjectForKey:@"isCacheRequest"];
    }
    
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    NSMutableURLRequest *request = [serializer requestWithMethod:method URLString:url parameters:requestParams error:nil];
    request.accessibilityValue = [@([[NSDate date] timeIntervalSince1970]) stringValue];

    [request setTimeoutInterval:20];
    if (useCache) {
        [request setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
    }
    if(needVerify){
        [self setCookieForRequest:request];
    }
    return request;
}

- (BOOL)isNeedVerifyForUrl:(NSString *)url
{
    //这在填写是否需要添加验证信息
    return false;
}

//在HTTPHeaderField里返回cookies
- (void)setCookieForRequest:(NSMutableURLRequest *)request
{
    NSArray* availableCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    NSDictionary* headers = [NSHTTPCookie requestHeaderFieldsWithCookies:availableCookies];
    [request setAllHTTPHeaderFields:headers];
}

//用于缓存的Request
- (NSMutableURLRequest *)cacheRequestUrl:(NSString *)url method:(NSString *)method useCache:(BOOL)useCache params:(NSDictionary *)params
{
    NSMutableDictionary *cacheParams = [HttpManager getRequestBodyWithParams:params];
    [cacheParams removeObjectForKey:@"time"];
    [cacheParams removeObjectForKey:@"skey"];
    [cacheParams removeObjectForKey:@"key"];
    [cacheParams removeObjectForKey:@"lat"];
    [cacheParams removeObjectForKey:@"lng"];
    [cacheParams setObject:@(true) forKey:@"isCacheRequest"];
    return [self requestWithUrl:url method:method useCache:useCache params:cacheParams];
}

- (void)localCacheToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, id result))complete
{
    NSURLRequest *cacheRequest = [self cacheRequestUrl:url method:@"GET" useCache:true params:params];
    NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:cacheRequest];
    if (cachedResponse != nil && [[cachedResponse data] length] > 0) {
        id object = cachedResponse.data;
        if ([object isKindOfClass:[NSData class]]) {
            object = [NSJSONSerialization JSONObjectWithData:object options:NSJSONReadingMutableLeaves error:nil];
        }
        if ([object isKindOfClass:[NSString class]]) {
            object = [object object];
        }
        [self handleResponse:object isCache:true complete:complete];
        
    } else {
        complete ? complete(false, nil) : nil;
    }
}

- (void)handleResponse:(NSDictionary *)response isCache:(BOOL)isCache complete:(void (^)(BOOL successed, id result))complete
{
    if (![response isKindOfClass:[NSDictionary class]]) {
        complete ? complete(false, @{}) : nil;
        return;
    }
    if (response[@"result"]) {
        if ([response[@"result"] intValue] == 1) {
            if (complete) {
                if (response[@"data"]) {
                    complete(true, response[@"data"]);
                } else {
                    complete(true, response);
                }
            }
        }
        else if(isCache){
            complete ? complete(false, response) : nil;
        }
        else{
            complete ? complete(false, response) : nil;
            
            //在这处理错误信息
        }
    } else {
        complete ? complete(true, response) : nil;
    }
}

- (AFHTTPRequestOperation *)requestToUrl:(NSString *)url method:(NSString *)method useCache:(BOOL)useCache
              params:(NSDictionary *)params complete:(void (^)(BOOL successed, id result))complete
{
    NSMutableURLRequest *request = [self requestWithUrl:url method:method useCache:useCache params:params];

    void (^requestSuccessBlock)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        [self logWithOperation:operation method:method params:params];
        
        [self handleResponse:responseObject isCache:false complete:complete];
    };
    void (^requestFailureBlock)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        [self logWithOperation:operation method:method params:params];
        complete ? complete(false,nil) : nil;
    };
    
    
    AFHTTPRequestOperation *operation = nil;
    if (useCache) {
        NSURLRequest *cacheRequest = [self cacheRequestUrl:url method:method useCache:useCache params:params];
        operation = [self cacheOperationWithRequest:request cacheRequest:cacheRequest success:requestSuccessBlock failure:requestFailureBlock];
    }else{
        operation = [_operationManager HTTPRequestOperationWithRequest:request success:requestSuccessBlock failure:requestFailureBlock];
    }
    [_operationManager.operationQueue addOperation:operation];
    
    return operation;
}

- (AFHTTPRequestOperation *)cacheOperationWithRequest:(NSURLRequest *)urlRequest
                                         cacheRequest:(NSURLRequest *)cacheRequest
                                              success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    AFHTTPRequestOperation *operation = [_operationManager HTTPRequestOperationWithRequest:urlRequest success:^(AFHTTPRequestOperation *operation, id responseObject){
        
        //store in cache
        NSData *data = [[responseObject json] dataUsingEncoding:NSUTF8StringEncoding];
        
        NSCachedURLResponse *cachedURLResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:cacheRequest];
        cachedURLResponse = [[NSCachedURLResponse alloc] initWithResponse:operation.response data:data userInfo:nil storagePolicy:NSURLCacheStorageAllowed];
        [[NSURLCache sharedURLCache] storeCachedResponse:cachedURLResponse forRequest:cacheRequest];
        
        success(operation,responseObject);
        
    }failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        if (error.code == kCFURLErrorNotConnectedToInternet || error.code == kCFURLErrorCannotConnectToHost) {
            NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:cacheRequest];
            if (cachedResponse != nil && [[cachedResponse data] length] > 0) {
                success(operation, cachedResponse.data);
            } else {
                failure(operation, error);
            }
        } else {
            failure(operation, error);
        }
    }];
    
    return operation;
}

- (void)logWithOperation:(AFHTTPRequestOperation *)operation method:(NSString *)method params:(NSDictionary *)params
{
    id response = [operation.responseString object]?:operation.responseString;
    
    if (operation.error) {
        
        if ([[method uppercaseString] isEqualToString:@"GET"]) {
            FLOG(@"get request url:  %@  ",[operation.request.URL.absoluteString decode]);
        }else{
            FLOG(@"%@ request url:  %@  \npost params:  %@\n",[method lowercaseString],[operation.request.URL.absoluteString decode],params);
        }
        
        FLOG(@"%@ responseObject:  %@",[method lowercaseString],response);
        FLOG(@"%@ error :  %@",[method lowercaseString],operation.error);
    }
    else{
        
        if ([[method uppercaseString] isEqualToString:@"GET"]) {
            FLOG(@"get request url:  %@  ",[operation.request.URL.absoluteString decode]);
        }else{
            FLOG(@"%@ request url:  %@  \npost params:  %@\n",[method lowercaseString],[operation.request.URL.absoluteString decode],params);
        }
        
        FLOG(@"%@ responseObject:  %@",[method lowercaseString],response);

        [self takesTimeWithRequest:operation.request flag:@"接口"];
    }
}

//打印每个接口的响应时间
- (void)takesTimeWithRequest:(NSURLRequest *)request flag:(NSString *)flag
{
    if (request && request.accessibilityValue) {
        NSURL *url = request.URL;
        
        double beginTime = [request.accessibilityValue doubleValue];
        double localTime = [[NSDate date] timeIntervalSince1970];
        
        FLOG(@"%@: %@    耗时：%.3f秒",flag,url.interface,localTime-beginTime);
    }
}

- (AFHTTPRequestOperation *)uploadToUrl:(NSString *)url
                                 params:(NSDictionary *)params
                                  files:(NSArray *)files
                               complete:(void (^)(BOOL successed, id result))complete
{
    return [self uploadToUrl:url params:params files:files process:nil complete:complete];
}

- (AFHTTPRequestOperation *)uploadToUrl:(NSString *)url
                                 params:(NSDictionary *)params
                                  files:(NSArray *)files
                                process:(void (^)(long writedBytes, long totalBytes))process
                               complete:(void (^)(BOOL successed, id result))complete
{
    if([self isNeedVerifyForUrl:url]){
        params = [[HttpManager getRequestBodyWithParams:params] copy];
    }
    FLOG(@"post request url:  %@  \npost params:  %@",url,params);
    
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    
    NSMutableURLRequest *request = [serializer multipartFormRequestWithMethod:@"POST" URLString:url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        for (NSDictionary *fileItem in files) {
            id value = [fileItem objectForKey:@"file"];        //支持四种数据类型：NSData、UIImage、NSURL、NSString
            NSString *name = [fileItem objectForKey:@"key"];            //文件字段的key
            NSString *fileName = [fileItem objectForKey:@"name"];       //文件名称
            NSString *mimeType = [fileItem objectForKey:@"type"];       //文件类型
            mimeType = mimeType ? mimeType : @"image/jpeg";
            name = name ? name : @"file";
            
            if ([value isKindOfClass:[NSData class]]) {
                [formData appendPartWithFileData:value name:name fileName:fileName mimeType:mimeType];
            }else if ([value isKindOfClass:[UIImage class]]) {
//                if (UIImagePNGRepresentation(value)) {  //返回为png图像。
//                    [formData appendPartWithFileData:UIImagePNGRepresentation(value) name:name fileName:fileName mimeType:mimeType];
//                }else {   //返回为JPEG图像。
                    [formData appendPartWithFileData:UIImageJPEGRepresentation(value, 0.5) name:name fileName:fileName mimeType:mimeType];
//                }
            }else if ([value isKindOfClass:[NSURL class]]) {
                [formData appendPartWithFileURL:value name:name fileName:fileName mimeType:mimeType error:nil];
            }else if ([value isKindOfClass:[NSString class]]) {
                [formData appendPartWithFileURL:[NSURL URLWithString:value]  name:name fileName:fileName mimeType:mimeType error:nil];
            }
        }
    } error:nil];
    request.accessibilityValue = [@([[NSDate date] timeIntervalSince1970]) stringValue];
    [self setCookieForRequest:request];
    
    AFHTTPRequestOperation *operation = nil;
    operation = [_operationManager HTTPRequestOperationWithRequest:request
                                                          success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                              id response = [operation.responseString object]?:operation.responseString;
                                                              FLOG(@"post responseObject:  %@",response);
                                                              
                                                              [self takesTimeWithRequest:operation.request flag:@"上传"];
                                                              if (complete) {
                                                                  [self handleResponse:responseObject isCache:false complete:complete];
                                                              }
                                                          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                              FLOG(@"post request url:  %@  \npost params:  %@",url,params);
                                                              FLOG(@"post responseObject:  %@",operation.responseString);
                                                              FLOG(@"post error :  %@",error);
                                                              
                                                              if (complete) {
                                                                  complete(false,nil);
                                                              }
                                                          }];
    
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        float progress = (float)totalBytesWritten / totalBytesExpectedToWrite;
        FLOG(@"upload process: %.0f%% (%@/%@)",100*progress,@(totalBytesWritten),@(totalBytesExpectedToWrite));
        if (process) {
            process((long)totalBytesWritten,(long)totalBytesExpectedToWrite);
        }
    }];
    [operation start];
    
    return operation;
}

- (AFHTTPRequestOperation *)downloadFromUrl:(NSString *)url
                                   filePath:(NSString *)filePath
                                   complete:(void (^)(BOOL successed, id result))complete
{
    return [self downloadFromUrl:url params:nil filePath:filePath process:nil complete:complete];
}

- (AFHTTPRequestOperation *)downloadFromUrl:(NSString *)url
                                     params:(NSDictionary *)params
                                   filePath:(NSString *)filePath
                                    process:(void (^)(long readBytes, long totalBytes))process
                                   complete:(void (^)(BOOL successed, id result))complete
{
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    NSMutableURLRequest *request = [serializer requestWithMethod:@"GET" URLString:url parameters:params error:nil];
    request.accessibilityValue = [@([[NSDate date] timeIntervalSince1970]) stringValue];
    FLOG(@"get request url: %@",[request.URL.absoluteString decode]);
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer.acceptableContentTypes = nil;
    
    NSString *tmpPath = [filePath stringByAppendingString:@".tmp"];
    operation.outputStream = [[NSOutputStream alloc] initToFileAtPath:tmpPath append:NO];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *mimeTypeArray = @[@"text/html", @"application/json"];
        NSError *moveError = nil;
        if ([mimeTypeArray containsObject:operation.response.MIMEType]) {
            //返回的是json格式数据
            NSString *string = [NSString stringWithContentsOfFile:tmpPath encoding:NSUTF8StringEncoding error:nil];
            if(string && string.length){
                responseObject = [string object];
                [self takesTimeWithRequest:operation.request flag:@"下载"];
            }
            
            [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
            FLOG(@"get responseObject:  %@",responseObject);
        }
        else{
            [self takesTimeWithRequest:operation.request flag:@"下载"];
            
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            [[NSFileManager defaultManager] moveItemAtPath:tmpPath toPath:filePath error:&moveError];
        }
        
        if (complete && !moveError) {
            complete(true,responseObject);
        }else{
            complete?complete(false,responseObject):nil;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        FLOG(@"get error :  %@",error);
        [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
        if (complete) {
            complete(false,nil);
        }
    }];
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        float progress = (float)totalBytesRead / totalBytesExpectedToRead;
        FLOG(@"download process: %.0f%% (%ld/%ld)",100*progress,(long)totalBytesRead,(long)totalBytesExpectedToRead);
        if (process) {
            process((NSUInteger)totalBytesRead,(NSUInteger)totalBytesExpectedToRead);
        }
    }];
    
    [operation start];
    
    return operation;
}

+ (NSMutableDictionary *)getRequestBodyWithParams:(NSDictionary *)params
{
    NSMutableDictionary *requestBody = [params?:@{} mutableCopy];

    NSString *versionCode = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    [requestBody setObject:@([[NSDate date] timeIntervalSince1970]*1000) forKey:@"time"];
    [requestBody setObject:@"iOS" forKey:@"platform"];
    [requestBody setObject:versionCode forKey:@"version"];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description"
                                                                     ascending:YES
                                                                      selector:@selector(compare:)];
    NSMutableString *paramString = [NSMutableString string];
    for (NSString *key in [requestBody.allKeys sortedArrayUsingDescriptors:@[sortDescriptor]]){
        id value = [requestBody objectForKey:key];
        [paramString appendFormat:@"%@=%@", key, value];
    }
    [paramString appendString:@"_!QA@WS#"];

    NSString *key = [paramString md5];
    [requestBody setObject:key forKey:@"key"];
    
    return requestBody;
}

@end
