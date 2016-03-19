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

@interface HttpManager ()

@end

@implementation HttpManager

- (id)init
{
    self = [super init];
	if (self) {
        NSURL *baseURL = [NSURL URLWithString:@"http://www.baidu.com"];
        _operationManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
        _operationManager.responseSerializer.acceptableContentTypes = nil;
        
//        _operationManager.securityPolicy.allowInvalidCertificates = YES; //是否允许无效证书（也就是自建的证书），默认为NO
//        _operationManager.securityPolicy.validatesDomainName = NO; //是否需要验证域名，默认为YES； 假如证书的域名与你请求的域名不一致，需把该项设置为NO
        
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

- (AFHTTPRequestOperation *)getRequestToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, HttpResponse *response))complete
{
    return [self requestToUrl:url method:@"GET" useCache:NO params:params complete:complete];
}

- (AFHTTPRequestOperation *)getCacheToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, HttpResponse *response))complete
{
    return [self requestToUrl:url method:@"GET" useCache:YES params:params complete:complete];
}

- (AFHTTPRequestOperation *)postRequestToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, HttpResponse *response))complete
{
    return [self requestToUrl:url method:@"POST" useCache:NO params:params complete:complete];
}

- (AFHTTPRequestOperation *)postCacheToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, HttpResponse *response))complete
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
        if (!requestParams[@"isCacheRequest"] && ![MCLog defaultManager].is_debug) method = @"POST";
#endif
        [requestParams removeObjectForKey:@"isCacheRequest"];
    }
    
    NSString *lastUrl = [[self class] getRequestUrlWithUrl:url];
    
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    NSMutableURLRequest *request = [serializer requestWithMethod:method URLString:lastUrl parameters:requestParams error:nil];
    request.accessibilityValue = [requestParams json];
    request.accessibilityHint = [@([[NSDate date] timeIntervalSince1970]) stringValue];
    
    [request setTimeoutInterval:20];
    if (useCache) {
        [request setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
    }
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
        NSDate *date = [NSDate date];
        if ([data isKindOfClass:[NSData class]]) {
            object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        }
        if ([data isKindOfClass:[NSString class]]) {
            object = [data object];
        }
        object = [object cleanNull];
        
        if(handleEmoji){
            object = [[[object json] stringByReplacingEmojiCheatCodesWithUnicode] object];
            NSLog(@"解析网络数据耗时 %.4f 秒",[[NSDate date] timeIntervalSinceDate:date]);
        }
        
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

- (AFHTTPRequestOperation *)requestToUrl:(NSString *)url method:(NSString *)method useCache:(BOOL)useCache
              params:(NSDictionary *)params complete:(void (^)(BOOL successed, HttpResponse *response))complete
{
    NSMutableURLRequest *request = [self requestWithUrl:url method:method useCache:useCache params:params];
    
    AFHTTPRequestOperation *operation = nil;
    
    void (^requestSuccessBlock)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        [self logWithOperation:operation method:request.HTTPMethod params:params];
        
        //已在cache中完成自带表情的解析
        [self dictionaryWithData:responseObject handleEmoji:!useCache complete:^(NSDictionary *object) {
            HttpResponse *resObj = [[HttpResponse alloc] init];
            resObj.request_url = operation.request.URL;
            resObj.request_params = [request.accessibilityValue object]?:params;
            resObj.payload = object;
            resObj.error = operation.error;
            resObj.is_cache = resObj.error!=nil;
            
            [self handleResponse:resObj complete:complete];
        }];
    };
    void (^requestFailureBlock)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        [self logWithOperation:operation method:method params:params];
        
        HttpResponse *resObj = [[HttpResponse alloc] init];
        resObj.request_url = operation.request.URL;
        resObj.request_params = [request.accessibilityValue object]?:params;
        resObj.error = operation.error;
        complete ? complete(NO,nil) : nil;
        
        [self handleHttpResponseError:error useCache:useCache];
    };
    
    if (useCache) {
        NSURLRequest *cacheRequest = [self cacheRequestUrl:url method:@"GET" useCache:useCache params:params];
        operation = [self cacheOperationWithRequest:request cacheRequest:cacheRequest success:requestSuccessBlock failure:requestFailureBlock];
    } else {
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
        [self dictionaryWithData:operation.responseData handleEmoji:YES complete:^(NSDictionary *object) {
            NSData *data = [[object json] dataUsingEncoding:NSUTF8StringEncoding];
            
            NSCachedURLResponse *cachedURLResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:cacheRequest];
            cachedURLResponse = [[NSCachedURLResponse alloc] initWithResponse:operation.response data:data userInfo:nil storagePolicy:NSURLCacheStorageAllowed];
            [[NSURLCache sharedURLCache] storeCachedResponse:cachedURLResponse forRequest:cacheRequest];
            
            success(operation,object);
        }];
        
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
            NSLog(@"get request url:  %@  ",[operation.request.URL.absoluteString decode]);
        }else{
            NSLog(@"%@ request url:  %@  \npost params:  %@\n",[method lowercaseString],[operation.request.URL.absoluteString decode],[operation.request.accessibilityValue object]);
        }
        
        NSLog(@"%@ responseObject:  %@",[method lowercaseString],response);
        NSLog(@"%@ error :  %@",[method lowercaseString],operation.error);
    }
    else{
        
        if ([[method uppercaseString] isEqualToString:@"GET"]) {
            NSLog(@"get request url:  %@  ",[operation.request.URL.absoluteString decode]);
        }else{
            NSLog(@"%@ request url:  %@  \npost params:  %@\n",[method lowercaseString],[operation.request.URL.absoluteString decode],[operation.request.accessibilityValue object]);
        }
        
        NSLog(@"%@ responseObject:  %@",[method lowercaseString],response);

        [self takesTimeWithRequest:operation.request flag:@"接口"];
    }
}

//打印每个接口的响应时间
- (void)takesTimeWithRequest:(NSURLRequest *)request flag:(NSString *)flag
{
    if (request && request.accessibilityHint) {
        NSURL *url = request.URL;
        
        double beginTime = [request.accessibilityHint doubleValue];
        double localTime = [[NSDate date] timeIntervalSince1970];
        
        FLOG(@"%@: %@    耗时：%.3f秒",flag,url.interface,localTime-beginTime);
    }
}

- (AFHTTPRequestOperation *)uploadToUrl:(NSString *)url
                                 params:(NSDictionary *)params
                                  files:(NSArray *)files
                               complete:(void (^)(BOOL successed, HttpResponse *response))complete
{
    return [self uploadToUrl:url params:params files:files process:nil complete:complete];
}

- (AFHTTPRequestOperation *)uploadToUrl:(NSString *)url
                                 params:(NSDictionary *)params
                                  files:(NSArray *)files
                                process:(void (^)(long writedBytes, long totalBytes))process
                               complete:(void (^)(BOOL successed, HttpResponse *response))complete
{
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
    
    AFHTTPRequestOperation *operation = nil;
    operation = [_operationManager HTTPRequestOperationWithRequest:request
                                                          success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                              id response = [operation.responseString object]?:operation.responseString;
                                                              NSLog(@"post responseObject:  %@",response);
                                                              
                                                              [self takesTimeWithRequest:operation.request flag:@"上传"];
                                                              if (complete) {
                                                                  [self dictionaryWithData:responseObject handleEmoji:YES complete:^(NSDictionary *object) {
                                                                      HttpResponse *resObj = [[HttpResponse alloc] init];
                                                                      resObj.request_url = operation.request.URL;
                                                                      resObj.request_params = params;
                                                                      resObj.payload = object;
                                                                      
                                                                      [self handleResponse:resObj complete:complete];
                                                                  }];
                                                              }
                                                          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                              NSLog(@"post request url:  %@  \npost params:  %@",lastUrl,params);
                                                              NSLog(@"post responseObject:  %@",operation.responseString);
                                                              NSLog(@"post error :  %@",error);
                                                              
//                                                              [KeyWindow showAlertMessage:@"网络连接失败" callback:nil];
                                                              if (complete) {
                                                                  HttpResponse *resObj = [[HttpResponse alloc] init];
                                                                  resObj.request_url = operation.request.URL;
                                                                  resObj.request_params = params;
                                                                  resObj.error = error;
                                                                  complete(NO,resObj);
                                                              }
                                                              
                                                              [self handleHttpResponseError:error useCache:NO];
                                                          }];
    
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        float progress = (float)totalBytesWritten / totalBytesExpectedToWrite;
        NSLog(@"upload process: %.0f%% (%@/%@)",100*progress,@(totalBytesWritten),@(totalBytesExpectedToWrite));
        if (process) {
            process((long)totalBytesWritten,(long)totalBytesExpectedToWrite);
        }
    }];
    [operation start];
    
    return operation;
}

- (AFHTTPRequestOperation *)downloadFromUrl:(NSString *)url
                                   filePath:(NSString *)filePath
                                   complete:(void (^)(BOOL successed, HttpResponse *response))complete
{
    return [self downloadFromUrl:url params:nil filePath:filePath process:nil complete:complete];
}

- (AFHTTPRequestOperation *)downloadFromUrl:(NSString *)url
                                     params:(NSDictionary *)params
                                   filePath:(NSString *)filePath
                                    process:(void (^)(long readBytes, long totalBytes))process
                                   complete:(void (^)(BOOL successed, HttpResponse *response))complete
{
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    NSMutableURLRequest *request = [serializer requestWithMethod:@"GET" URLString:url parameters:params error:nil];
    request.accessibilityValue = [@([[NSDate date] timeIntervalSince1970]) stringValue];
    NSLog(@"get request url: %@",[request.URL.absoluteString decode]);
    
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
            NSLog(@"get responseObject:  %@",responseObject);
        }
        else {
            [self takesTimeWithRequest:operation.request flag:@"下载"];
            
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            [[NSFileManager defaultManager] moveItemAtPath:tmpPath toPath:filePath error:&moveError];
        }
        
        HttpResponse *resObj = [[HttpResponse alloc] init];
        resObj.request_url = operation.request.URL;
        resObj.request_params = params;
        resObj.payload = responseObject;
        
        if (complete && !moveError) {
            complete(YES,resObj);
        } else {
            resObj.error = [NSError errorWithDomain:NSURLErrorDomain
                                               code:NSURLErrorResourceUnavailable
                                           userInfo:@{NSLocalizedDescriptionKey:@"移动文件失败"}];
            complete?complete(NO,resObj):nil;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        FLOG(@"get error :  %@",error);
        [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
        if (complete) {
            HttpResponse *resObj = [[HttpResponse alloc] init];
            resObj.request_url = operation.request.URL;
            resObj.request_params = params;
            resObj.error = error;
            complete(NO,resObj);
        }
    }];
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        float progress = (float)totalBytesRead / totalBytesExpectedToRead;
        NSLog(@"download process: %.0f%% (%ld/%ld)",100*progress,(long)totalBytesRead,(long)totalBytesExpectedToRead);
        if (process) {
            process((NSUInteger)totalBytesRead,(NSUInteger)totalBytesExpectedToRead);
        }
    }];
    
    [operation start];
    
    return operation;
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
//        return url;
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
