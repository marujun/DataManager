//
//  ImageCache.m
//  CoreDataUtil
//
//  Created by marujun on 14-1-18.
//  Copyright (c) 2014年 jizhi. All rights reserved.
//

#import "ImageCache.h"
#import "HttpManager.h"
#import <ImageIO/ImageIO.h>
#import "NSDate+Common.h"
#import "UIView+Common.h"

#define  IdentifyDefault    @"identify_default"
#define  IdentifyImprove    @"identify_improve"

@interface ImageCacheManager ()

@property (strong, nonatomic) NSString *downloadingUrl;

@property (strong, nonatomic) NSMutableArray *identifyQueue;

@property (strong, nonatomic) NSMutableDictionary *urlClassify;
@property (strong, nonatomic) NSMutableDictionary *identifyClassify;
@property (strong, nonatomic) NSMutableDictionary *operationClassify;

@property (strong, nonatomic) NSMutableDictionary *visitDateDictionary;
@property (strong, nonatomic) NSString *visitPlistPath;

@property (strong, nonatomic) AFHTTPRequestOperation *requestOperation;

- (void)startDownload;

- (void)setActiveDateForUrl:(NSString *)url;

- (void)addOperation:(NSDictionary *)operation identify:(NSString *)identify;

@end

@implementation NSData (ImageCache)

+ (void)dataWithURL:(NSString *)url callback:(void(^)(NSData *data))callback
{
    [self dataWithURL:url identify:nil callback:callback];
}

+ (void)dataWithURL:(NSString *)url
           identify:(NSString *)identify
           callback:(void(^)(NSData *data))callback
{
    [self dataWithURL:url identify:identify process:nil callback:callback];
}

+ (void)dataWithURL:(NSString *)url
           identify:(NSString *)identify
            process:(void (^)(long readBytes, long totalBytes))process
           callback:(void(^)(NSData *data))callback
{
    if(!url || !url.length){
        callback ? callback(nil) : nil;
        return;
    }
    
    [[ImageCacheManager defaultManager] setActiveDateForUrl:url];
    
    NSString *filePath = [self diskCachePathWithURL:url];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        callback ? callback(data) : nil;
    }else{
        //添加到下载列表里
        NSMutableDictionary *operation = [[NSMutableDictionary alloc] init];
        [operation setObject:url forKey:@"url"];
        process?[operation setObject:process forKey:@"process"]:nil;
        callback?[operation setObject:callback forKey:@"callback"]:nil;
        
        [[ImageCacheManager defaultManager] addOperation:operation identify:identify];
    }
}

/*通过URL获取缓存文件在本地对应的路径*/
+ (NSString *)diskCachePathWithURL:(NSString *)url
{
    if (!url || !url.length) {
        return @"";
    }
    
    if ([url hasPrefix:@"/var/mobile/Applications"]) {
        return url;
    }
    
    if ([url hasSuffix:@".mp4"]) {
        return [[self diskCacheDirectory] stringByAppendingPathComponent:url.lastPathComponent];
    }

    return [[self diskCacheDirectory] stringByAppendingPathComponent:[url md5]];
}

+ (void)directoryExistsAtPath:(NSString *)path
{
    NSString *directory = [path stringByDeletingLastPathComponent];
    
    //文件夹不存在的话则创建文件夹
    if (![[NSFileManager defaultManager] fileExistsAtPath:directory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

+ (NSString *)diskCacheDirectory
{
    static NSString *cachePath = nil;
    if (!cachePath) {
        cachePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/imgcache"];
    }
    
    return cachePath;
}

/*计算NSData的MD5值(已加上时间戳，保证相同的data在不同时刻MD5值不相同)*/
- (NSString *)md5
{
    if(self == nil || [self length] == 0){
        return nil;
    }
    
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(self.bytes, (CC_LONG)self.length, md5Buffer);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++){
        [output appendFormat:@"%02x",md5Buffer[i]];
    }

    //保证相同的文件在不同时刻MD5值不相同
    return [[NSString stringWithFormat:@"%@_%@",output,[[NSDate date] timestamp]] md5];
}

+ (NSString *)contentTypeForImageData:(NSData *)data
{
    if (!data) return nil;
    
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
        case 0xFF:
            return @"image/jpeg";
        case 0x89:
            return @"image/png";
        case 0x47:
            return @"image/gif";
        case 0x49:
        case 0x4D:
            return @"image/tiff";
        case 0x52:
            // R as RIFF for WEBP
            if ([data length] < 12) {
                return nil;
            }
            
            NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
            if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
                return @"image/webp";
            }
            
            return nil;
    }
    return nil;
}

@end

@implementation UIImage (ImageCache)
ADD_DYNAMIC_PROPERTY(NSString *,cache_url,setCache_url);

+ (void)imageWithURL:(NSString *)url callback:(void(^)(UIImage *image))callback
{
    [self imageWithURL:url identify:nil callback:callback];
}

+ (void)imageWithURL:(NSString *)url
            identify:(NSString *)identify
            callback:(void(^)(UIImage *image))callback
{
    [self imageWithURL:url identify:identify process:nil callback:callback];
}

+ (void)imageWithURL:(NSString *)url
            identify:(NSString *)identify
             process:(void (^)(long readBytes, long totalBytes))process
            callback:(void(^)(UIImage *image))callback
{
    [NSData dataWithURL:url identify:identify process:process callback:^(NSData *data) {
        UIImage *lastImage = nil;
        NSString *contentType = [NSData contentTypeForImageData:data];
        if (contentType && [contentType isEqualToString:@"image/gif"]) {
            lastImage = [UIImage animatedGIFWithData:data];
        } else{
            lastImage = [UIImage imageWithData:data];
        }

        if (lastImage) {
            lastImage.cache_url = url;
        } else if(data) {
            NSString *filePath = [NSData diskCachePathWithURL:url];
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
        
        callback?callback(lastImage):nil;
    }];
}

+ (void)storeImage:(UIImage *)image forUrl:(NSString *)url
{
    NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
    
    NSString *path = [UIImage diskCachePathWithURL:url];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    [imageData writeToFile:path atomically:YES];
}

+ (NSString *)diskCachePathWithURL:(NSString *)url
{
    return [NSData diskCachePathWithURL:url];
}

+ (NSString *)diskCacheDirectory
{
    return [NSData diskCacheDirectory];
}

+ (UIImage *)animatedGIFWithData:(NSData *)data
{
    if (!data) {
        return nil;
    }
    
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    
    size_t count = CGImageSourceGetCount(source);
    
    UIImage *animatedImage;
    
    if (count <= 1) {
        animatedImage = [[UIImage alloc] initWithData:data];
    }
    else {
        NSMutableArray *images = [NSMutableArray array];
        
        NSTimeInterval duration = 0.0f;
        
        for (size_t i = 0; i < count; i++) {
            CGImageRef image = CGImageSourceCreateImageAtIndex(source, i, NULL);
            
            duration += [self frameDurationAtIndex:i source:source];
            
            [images addObject:[UIImage imageWithCGImage:image scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp]];
            
            CGImageRelease(image);
        }
        
        if (!duration) {
            duration = (1.0f / 10.0f) * count;
        }
        
        animatedImage = [UIImage animatedImageWithImages:images duration:duration];
    }
    
    CFRelease(source);
    
    return animatedImage;
}

+ (float)frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source
{
    float frameDuration = 0.1f;
    CFDictionaryRef cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    NSDictionary *frameProperties = (__bridge NSDictionary *)cfFrameProperties;
    NSDictionary *gifProperties = frameProperties[(NSString *)kCGImagePropertyGIFDictionary];
    
    NSNumber *delayTimeUnclampedProp = gifProperties[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTimeUnclampedProp) {
        frameDuration = [delayTimeUnclampedProp floatValue];
    }
    else {
        
        NSNumber *delayTimeProp = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTimeProp) {
            frameDuration = [delayTimeProp floatValue];
        }
    }
    
    // Many annoying ads specify a 0 duration to make an image flash as quickly as possible.
    // We follow Firefox's behavior and use a duration of 100 ms for any frames that specify
    // a duration of <= 10 ms. See <rdar://problem/7689300> and <http://webkit.org/b/36082>
    // for more information.
    
    if (frameDuration < 0.011f) {
        frameDuration = 0.100f;
    }
    
    CFRelease(cfFrameProperties);
    return frameDuration;
}

@end

@implementation UIImageView (ImageCache)
ADD_DYNAMIC_PROPERTY(NSString *,cache_url,setCache_url);
ADD_DYNAMIC_PROPERTY(NSString *,cache_identify,setCache_identify);

- (void)setImageURL:(NSString *)url
{
    [self setImageURL:url callback:nil];
}
- (void)setImageURL:(NSString *)url defaultImage:(UIImage *)defaultImage
{
    self.image = defaultImage;
    
    [self setImageURL:url callback:nil];
}
- (void)setImageURL:(NSString *)url callback:(void(^)(UIImage *image))callback
{
    self.cache_url = url;
    if (!self.cache_identify || [self.cache_identify isEqualToString:IdentifyDefault]) {
        self.cache_identify = [ImageCacheManager identifyOfView:self];
    }
    
    __weak __typeof(self)wself = self;
    [UIImage imageWithURL:url identify:self.cache_identify process:nil callback:^(UIImage *image) {
        if (!wself) return;
        dispatch_main_sync_safe(^{
            __strong UIImageView *sself = wself;
            if (!sself) return;
            if (image && [image.cache_url isEqualToString:sself.cache_url]) {
                sself.image=image;
                callback ? callback(image) : nil;
            }
        });
    }];
}

@end

@implementation UIButton (ImageCache)
ADD_DYNAMIC_PROPERTY(NSString *,cache_url,setCache_url);
ADD_DYNAMIC_PROPERTY(NSString *,cache_identify,setCache_identify);

- (void)setImageURL:(NSString *)url forState:(UIControlState)state
{
    [self setImageURL:url forState:state defaultImage:nil];
}
- (void)setImageURL:(NSString *)url forState:(UIControlState)state defaultImage:(UIImage *)defaultImage
{
    [self setImage:defaultImage forState:state];
    
    [self setImageURL:url forState:state callback:nil];
}
- (void)setImageURL:(NSString *)url forState:(UIControlState)state callback:(void(^)(UIImage *image))callback
{
    self.cache_url = url;
    if (!self.cache_identify || [self.cache_identify isEqualToString:IdentifyDefault]) {
        self.cache_identify = [ImageCacheManager identifyOfView:self];
    }
    
    __weak __typeof(self)wself = self;
    [UIImage imageWithURL:url identify:self.cache_identify process:nil callback:^(UIImage *image) {
        if (!wself) return;
        dispatch_main_sync_safe(^{
            __strong UIButton *sself = wself;
            if (!sself) return;
            if (image && [image.cache_url isEqualToString:sself.cache_url]) {
                [self setImage:image forState:state];
                callback ? callback(image) : nil;
            }
        });
    }];
}


- (void)setBackgroundImageURL:(NSString *)url forState:(UIControlState)state
{
    [self setBackgroundImageURL:url forState:state defaultImage:nil];
}
- (void)setBackgroundImageURL:(NSString *)url forState:(UIControlState)state defaultImage:(UIImage *)defaultImage
{
    [self setBackgroundImage:defaultImage forState:state];
    
    [self setBackgroundImageURL:url forState:state callback:nil];
}
- (void)setBackgroundImageURL:(NSString *)url forState:(UIControlState)state callback:(void(^)(UIImage *image))callback
{
    self.cache_url = url;
    if (!self.cache_identify || [self.cache_identify isEqualToString:IdentifyDefault]) {
        self.cache_identify = [ImageCacheManager identifyOfView:self];
    }
    
    __weak __typeof(self)wself = self;
    [UIImage imageWithURL:url identify:self.cache_identify process:nil callback:^(UIImage *image) {
        if (!wself) return;
        dispatch_main_sync_safe(^{
            __strong UIButton *sself = wself;
            if (!sself) return;
            if (image && [image.cache_url isEqualToString:sself.cache_url]) {
                [self setBackgroundImage:image forState:state];
                callback ? callback(image) : nil;
            }
        });
    }];
}

@end


@implementation NSFileManager (ImageCache)

/*单个文件的大小*/
+ (long long)fileSizeAtPath:(NSString*) filePath{
    struct stat st;
    if(lstat([filePath cStringUsingEncoding:NSUTF8StringEncoding], &st) == 0){
        return st.st_size;
    }
    return 0;
}

/*遍历文件夹获得文件夹大小，返回多少M*/
+ (float)folderSizeAtPath: (NSString *)folderPath
{
    const char* path = [folderPath cStringUsingEncoding:NSUTF8StringEncoding];
    return [self _folderSizeAtPath:path]/(1024.0*1024.0);
}

/*计算文件的MD5值(已加上时间戳，保证相同的文件在不同时刻MD5值不相同)*/
+ (NSString *)fileMd5AtPath:(NSString *)path
{
    NSString *output = (__bridge_transfer NSString *)FileMD5HashCreateWithPath((__bridge CFStringRef)path, 0);
    
    //保证相同的文件在不同时刻MD5值不相同
    return [[NSString stringWithFormat:@"%@_%@",output,[[NSDate date] timestamp]] md5];
}

CFStringRef FileMD5HashCreateWithPath(CFStringRef filePath, size_t chunkSizeForReadingData)
{
    // Declare needed variables
    CFStringRef result = NULL;
    CFReadStreamRef readStream = NULL;
    
    // Get the file URL
    CFURLRef fileURL =
    CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)filePath, kCFURLPOSIXPathStyle, false);
    if (!fileURL) goto done;
    
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault, (CFURLRef)fileURL);
    if (!readStream) goto done;
    bool didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed) goto done;
    
    // Initialize the hash object
    CC_MD5_CTX hashObject;
    CC_MD5_Init(&hashObject);
    
    // Make sure chunkSizeForReadingData is valid
    if (!chunkSizeForReadingData) {
        chunkSizeForReadingData = 1024*8;
    }
    
    // Feed the data to the hash object
    bool hasMoreData = true;
    while (hasMoreData) {
        uint8_t buffer[chunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream, (UInt8 *)buffer, (CFIndex)sizeof(buffer));
        if (readBytesCount == -1) break;
        if (readBytesCount == 0) {
            hasMoreData = false;
            continue;
        }
        CC_MD5_Update(&hashObject, (const void *)buffer, (CC_LONG)readBytesCount);
    }
    
    // Check if the read operation succeeded
    didSucceed = !hasMoreData;
    
    // Compute the hash digest
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &hashObject);
    
    // Abort if the read operation failed
    if (!didSucceed) goto done;
    
    // Compute the string result
    char hash[2 * sizeof(digest) + 1];
    for (size_t i = 0; i < sizeof(digest); ++i) {
        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }
    result = CFStringCreateWithCString(kCFAllocatorDefault, (const char *)hash, kCFStringEncodingUTF8);
    
done:
    
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL) {
        CFRelease(fileURL);
    }
    return result;
}

+ (long long)_folderSizeAtPath:(const char*)folderPath
{
    long long folderSize = 0;
    DIR* dir = opendir(folderPath);
    if (dir == NULL) return 0;
    struct dirent* child;
    while ((child = readdir(dir))!=NULL) {
        if (child->d_type == DT_DIR && ((child->d_name[0] == '.' && child->d_name[1] == 0) || // 忽略目录 .
                                        (child->d_name[0] == '.' && child->d_name[1] == '.' && child->d_name[2] == 0) // 忽略目录 ..
                                        )) continue;
        
        int folderPathLength = (int)strlen(folderPath);
        char childPath[1024]; // 子文件的路径地址
        stpcpy(childPath, folderPath);
        if (folderPath[folderPathLength-1] != '/'){
            childPath[folderPathLength] = '/';
            folderPathLength++;
        }
        stpcpy(childPath+folderPathLength, child->d_name);
        childPath[folderPathLength + child->d_namlen] = 0;
        if (child->d_type == DT_DIR){ // directory
            folderSize += [self _folderSizeAtPath:childPath]; // 递归调用子目录
            // 把目录本身所占的空间也加上
            struct stat st;
            if(lstat(childPath, &st) == 0) folderSize += st.st_size;
        }else if (child->d_type == DT_REG || child->d_type == DT_LNK){ // file or link
            struct stat st;
            if(lstat(childPath, &st) == 0) folderSize += st.st_size;
        }
    }
    return folderSize;
}

@end


@implementation ImageCacheManager

+ (instancetype)defaultManager
{
    static dispatch_once_t pred = 0;
    __strong static id defaultImageCacheManager = nil;
    dispatch_once( &pred, ^{
        defaultImageCacheManager = [[self alloc] init];
    });
    return defaultImageCacheManager;
}

- (id)init
{
    self = [super init];
    if (self) {
        _identifyQueue = [[NSMutableArray alloc] init];
        
        _urlClassify = [[NSMutableDictionary alloc] init];
        _identifyClassify = [[NSMutableDictionary alloc] init];
        _operationClassify = [[NSMutableDictionary alloc] init];
        
        _visitPlistPath = [[UIImage diskCacheDirectory] stringByAppendingPathComponent:@"date.plist"];
        _visitDateDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:_visitPlistPath];
        _visitDateDictionary = _visitDateDictionary?:[[NSMutableDictionary alloc] init];
    }
    return self;
}

+ (NSString *)identifyOfView:(UIView *)view
{
    if (!view) {
        return IdentifyDefault;
    }
    
    UIViewController *nearsetVC = view.nearsetViewController;
    if (nearsetVC){
        return NSStringFromClass([nearsetVC class]);
    }
    
    return IdentifyDefault;
}

- (void)setActiveDateForUrl:(NSString *)url
{
    NSString *timestamp = [[NSDate date] timestamp];
    [_visitDateDictionary setObject:timestamp forKey:[url md5]];
    
    //3秒之后保存一次
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(synchronizeVistDateList) object:nil];
    [self performSelector:@selector(synchronizeVistDateList) withObject:nil afterDelay:3];
}

- (void)autoCleanImageCache
{
    double timestamp = [[[NSDate date] timestamp] doubleValue];
    float  stashInterval = 6*24*60*60*1000;  //自动清除6天之前活跃的图片
    
    @synchronized(_visitDateDictionary){
        NSMutableArray *waitArray = [NSMutableArray array];
        [_visitDateDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            double itemstamp = [obj doubleValue];
            if (timestamp-itemstamp > stashInterval) {
                [waitArray addObject:key];
            }
        }];
        [_visitDateDictionary removeObjectsForKeys:waitArray];
        [self synchronizeVistDateList];
        
        //删除文件
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            for (NSString *key in waitArray) {
                NSString *path = [[UIImage diskCacheDirectory] stringByAppendingPathComponent:key];
                [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
            }
        });
    }
}

- (void)synchronizeVistDateList
{
    NSDictionary *lastList = [_visitDateDictionary copy];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @try {
            [lastList writeToFile:_visitPlistPath atomically:YES];
        }
        @catch (NSException *exception) {}
    });
}

- (void)addOperation:(NSDictionary *)operation identify:(NSString *)identify
{
    @synchronized(_identifyQueue){
        //添加到下载列表里
        
        NSString *newestId = [_identifyQueue firstObject];
        BOOL needCancel = (newestId && identify && ![newestId isEqualToString:identify]);
        
        if (identify) {
            [_identifyQueue removeObject:identify];
            [_identifyQueue insertObject:identify atIndex:0];
        }else{
            identify = @"identify_default";
            [_identifyQueue removeObject:identify];
            [_identifyQueue addObject:identify];
        }
        NSString *uniqueId = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
        uniqueId = [[NSString stringWithFormat:@"%@_%@_%@",operation[@"url"],identify,uniqueId] md5];
        
        //所有任务对应的关系表
        [_operationClassify setObject:operation forKey:uniqueId];
        
        //按URL分类（避免同时添加多个相似下载任务）
        NSMutableArray *targetArray = _urlClassify[operation[@"url"]];
        if(!targetArray){
            targetArray = [NSMutableArray array];
            [_urlClassify setObject:targetArray forKey:operation[@"url"]];
        }
        [targetArray addObject:uniqueId];
        
        //按identify分类（保证第一个identify的任务优先执行）
        targetArray = _identifyClassify[identify];
        if(!targetArray){
            targetArray = [NSMutableArray array];
            [_identifyClassify setObject:targetArray forKey:identify];
        }
        [targetArray addObject:uniqueId];
        
        if (needCancel) {
            [_requestOperation cancel];
        }
        
        [self startDownload];
    }
}

- (void)openOperationForIdentify:(NSString *)identify
{
    @synchronized(_identifyQueue){
        NSString *newestId = [_identifyQueue firstObject];
        BOOL needCancel = (newestId && identify && ![newestId isEqualToString:identify]);
        
        identify = identify?:@"identify_default";
        if ([_identifyQueue containsObject:identify]) {
            [_identifyQueue removeObject:identify];
            [_identifyQueue insertObject:identify atIndex:0];
        }
        
        if (needCancel) {
            [_requestOperation cancel];
        }
        
        [self startDownload];
    }
}

- (void)improvePriorityForUrl:(NSString *)url
{
    if(!url || !url.length){
        return;
    }
    
    @synchronized(_identifyQueue){

        //取消当前正在下载的任务
        [_requestOperation cancel];
        
        [_identifyQueue removeObject:IdentifyImprove];
        [_identifyQueue addObject:IdentifyImprove];

        NSMutableArray *targetArray = _identifyClassify[IdentifyImprove];
        if(!targetArray){
            targetArray = [NSMutableArray array];
            [_identifyClassify setObject:targetArray forKey:IdentifyImprove];
        }

        NSMutableArray *uniqueIdArray = _urlClassify[url];
        if(uniqueIdArray && uniqueIdArray.count){
            for (NSString *uniqueId in uniqueIdArray) {
                [targetArray removeObject:uniqueId];
                [targetArray insertObject:uniqueId atIndex:0];
            }
        }
        
        [self startDownload];
    }
}

- (void)improvePriorityForUrlArray:(NSArray *)urlArray
{
    if(!urlArray || !urlArray.count){
        return;
    }
    
    @synchronized(_identifyQueue){
        
        //取消当前正在下载的任务
        [_requestOperation cancel];
        
        [_identifyQueue removeObject:IdentifyImprove];
        [_identifyQueue addObject:IdentifyImprove];
        
        NSMutableArray *targetArray = _identifyClassify[IdentifyImprove];
        if(!targetArray){
            targetArray = [NSMutableArray array];
            [_identifyClassify setObject:targetArray forKey:IdentifyImprove];
        }
        
        for (int i=(int)(urlArray.count-1); i>=0; i--) {
            if ([urlArray[i] isKindOfClass:[NSString class]]) {
                NSMutableArray *uniqueIdArray = _urlClassify[urlArray[i]];
                if(uniqueIdArray && uniqueIdArray.count){
                    for (NSString *uniqueId in uniqueIdArray) {
                        [targetArray removeObject:uniqueId];
                        [targetArray insertObject:uniqueId atIndex:0];
                    }
                }
            }
        }
        
        [self startDownload];
    }
}

- (void)cancelLoadingUrl:(NSString *)url
{
    if(!url || !url.length){
        return;
    }

    @synchronized(_identifyQueue){
        if (_downloadingUrl && [url isEqualToString:_downloadingUrl]) {
            [_requestOperation cancel];
        }
        
        NSMutableArray *uniqueIdArray = _urlClassify[url];
        if(uniqueIdArray && uniqueIdArray.count){
            for (NSString *uniqueId in uniqueIdArray) {
                [_operationClassify removeObjectForKey:uniqueId];
            }
        }
        [_urlClassify removeObjectForKey:url];

        [self startDownload];
    }
}

- (void)startDownload
{
    if (_identifyQueue.count && !_downloadingUrl) {
        
        //获取最新identify对应的下载列表
        NSString *downIdentify = [_identifyQueue firstObject];
        NSMutableArray *taskQueue = _identifyClassify[downIdentify];
        if (!taskQueue || !taskQueue.count) {
            [_identifyQueue removeObject:downIdentify];
            [_identifyClassify removeObjectForKey:downIdentify];
            [self startDownload];
            
            return;
        }
        
        //获取最新的任务
        NSString *downloadingUniqueId = [taskQueue firstObject];
        NSDictionary *operation = _operationClassify[downloadingUniqueId];
        if (!operation) {
            [taskQueue removeObject:downloadingUniqueId];
            _downloadingUrl = nil;
            [self startDownload];
            
            return;
        }
        
        _downloadingUrl = operation[@"url"];
        NSString *filePath = [NSData diskCachePathWithURL:_downloadingUrl];
        [NSData directoryExistsAtPath:filePath];
        
        void(^processBlock)(long, long) = ^(long readBytes, long totalBytes)
        {
            NSArray *urlArray = _urlClassify[_downloadingUrl];
            if(urlArray && urlArray.count){
                for (NSString *uniqueId in urlArray) {
                    if (_operationClassify[uniqueId]) {
                        void(^processBlock)(long, long) = _operationClassify[uniqueId][@"process"];
                        processBlock?processBlock(readBytes,totalBytes):nil;
                    }
                }
            }
        };
        
        void(^completeBlock)(BOOL, NSDictionary *) = ^(BOOL successed, NSDictionary *result)
        {
            NSData *lastData = nil;
            if (successed && !result) {
                lastData = [NSData dataWithContentsOfFile:filePath];
            }
            
            @synchronized(_identifyQueue){
                
                if (!_requestOperation || !_requestOperation.error || _requestOperation.error.code != NSURLErrorCancelled) {
                    
                    //不是手动取消的任务即使失败了也要从队列中移除
                    [taskQueue removeObject:downloadingUniqueId];
                    if(!taskQueue.count){
                        [_identifyQueue removeObject:downIdentify];
                        [_identifyClassify removeObjectForKey:downIdentify];
                    }
                    
                    NSMutableArray *uniqueIdArray = _urlClassify[_downloadingUrl];
                    if(uniqueIdArray && uniqueIdArray.count){
                        for (NSString *uniqueId in uniqueIdArray) {
                            if (_operationClassify[uniqueId]) {
                                void(^callbackBlock)(NSData *) = _operationClassify[uniqueId][@"callback"];
                                callbackBlock?callbackBlock(lastData):nil;
                                
                                [_operationClassify removeObjectForKey:uniqueId];
                            }
                        }
                    }
                    [_urlClassify removeObjectForKey:_downloadingUrl];
                }
                
                
                _downloadingUrl = nil;
                _requestOperation = nil;
                
                [self startDownload];
            }
        };
        
        _requestOperation = [[HttpManager defaultManager] downloadFromUrl:_downloadingUrl
                                                                   params:nil
                                                                 filePath:filePath
                                                                  process:processBlock
                                                                 complete:completeBlock];
    }
    else if (!_identifyQueue.count){
        _requestOperation = nil;
    }
}


@end
