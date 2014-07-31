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

@interface HttpManager ()
{
    Reachability *reachability;
    AFHTTPRequestOperationManager *operationManager;
}
@end

@implementation HttpManager

- (id)init{
    self = [super init];
	if (self) {
        operationManager = [AFHTTPRequestOperationManager manager];
        operationManager.responseSerializer.acceptableContentTypes = nil;
        
        reachability = [Reachability reachabilityWithHostname:@"www.baidu.com"];
        [reachability startNotifier];
        
        NSURLCache *urlCache = [NSURLCache sharedURLCache];
        [urlCache setMemoryCapacity:5*1024*1024];  /* 设置缓存的大小为5M*/
        [NSURLCache setSharedURLCache:urlCache];
    }
    return self;
}

- (NetworkStatus)networkStatus
{
    return [reachability currentReachabilityStatus];
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
    [self requestToUrl:url method:@"GET" useCache:NO params:params complete:complete];
}

- (void)getCacheToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, NSDictionary *result))complete
{
    [self requestToUrl:url method:@"GET" useCache:YES params:params complete:complete];
}

- (void)postRequestToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, NSDictionary *result))complete
{
    [self requestToUrl:url method:@"POST" useCache:NO params:params complete:complete];
}

- (NSMutableURLRequest *)requestWithUrl:(NSString *)url method:(NSString *)method useCache:(BOOL)useCache params:(NSDictionary *)params
{
    params = [[HttpManager getRequestBodyWithParams:params] copy];
    
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    NSMutableURLRequest *request = [serializer requestWithMethod:method URLString:url parameters:params error:nil];
    
    [request setTimeoutInterval:10];
    if (useCache) {
        [request setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
    }
    return request;
}

- (id)dictionaryWithData:(id)data
{
    NSDictionary *object = data;
    if ([data isKindOfClass:[NSData class]]) {
        object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    }
    if ([data isKindOfClass:[NSString class]]) {
        object = [data object];
    }
    return object?:data;
}

- (void)localCacheToUrl:(NSString *)url params:(NSDictionary *)params complete:(void (^)(BOOL successed, NSDictionary *result))complete
{
    NSMutableURLRequest *request = [self requestWithUrl:url method:@"GET" useCache:true params:params];
    
    NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
    if (cachedResponse != nil && [[cachedResponse data] length] > 0) {
        complete ? complete(true, [self dictionaryWithData:cachedResponse.data]) : nil;
    } else {
        [self getCacheToUrl:url params:params complete:complete];
    }
}

- (void)requestToUrl:(NSString *)url method:(NSString *)method useCache:(BOOL)useCache
              params:(NSDictionary *)params complete:(void (^)(BOOL successed, NSDictionary *result))complete
{
    NSMutableURLRequest *request = [self requestWithUrl:url method:method useCache:useCache params:params];
    
    void (^requestSuccessBlock)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        [self logWithOperation:operation method:method params:params];
        complete ? complete(true,[self dictionaryWithData:responseObject]) : nil;
    };
    void (^requestFailureBlock)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        [self logWithOperation:operation method:method params:params];
        complete ? complete(false,nil) : nil;
    };
    
    AFHTTPRequestOperation *operation = nil;
    if (useCache) {
        operation = [self cacheOperationWithRequest:request success:requestSuccessBlock failure:requestFailureBlock];
    }else{
        operation = [operationManager HTTPRequestOperationWithRequest:request success:requestSuccessBlock failure:requestFailureBlock];
    }
    [operationManager.operationQueue addOperation:operation];
}

- (AFHTTPRequestOperation *)cacheOperationWithRequest:(NSURLRequest *)urlRequest
                                              success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    AFHTTPRequestOperation *operation = [operationManager HTTPRequestOperationWithRequest:urlRequest success:^(AFHTTPRequestOperation *operation, id responseObject){
        NSCachedURLResponse *cachedURLResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:urlRequest];
        
        //store in cache
        cachedURLResponse = [[NSCachedURLResponse alloc] initWithResponse:operation.response data:operation.responseData userInfo:nil storagePolicy:NSURLCacheStorageAllowed];
        [[NSURLCache sharedURLCache] storeCachedResponse:cachedURLResponse forRequest:urlRequest];
        
        success(operation,responseObject);
        
    }failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (error.code == kCFURLErrorNotConnectedToInternet) {
            NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:urlRequest];
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
    if ([[method uppercaseString] isEqualToString:@"GET"]) {
        FLOG(@"get request url:  %@  \n",[operation.request.URL.absoluteString decode]);
    }else{
        FLOG(@"%@ request url:  %@  \npost params:  %@\n",[method lowercaseString],[operation.request.URL.absoluteString decode],params);
    }
    if (operation.error) {
        FLOG(@"%@ error :  %@",[method lowercaseString],operation.error);
    }else{
        id response = [operation.responseString object]?:operation.responseString;
        FLOG(@"%@ responseObject:  %@",[method lowercaseString],response);
    }
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
                                process:(void (^)(NSInteger writedBytes, NSInteger totalBytes))process
                               complete:(void (^)(BOOL successed, NSDictionary *result))complete
{
    params = [[HttpManager getRequestBodyWithParams:params] copy];
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
                if (UIImagePNGRepresentation(value)) {  //返回为png图像。
                    [formData appendPartWithFileData:UIImagePNGRepresentation(value) name:name fileName:fileName mimeType:mimeType];
                }else {   //返回为JPEG图像。
                    [formData appendPartWithFileData:UIImageJPEGRepresentation(value, 0.5) name:name fileName:fileName mimeType:mimeType];
                }
            }else if ([value isKindOfClass:[NSURL class]]) {
                [formData appendPartWithFileURL:value name:name fileName:fileName mimeType:mimeType error:nil];
            }else if ([value isKindOfClass:[NSString class]]) {
                [formData appendPartWithFileURL:[NSURL URLWithString:value]  name:name fileName:fileName mimeType:mimeType error:nil];
            }
        }
    } error:nil];
    
    AFHTTPRequestOperation *operation = nil;
    operation = [operationManager HTTPRequestOperationWithRequest:request
                                                          success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                              id response = [operation.responseString object]?:operation.responseString;
                                                              FLOG(@"post responseObject:  %@",response);
                                                              if (complete) {
                                                                  complete(true,[self dictionaryWithData:responseObject]);
                                                              }
                                                          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                              FLOG(@"post error :  %@",error);
                                                              if (complete) {
                                                                  complete(false,nil);
                                                              }
                                                          }];
    
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        float progress = (float)totalBytesWritten / totalBytesExpectedToWrite;
        FLOG(@"upload process: %.0f%% (%lld/%lld)",100*progress,totalBytesWritten,totalBytesExpectedToWrite);
        if (process) {
            process((NSUInteger)totalBytesWritten,(NSUInteger)totalBytesExpectedToWrite);
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
                                    process:(void (^)(NSInteger readBytes, NSInteger totalBytes))process
                                   complete:(void (^)(BOOL successed, NSDictionary *response))complete
{
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    NSMutableURLRequest *request = [serializer requestWithMethod:@"GET" URLString:url parameters:params error:nil];
    FLOG(@"get request url: %@",[request.URL.absoluteString decode]);
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer.acceptableContentTypes = nil;
    
    NSString *tmpPath = [filePath stringByAppendingString:@".tmp"];
    operation.outputStream=[[NSOutputStream alloc] initToFileAtPath:tmpPath append:NO];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *mimeTypeArray = @[@"text/html", @"application/json"];
        NSError *moveError = nil;
        if ([mimeTypeArray containsObject:operation.response.MIMEType]) {
            //返回的是json格式数据
            responseObject = [self dictionaryWithData:[NSData dataWithContentsOfFile:tmpPath]];
            [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
            FLOG(@"get responseObject:  %@",responseObject);
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
        FLOG(@"get error :  %@",error);
        [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
        if (complete) {
            complete(false,nil);
        }
    }];
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        float progress = (float)totalBytesRead / totalBytesExpectedToRead;
        FLOG(@"download process: %.0f%% (%lld/%lld)",100*progress,totalBytesRead,totalBytesExpectedToRead);
        if (process) {
            process((NSUInteger)totalBytesRead,(NSUInteger)totalBytesExpectedToRead);
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

@end
