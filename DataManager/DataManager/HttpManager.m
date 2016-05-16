//
//  HttpManager.m
//  HLMagic
//
//  Created by marujun on 14-1-17.
//  Copyright (c) 2014年 jizhi. All rights reserved.
//

#import "HttpManager.h"

@implementation NSString (HttpManager)
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
        NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
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

@implementation HttpResponse

@end


@interface DMJSONResponseSerializer : AFJSONResponseSerializer
@end

@implementation DMJSONResponseSerializer

- (id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error
{
    id responseObject = [super responseObjectForResponse:response data:data error:error];
    
    if (!responseObject && *error && data && [data length]) {
        responseObject = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    
    return responseObject;
}

@end

@interface HttpManager ()

@end

@implementation HttpManager

- (id)init
{
    self = [super init];
	if (self) {
        DMJSONResponseSerializer *responseSerializer = [DMJSONResponseSerializer serializer];
        responseSerializer.acceptableContentTypes = nil;
        responseSerializer.removesKeysWithNullValues = NO;
        
        _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:nil];
        _sessionManager.responseSerializer = responseSerializer;
//        _sessionManager.securityPolicy.allowInvalidCertificates = YES; //是否允许无效证书（也就是自建的证书），默认为NO
//        _sessionManager.securityPolicy.validatesDomainName = NO; //是否需要验证域名，默认为YES； 假如证书的域名与你请求的域名不一致，需把该项设置为NO
        
        [_sessionManager.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            FLOG(@"AFNetworkReachabilityStatus: %@", AFStringFromNetworkReachabilityStatus(status));
        }];
        [_sessionManager.reachabilityManager startMonitoring];
        
        NSURLCache *urlCache = [NSURLCache sharedURLCache];
        [urlCache setMemoryCapacity:50*1024*1024];  /* 设置内存缓存的大小为50M*/
        [urlCache setDiskCapacity:200*1024*1024];   /* 设置文件缓存的大小为200M*/
        [NSURLCache setSharedURLCache:urlCache];
    }
    return self;
}

- (AFNetworkReachabilityStatus)networkStatus
{
    return [_sessionManager.reachabilityManager networkReachabilityStatus];
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

- (NSURLSessionDataTask *)getRequestToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, HttpResponse *response))complete
{
    return [self requestToUrl:url method:@"GET" useCache:NO params:params complete:complete];
}

- (NSURLSessionDataTask *)getCacheToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, HttpResponse *response))complete
{
    return [self requestToUrl:url method:@"GET" useCache:YES params:params complete:complete];
}

- (NSURLSessionDataTask *)postRequestToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, HttpResponse *response))complete
{
    return [self requestToUrl:url method:@"POST" useCache:NO params:params complete:complete];
}

- (NSURLSessionDataTask *)postCacheToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, HttpResponse *response))complete
{
    return [self requestToUrl:url method:@"POST" useCache:YES params:params complete:complete];
}

- (NSMutableURLRequest *)requestWithUrl:(NSString *)url method:(NSString *)method useCache:(BOOL)useCache params:(NSDictionary *)params
{
    NSMutableDictionary *requestParams = [params mutableCopy];
    BOOL needVerify = [[self class] isNeedVerifyForUrl:url];
    if(needVerify){
        if (!requestParams || !requestParams[@"isCacheRequest"]) {
            requestParams = [HttpManager getRequestBodyWithParams:params];
        }
        
#ifdef DEBUG
#else
        if (!requestParams[@"isCacheRequest"]) method = @"POST";
#endif
        [requestParams removeObjectForKey:@"isCacheRequest"];
    }
    
    NSString *lastUrl = [[self class] getRequestUrlWithUrl:url];
    
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    NSMutableURLRequest *request = [serializer requestWithMethod:method URLString:lastUrl parameters:requestParams error:nil];
    request.accessibilityValue = [requestParams json];
    request.accessibilityHint = [@([[NSDate date] timeIntervalSince1970]) stringValue];
    
    [request setTimeoutInterval:20];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    
    if(needVerify){
        [self setCookieForRequest:request];
    }
    return request;
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
    [cacheParams removeObjectForKey:@"lat"];
    [cacheParams removeObjectForKey:@"lng"];
    [cacheParams setObject:@(YES) forKey:@"isCacheRequest"];
    
    return [self requestWithUrl:url method:method useCache:useCache params:cacheParams];
}

- (void)dictionaryWithData:(id)data handleEmoji:(BOOL)handleEmoji complete:(void (^)(NSDictionary *object))complete
{
    __block NSDictionary *object = data;

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        NSDate *date = [NSDate date];
        if ([data isKindOfClass:[NSData class]]) {
            object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        }
        if ([data isKindOfClass:[NSString class]]) {
            object = [data object];
        }
        object = [object cleanNull];
        
        //TODO: 暂时还用不到emoji解析
//        if(handleEmoji){
//            object = [[[object json] stringByReplacingEmojiCheatCodesWithUnicode] object];
//            DLOG(@"解析网络数据耗时 %.4f 秒",[[NSDate date] timeIntervalSinceDate:date]);
//        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            complete ? complete(object?:data) : nil;
        });
    });
}

- (void)localCacheToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, HttpResponse *response))complete
{
    NSURLRequest *cacheRequest = [self cacheRequestUrl:url method:@"GET" useCache:YES params:params];
    
    NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:cacheRequest];
    if (cachedResponse != nil && [[cachedResponse data] length] > 0) {
        id object = cachedResponse.data;
        if ([object isKindOfClass:[NSData class]]) {
            object = [NSJSONSerialization JSONObjectWithData:object options:NSJSONReadingMutableLeaves error:nil];
        }
        if ([object isKindOfClass:[NSString class]]) {
            object = [object object];
        }
        
        HttpResponse *resObj = [[HttpResponse alloc] init];
        resObj.request_url = cacheRequest.URL;
        resObj.request_params = params;
        resObj.payload = object;
        resObj.is_cache = YES;
        [self handleResponse:resObj complete:complete];
        
    } else {
        HttpResponse *resObj = [[HttpResponse alloc] init];
        resObj.request_url = cacheRequest.URL;
        resObj.request_params = params;
        resObj.is_cache = YES;
        resObj.error = [NSError errorWithDomain:NSURLErrorDomain
                                           code:NSURLErrorResourceUnavailable
                                       userInfo:@{NSLocalizedDescriptionKey:@"缓存数据不存在"}];
        complete ? complete(NO, resObj) : nil;
    }
}

- (void)updateLocalCacheToUrl:(NSString *)url params:(NSDictionary *)params keyPath:(NSString *)keyPath value:(id)value
{
    if (!keyPath) return;
    
    keyPath =  [@"p." stringByAppendingString:keyPath];
    NSURLRequest *cacheRequest = [self cacheRequestUrl:url method:@"GET" useCache:YES params:params];
    
    NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:cacheRequest];
    if (cachedResponse != nil && [[cachedResponse data] length] > 0) {
        id object = cachedResponse.data;
        if ([object isKindOfClass:[NSData class]]) {
            object = [NSJSONSerialization JSONObjectWithData:object options:NSJSONReadingMutableLeaves error:nil];
        }
        
        if ([object isKindOfClass:[NSString class]]) {
            object = [object object];
        }
        
        if (object) {
            NSDictionary *newdata = [object dictionaryByReplaceingValue:value forKeyPath:keyPath];
            
            //store in cache
            NSData *data = [[newdata json] dataUsingEncoding:NSUTF8StringEncoding];
            
            NSCachedURLResponse *cachedURLResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:cacheRequest];
            cachedURLResponse = [[NSCachedURLResponse alloc] initWithResponse:cachedResponse.response data:data userInfo:nil storagePolicy:NSURLCacheStorageAllowed];
            [[NSURLCache sharedURLCache] storeCachedResponse:cachedURLResponse forRequest:cacheRequest];
        }
    }
}

- (void)handleResponse:(HttpResponse *)resObj complete:(void (^)(BOOL successed, HttpResponse *response))complete
{
    NSDictionary *response = resObj.payload;
    if (![response isKindOfClass:[NSDictionary class]]) {
        resObj.payload = nil;
        resObj.error = [NSError errorWithDomain:NSURLErrorDomain
                                           code:NSURLErrorCannotDecodeContentData
                                       userInfo:@{NSLocalizedDescriptionKey:@"返回的数据格式不正确"}];
        complete ? complete(NO, resObj) : nil;
        return;
    }
    
    if (response[@"c"]) {
        resObj.hint = response[@"h"];
        
        if (response[@"ts"] && !resObj.is_cache) {
            @try {
                double systime = [response[@"ts"] doubleValue];
                resObj.date = [NSDate dateWithTimeStamp:systime];
            }
            @catch (NSException *exception) {}
        }
        
        int httpCode = [response[@"c"] intValue];
        
        if (httpCode == 200) {
            if (complete) {
                if (response[@"p"] && [response[@"p"] isKindOfClass:[NSDictionary class]]) {
                    resObj.payload = response[@"p"];
                } else {
                    resObj.payload = @{};
                }
                complete(YES, resObj);
            }
        }
        else if(resObj.is_cache){
            resObj.error = [NSError errorWithDomain:NSURLErrorDomain
                                               code:httpCode
                                           userInfo:@{NSLocalizedDescriptionKey:response[@"m"]}];
            complete ? complete(NO, resObj) : nil;
        }
        else {
            resObj.error = [NSError errorWithDomain:NSURLErrorDomain
                                               code:httpCode
                                           userInfo:@{NSLocalizedDescriptionKey:response[@"m"]}];
            complete ? complete(NO, resObj) : nil;
        }
        
    } else {
        complete ? complete(YES, resObj) : nil;
    }
}

- (void)handleHttpResponseError:(NSError *)error useCache:(BOOL)useCache
{
    if (!useCache && error.code != NSURLErrorCancelled) {
        switch (error.code) {
            case kCFURLErrorTimedOut:
                NSLog(@"您的网络不给力哦~");
                break;
            default:
                NSLog(@"网络服务不给力哦~");
                break;
        }
    }
}

- (NSURLSessionDataTask *)requestToUrl:(NSString *)url method:(NSString *)method useCache:(BOOL)useCache
              params:(NSDictionary *)params complete:(void (^)(BOOL successed, HttpResponse *response))complete
{
    NSMutableURLRequest *request = [self requestWithUrl:url method:method useCache:useCache params:params];
    
    NSURLSessionDataTask *dataTask = nil;
    
    void (^completionHandler)(NSURLResponse *, id, NSError *) = ^(NSURLResponse *response, id responseObject, NSError *error) {
        if ([[method uppercaseString] isEqualToString:@"GET"]) {
            NSLog(@"get request url:  %@  ",[request.URL.absoluteString decode]);
        }else{
            NSLog(@"%@ request url:  %@  \npost params:  %@\n",[method lowercaseString],[request.URL.absoluteString decode],[request.accessibilityValue object]);
        }
        
        NSLog(@"%@ responseObject:  %@",[method lowercaseString],responseObject);
        
        HttpResponse *resObj = [[HttpResponse alloc] init];
        resObj.request_url = request.URL;
        resObj.request_params = [request.accessibilityValue object]?:params;
        resObj.error = error;
        
        if (error) {
            NSLog(@"%@ error :  %@",[method lowercaseString],error);
            
            complete ? complete(NO,resObj) : nil;
            
            [self handleHttpResponseError:error useCache:useCache];
        }
        else{
            [self takesTimeWithRequest:request flag:@"接口"];
            
            //已在cache中完成自带表情的解析
            [self dictionaryWithData:responseObject handleEmoji:!useCache complete:^(NSDictionary *object) {
                resObj.payload = object;
                
                NSString *flagStr = response.accessibilityValue;
                if (flagStr && [flagStr isEqualToString:@"cache_data"]) {
                    resObj.is_cache = YES;
                }
                
                [self handleResponse:resObj complete:complete];
            }];
        }
    };
    
    if (useCache) {
        NSURLRequest *cacheRequest = [self cacheRequestUrl:url method:@"GET" useCache:useCache params:params];
        dataTask = [self cacheDataTaskWithRequest:request cacheRequest:cacheRequest completionHandler:completionHandler];
    } else {
        dataTask = [_sessionManager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:completionHandler];
    }
    [dataTask resume];
    
    return dataTask;
}

- (NSURLSessionDataTask *)cacheDataTaskWithRequest:(NSURLRequest *)urlRequest
                                      cacheRequest:(NSURLRequest *)cacheRequest
                                 completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler
{
    return [_sessionManager dataTaskWithRequest:urlRequest uploadProgress:nil downloadProgress:nil
                              completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            if (error.code == kCFURLErrorNotConnectedToInternet || error.code == kCFURLErrorCannotConnectToHost) {
                NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:cacheRequest];
                if (cachedResponse != nil && [[cachedResponse data] length] > 0) {
                    NSURLResponse *response = cachedResponse.response;
                    response.accessibilityValue = @"cache_data";
                    completionHandler(response, cachedResponse.data, nil);
                } else {
                    completionHandler(nil, nil, error);
                }
            } else {
                completionHandler(nil, nil, error);
            }
        }
        else {
            //store in cache
            [self dictionaryWithData:responseObject handleEmoji:YES complete:^(NSDictionary *object) {
                NSData *data = [[object json] dataUsingEncoding:NSUTF8StringEncoding];
                
                NSCachedURLResponse *cachedURLResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:cacheRequest];
                cachedURLResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:data userInfo:nil storagePolicy:NSURLCacheStorageAllowed];
                [[NSURLCache sharedURLCache] storeCachedResponse:cachedURLResponse forRequest:cacheRequest];
                
                completionHandler(response, object, error);
            }];
        }
    }];
}

//打印每个接口的响应时间
- (void)takesTimeWithRequest:(NSURLRequest *)request flag:(NSString *)flag
{
    if (request && request.accessibilityHint) {
        NSURL *url = request.URL;
        
        double beginTime = [request.accessibilityHint doubleValue];
        double localTime = [[NSDate date] timeIntervalSince1970];
        
        NSLog(@"%@: %@    耗时：%.3f秒",flag,url.interface,localTime-beginTime);
    }
}

- (NSURLSessionUploadTask *)uploadToUrl:(NSString *)url
                                 params:(NSDictionary *)params
                                  files:(NSArray *)files
                               complete:(void (^)(BOOL successed, HttpResponse *response))complete
{
    return [self uploadToUrl:url params:params files:files process:nil complete:complete];
}

- (NSURLSessionUploadTask *)uploadToUrl:(NSString *)url
                                 params:(NSDictionary *)params
                                  files:(NSArray *)files
                                process:(void (^)(int64_t writedBytes, int64_t totalBytes))process
                               complete:(void (^)(BOOL successed, HttpResponse *response))complete
{
    if(_applicationContext.fetchingInBackground) {
        HttpResponse *resObj = [[HttpResponse alloc] init];
        resObj.error = [NSError errorWithDomain:NSURLErrorDomain
                                           code:NSURLErrorNoPermissionsToReadFile
                                       userInfo:@{NSLocalizedDescriptionKey:@"后台刷新模式时禁止上传"}];
        complete ? complete(NO, resObj) : nil;
    }
    
    NSString *lastUrl = [[self class] getRequestUrlWithUrl:url];
    if([[self class] isNeedVerifyForUrl:url]){
        params = [[HttpManager getRequestBodyWithParams:params] copy];
    }
    NSLog(@"post request url:  %@  \npost params:  %@",lastUrl,params);
    
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    
    NSMutableURLRequest *request = [serializer multipartFormRequestWithMethod:@"POST" URLString:lastUrl parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
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
                //转换为JPEG图片并把质量下降0.5
                NSData *data = UIImageJPEGRepresentation(value, 0.5);
                [formData appendPartWithFileData:data name:name fileName:fileName mimeType:mimeType];
            }else if ([value isKindOfClass:[NSURL class]]) {
                [formData appendPartWithFileURL:value name:name fileName:fileName mimeType:mimeType error:nil];
            }else if ([value isKindOfClass:[NSString class]]) {
                [formData appendPartWithFileURL:[NSURL URLWithString:value]  name:name fileName:fileName mimeType:mimeType error:nil];
            }
        }
    } error:nil];
    request.accessibilityValue = [@([[NSDate date] timeIntervalSince1970]) stringValue];
    [self setCookieForRequest:request];
    
    NSURLSessionUploadTask *uploadTask;
    
    void (^progressHandler)(NSProgress *) = ^(NSProgress * _Nonnull uploadProgress) {
        // This is not called back on the main queue.
        // You are responsible for dispatching to the main queue for UI updates
        dispatch_async(dispatch_get_main_queue(), ^{
            float progress = uploadProgress.completedUnitCount*1.f / uploadProgress.totalUnitCount;
            NSLog(@"upload process: %.0f%% (%@/%@)",100*progress,@(uploadProgress.completedUnitCount),@(uploadProgress.totalUnitCount));
            if (process) process(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
        });
    };
    
    void (^completionHandler)(NSURLResponse *, id, NSError *) = ^(NSURLResponse *response, id responseObject, NSError *error) {
        HttpResponse *resObj;
        if (complete) {
            resObj = [[HttpResponse alloc] init];
            resObj.request_url = request.URL;
            resObj.request_params = params;
            resObj.error = error;
        }
        
        if (error) {
            NSLog(@"post request url:  %@  \npost params:  %@",lastUrl,params);
            NSLog(@"post responseObject:  %@",responseObject);
            NSLog(@"post error :  %@",error);
            
            // [KeyWindow showAlertMessage:@"网络连接失败" callback:nil];
            
            if (complete) complete(NO,resObj);
            
            [self handleHttpResponseError:error useCache:NO];
            
        } else {
            NSLog(@"post responseObject:  %@",responseObject);
            
            [self takesTimeWithRequest:request flag:@"上传"];
            
            if (complete) {
                [self dictionaryWithData:responseObject handleEmoji:YES complete:^(NSDictionary *object) {
                    resObj.payload = object;
                    
                    [self handleResponse:resObj complete:complete];
                }];
            }
        }
    };
    
    
    uploadTask = [_sessionManager uploadTaskWithStreamedRequest:request progress:progressHandler completionHandler:completionHandler];
    
    [uploadTask resume];
    
    return uploadTask;
}

- (NSURLSessionDownloadTask *)downloadFromUrl:(NSString *)url
                                   filePath:(NSString *)filePath
                                   complete:(void (^)(BOOL successed, HttpResponse *response))complete
{
    return [self downloadFromUrl:url params:nil filePath:filePath process:nil complete:complete];
}

- (NSURLSessionDownloadTask *)downloadFromUrl:(NSString *)url
                                     params:(NSDictionary *)params
                                   filePath:(NSString *)filePath
                                    process:(void (^)(int64_t readBytes, int64_t totalBytes))process
                                   complete:(void (^)(BOOL successed, HttpResponse *response))complete
{
    if(_applicationContext.fetchingInBackground) {
        HttpResponse *resObj = [[HttpResponse alloc] init];
        resObj.error = [NSError errorWithDomain:NSURLErrorDomain
                                           code:NSURLErrorNoPermissionsToReadFile
                                       userInfo:@{NSLocalizedDescriptionKey:@"后台刷新模式时禁止下载"}];
        complete ? complete(NO, resObj) : nil;
    }
    
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    NSMutableURLRequest *request = [serializer requestWithMethod:@"GET" URLString:url parameters:params error:nil];
    request.accessibilityValue = [@([[NSDate date] timeIntervalSince1970]) stringValue];
    NSLog(@"get request url: %@",[request.URL.absoluteString decode]);
    
    
    NSURLSessionDownloadTask *downloadTask;
    NSString *tmpPath = [filePath stringByAppendingString:@".tmp"];
    
    void (^progressHandler)(NSProgress *) = ^(NSProgress * _Nonnull uploadProgress) {
        // This is not called back on the main queue.
        // You are responsible for dispatching to the main queue for UI updates
        dispatch_async(dispatch_get_main_queue(), ^{
            float progress = uploadProgress.completedUnitCount*1.f / uploadProgress.totalUnitCount;
            NSLog(@"download process: %.0f%% (%@/%@)",100*progress,@(uploadProgress.completedUnitCount),@(uploadProgress.totalUnitCount));
            if (process) process(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
        });
    };
    
    NSURL *(^destination)(NSURL *, NSURLResponse *) = ^NSURL * (NSURL *targetPath, NSURLResponse *response) {
        return [NSURL fileURLWithPath:tmpPath];
    };
    
    void (^completionHandler)(NSURLResponse *, id, NSError *) = ^(NSURLResponse *response, id responseObject, NSError *error) {
        
        HttpResponse *resObj;
        if (complete) {
            resObj = [[HttpResponse alloc] init];
            resObj.request_url = request.URL;
            resObj.request_params = params;
            resObj.error = error;
        }
        
        if (error) {
            [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
            if (complete) complete(NO,resObj);
        }
        else {
            NSArray *mimeTypeArray = @[@"text/html", @"application/json"];
            NSError *moveError = nil;
            
            if ([mimeTypeArray containsObject:response.MIMEType]) {
                //返回的是json格式数据
                NSString *string = [NSString stringWithContentsOfFile:tmpPath encoding:NSUTF8StringEncoding error:nil];
                if(string && string.length){
                    responseObject = [string object];
                    [self takesTimeWithRequest:request flag:@"下载"];
                }
                resObj.payload = responseObject;
                
                [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
                NSLog(@"get responseObject:  %@",responseObject);
            }
            else {
                [self takesTimeWithRequest:request flag:@"下载"];
                
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
                [[NSFileManager defaultManager] moveItemAtPath:tmpPath toPath:filePath error:&moveError];
            }
            
            if (complete && !moveError) {
                complete(YES,resObj);
            } else {
                resObj.error = [NSError errorWithDomain:NSURLErrorDomain
                                                   code:NSURLErrorResourceUnavailable
                                               userInfo:@{NSLocalizedDescriptionKey:@"移动文件失败"}];
                complete?complete(NO,resObj):nil;
            }
        }
    };
    
    downloadTask = [_sessionManager downloadTaskWithRequest:request progress:progressHandler destination:destination completionHandler:completionHandler];
    
    [downloadTask resume];
    
    return downloadTask;
}

+ (BOOL)isNeedVerifyForUrl:(NSString *)url
{
    return NO;
}

+ (NSString *)getRequestUrlWithUrl:(NSString *)url
{
    BOOL needVerify = [self isNeedVerifyForUrl:url];
    if(needVerify){
        if ([url rangeOfString:@"device_id"].length) {
            return url;
        }
        
//        NSString *lastUrl = [url stringByAppendingFormat:@"?device_id=%@",[OpenUDID value]];
//        if (_loginUser && _loginUser.uid) {
//            lastUrl = [lastUrl stringByAppendingFormat:@"&login_uid=%@",_loginUser.uid];
//        }
//        
//        return lastUrl;
    }
    
    return url;
}

+ (NSMutableDictionary *)getRequestBodyWithParams:(NSDictionary *)params
{
    params = [[[params json] stringByReplacingEmojiUnicodeWithCheatCodes] object];
    
    NSMutableDictionary *requestBody = params?[params mutableCopy]:[[NSMutableDictionary alloc] init];
    
//    double difference = [[userDefaults objectForKey:UserDefaultKey_TimeDifference] doubleValue];
//    double localTime = [[NSDate date] timeIntervalSince1970]*1000;
//    NSString *systime = [NSString stringWithFormat:@"%.0f",(localTime+difference)];
//    
//    [requestBody setObject:systime forKey:@"time"];
    [requestBody setObject:@"0" forKey:@"platform"];               //0-iOS 1-Android
    [requestBody setObject:XcodeBundleVersion forKey:@"version"];
    [requestBody setObject:@"app_store" forKey:@"distributor"];
    
    //TODO: 已放在链接地址里，详见方法：getRequestUrlWithUrl
//    [requestBody setObject:[OpenUDID value] forKey:@"device_id"];
//    if (_loginUser.uid && _loginUser.uid.length) {
//        [requestBody setObject:_loginUser.uid forKey:@"login_uid"];
//    }
    
//    if (_loginUser.session_key && _loginUser.session_key.length) {
//        [requestBody setObject:_loginUser.session_key forKey:@"session_key"];
//    }
    
    return requestBody;
}


@end
