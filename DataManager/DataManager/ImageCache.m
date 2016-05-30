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

@interface UIWindow (ImageCache)

- (UIViewController *) visibleViewController;

@end

@implementation UIWindow (ImageCache)

- (UIViewController *)visibleViewController {
    UIViewController *rootViewController = self.rootViewController;
    return [UIWindow getVisibleViewControllerFrom:rootViewController];
}

+ (UIViewController *) getVisibleViewControllerFrom:(UIViewController *) vc {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [UIWindow getVisibleViewControllerFrom:[((UINavigationController *) vc) topViewController]];
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        return [UIWindow getVisibleViewControllerFrom:[((UITabBarController *) vc) selectedViewController]];
    } else {
        if (vc.presentedViewController) {
            return [UIWindow getVisibleViewControllerFrom:vc.presentedViewController];
        } else {
            if (vc.childViewControllers.count) {
                return [UIWindow getVisibleViewControllerFrom:[vc.childViewControllers lastObject]];
            }
            return vc;
        }
    }
}

@end

#define  FadeAnimationKey   @"image_cache_fade_animation"

static const NSString *TemporaryIdentify = @"TemporaryIdentify";

@interface ImageCacheManager ()

#if OS_OBJECT_USE_OBJC
@property (nonatomic, strong) dispatch_queue_t synchronizeQueue;
#else
@property (nonatomic, assign) dispatch_queue_t synchronizeQueue;
#endif
@property (strong, nonatomic) NSMutableArray *identifyQueue;

@property (strong, nonatomic) NSMutableDictionary *urlClassify;
@property (strong, nonatomic) NSMutableDictionary *identifyClassify;
@property (strong, nonatomic) NSMutableDictionary *operationClassify;

@property (strong, nonatomic) NSMutableDictionary *visitDateDictionary;
@property (strong, nonatomic) NSString *visitPlistPath;

- (void)startDownload;

- (void)setActiveDateForURL:(NSString *)url;

- (void)addOperation:(NSDictionary *)operation identify:(NSString *)identify;

@end

@implementation NSData (ImageCache)
ADD_DYNAMIC_PROPERTY(NSNumber *,disk_exist,setDisk_exist);

+ (void)dataWithURL:(NSString *)url completed:(void(^)(NSData *data))completed
{
    [self dataWithURL:url identify:nil completed:completed];
}

+ (void)dataWithURL:(NSString *)url
           identify:(NSString *)identify
          completed:(void(^)(NSData *data))completed
{
    [self dataWithURL:url identify:identify process:nil completed:completed];
}

+ (void)dataWithURL:(NSString *)url
           identify:(NSString *)identify
            process:(void (^)(int64_t readBytes, int64_t totalBytes))process
          completed:(void(^)(NSData *data))completed
{
    if(!url || !url.length){
        completed ? completed(nil) : nil;
        return;
    }
    
    if ([url hasPrefix:@"http"]) {
        [[ImageCacheManager defaultManager] setActiveDateForURL:url];
    }
    
    NSString *filePath = [self diskCachePathWithURL:url];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        data.disk_exist = @(YES);
        completed ? completed(data) : nil;
    }else{
        //添加到下载列表里
        NSMutableDictionary *operation = [[NSMutableDictionary alloc] init];
        [operation setValue:url forKey:@"url"];
        [operation setValue:process forKey:@"process"];
        [operation setValue:completed forKey:@"completed"];
        
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
ADD_DYNAMIC_PROPERTY(NSNumber *,disk_exist,setDisk_exist);

+ (void)imageWithURL:(NSString *)url completed:(void(^)(UIImage *image))completed
{
    [self imageWithURL:url identify:nil completed:completed];
}

+ (void)imageWithURL:(NSString *)url
            identify:(NSString *)identify
           completed:(void(^)(UIImage *image))completed
{
    [self imageWithURL:url identify:identify process:nil completed:completed];
}

+ (void)imageWithURL:(NSString *)url
            identify:(NSString *)identify
             process:(void (^)(int64_t readBytes, int64_t totalBytes))process
           completed:(void(^)(UIImage *image))completed
{
    [NSData dataWithURL:url identify:identify process:process completed:^(NSData *data) {
        UIImage *lastImage = nil;
        NSString *contentType = [NSData contentTypeForImageData:data];
        if (contentType && [contentType isEqualToString:@"image/gif"]) {
            lastImage = [UIImage animatedGIFWithData:data];
        } else {
            lastImage = [UIImage imageWithData:data];
        }
        lastImage.disk_exist = data.disk_exist;
        
        if (lastImage) {
            lastImage.cache_url = url;
            
            [[ImageCacheManager defaultManager].imageMemoryCache setObject:lastImage forKey:url cost:data.length];
        }
        else if(data) {
            NSString *filePath = [NSData diskCachePathWithURL:url];
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
        
        completed?completed(lastImage):nil;
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

- (void)setImageWithURL:(NSString *)url
{
    [self setImageWithURL:url completed:nil];
}
- (void)setImageWithURL:(NSString *)url placeholderImage:(UIImage *)placeholder
{
    self.image = placeholder;
    
    [self setImageWithURL:url completed:nil];
}
- (void)setImageWithURL:(NSString *)url completed:(void(^)(UIImage *image))completed
{
    [self setImageWithURL:url identify:nil completed:completed];
}
- (void)setImageWithURL:(NSString *)url identify:(NSString *)identify completed:(void(^)(UIImage *image))completed
{
    self.cache_url = url;
    if (!url) return;
    
    NSCache *imageCache = [ImageCacheManager defaultManager].imageMemoryCache;
    if ([imageCache objectForKey:url]) {
        [self.layer removeAnimationForKey:FadeAnimationKey];
        self.image = [imageCache objectForKey:url];
        completed ? completed(self.image) : nil;
        return;
    }
    
    if(identify && identify.length) {
        self.cache_identify = identify;
    } else {
        BOOL isTemporary = [objc_getAssociatedObject(self, &TemporaryIdentify) boolValue];
        if (!self.cache_identify || isTemporary) {
            self.cache_identify = [ImageCacheManager identifyOfView:self];
        }
    }
    
    __weak __typeof(self)wself = self;
    [UIImage imageWithURL:url identify:self.cache_identify process:nil completed:^(UIImage *image) {
        if (!wself) return;
        dispatch_main_sync_safe(^{
            __strong UIImageView *sself = wself;
            if (!sself) return;
            if (image && [image.cache_url isEqualToString:sself.cache_url]) {
                [sself.layer removeAnimationForKey:FadeAnimationKey];
                if (image.disk_exist.boolValue) {
                    sself.image=image;
                } else {
                    CATransition *transition = [CATransition animation];
                    transition.duration = 0.25;
                    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                    transition.type = kCATransitionFade;
                    sself.image=image;
                    [sself.layer addAnimation:transition forKey:FadeAnimationKey];
                }
                
                completed ? completed(image) : nil;
            }
        });
    }];
}

@end

@implementation UIButton (ImageCache)
ADD_DYNAMIC_PROPERTY(NSString *,cache_url,setCache_url);
ADD_DYNAMIC_PROPERTY(NSString *,cache_identify,setCache_identify);

- (void)setImageWithURL:(NSString *)url forState:(UIControlState)state
{
    [self setImageWithURL:url forState:state placeholderImage:nil];
}
- (void)setImageWithURL:(NSString *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder
{
    [self setImage:placeholder forState:state];
    
    [self setImageWithURL:url forState:state completed:nil];
}
- (void)setImageWithURL:(NSString *)url forState:(UIControlState)state completed:(void(^)(UIImage *image))completed
{
    self.cache_url = url;
    
    [self setImageWithURL:url forState:state identify:nil completed:completed];
}
- (void)setImageWithURL:(NSString *)url forState:(UIControlState)state identify:(NSString *)identify completed:(void(^)(UIImage *image))completed
{
    self.cache_url = url;
    if (!url) return;
    
    NSCache *imageCache = [ImageCacheManager defaultManager].imageMemoryCache;
    if ([imageCache objectForKey:url]) {
        [self.layer removeAnimationForKey:FadeAnimationKey];
        [self setImage:[imageCache objectForKey:url] forState:state];
        completed ? completed([self imageForState:state]) : nil;
        return;
    }
    
    if(identify && identify.length) {
        self.cache_identify = identify;
    } else {
        BOOL isTemporary = [objc_getAssociatedObject(self, &TemporaryIdentify) boolValue];
        if (!self.cache_identify || isTemporary) {
            self.cache_identify = [ImageCacheManager identifyOfView:self];
        }
    }
    
    __weak __typeof(self)wself = self;
    [UIImage imageWithURL:url identify:self.cache_identify process:nil completed:^(UIImage *image) {
        if (!wself) return;
        dispatch_main_sync_safe(^{
            __strong UIButton *sself = wself;
            if (!sself) return;
            if (image && [image.cache_url isEqualToString:sself.cache_url]) {
                [sself.layer removeAnimationForKey:FadeAnimationKey];
                if (image.disk_exist.boolValue) {
                    [sself setImage:image forState:state];
                } else {
                    CATransition *transition = [CATransition animation];
                    transition.duration = 0.25;
                    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                    transition.type = kCATransitionFade;
                    [sself setImage:image forState:state];
                    [sself.layer addAnimation:transition forKey:FadeAnimationKey];
                }
                
                completed ? completed(image) : nil;
            }
        });
    }];
}


- (void)setBackgroundImageWithURL:(NSString *)url forState:(UIControlState)state
{
    [self setBackgroundImageWithURL:url forState:state placeholderImage:nil];
}
- (void)setBackgroundImageWithURL:(NSString *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder
{
    [self setBackgroundImage:placeholder forState:state];
    
    [self setBackgroundImageWithURL:url forState:state completed:nil];
}
- (void)setBackgroundImageWithURL:(NSString *)url forState:(UIControlState)state completed:(void(^)(UIImage *image))completed
{
    [self setBackgroundImageWithURL:url forState:state identify:nil completed:completed];
}
- (void)setBackgroundImageWithURL:(NSString *)url forState:(UIControlState)state identify:(NSString *)identify completed:(void(^)(UIImage *image))completed
{
    self.cache_url = url;
    if (!url) return;
    
    NSCache *imageCache = [ImageCacheManager defaultManager].imageMemoryCache;
    if ([imageCache objectForKey:url]) {
        [self.layer removeAnimationForKey:FadeAnimationKey];
        [self setBackgroundImage:[imageCache objectForKey:url] forState:state];
        completed ? completed([self backgroundImageForState:state]) : nil;
        return;
    }
    
    if(identify && identify.length) {
        self.cache_identify = identify;
    } else {
        BOOL isTemporary = [objc_getAssociatedObject(self, &TemporaryIdentify) boolValue];
        if (!self.cache_identify || isTemporary) {
            self.cache_identify = [ImageCacheManager identifyOfView:self];
        }
    }
    
    __weak __typeof(self)wself = self;
    [UIImage imageWithURL:url identify:self.cache_identify process:nil completed:^(UIImage *image) {
        if (!wself) return;
        dispatch_main_sync_safe(^{
            __strong UIButton *sself = wself;
            if (!sself) return;
            if (image && [image.cache_url isEqualToString:sself.cache_url]) {
                [sself.layer removeAnimationForKey:FadeAnimationKey];
                if (image.disk_exist.boolValue) {
                    [sself setBackgroundImage:image forState:state];
                } else {
                    CATransition *transition = [CATransition animation];
                    transition.duration = 0.25;
                    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                    transition.type = kCATransitionFade;
                    [sself setBackgroundImage:image forState:state];
                    [sself.layer addAnimation:transition forKey:FadeAnimationKey];
                }
                
                completed ? completed(image) : nil;
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
+ (CGFloat)folderSizeAtPath: (NSString *)folderPath
{
    const char* path = [folderPath cStringUsingEncoding:NSUTF8StringEncoding];
    return [self _folderSizeAtPath:path]/(1024.0*1024.0);
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
        _synchronizeQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        _identifyQueue = [[NSMutableArray alloc] init];
        
        _urlClassify = [[NSMutableDictionary alloc] init];
        _identifyClassify = [[NSMutableDictionary alloc] init];
        _operationClassify = [[NSMutableDictionary alloc] init];
        
        _visitPlistPath = [[UIImage diskCacheDirectory] stringByAppendingPathComponent:@"date.plist"];
        _visitDateDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:_visitPlistPath];
        _visitDateDictionary = _visitDateDictionary?:[[NSMutableDictionary alloc] init];
        
        _imageMemoryCache = [[NSCache alloc] init];
        _imageMemoryCache.countLimit = 100;   //最多缓存100张照片
        _imageMemoryCache.totalCostLimit = 20*1024*1024; //内存缓存最大20M
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appDidReceiveMemoryWarningNotification)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appDidEnterBackgroundNotification)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appWillTerminateNotification)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
    }
    return self;
}

- (void)appDidReceiveMemoryWarningNotification
{
    NSLog(@"已清除内存中缓存的图片！！！");
}

- (void)appDidEnterBackgroundNotification
{
    [self autoCleanImageCache];
}

- (void)appWillTerminateNotification
{
    [self synchronizeVistDateList];
}

+ (NSString *)identifyOfView:(UIView *)view
{
    if (!view) {
        return ImageCacheIdentifyDefault;
    }
    
    UIViewController *nearsetVC = [view nearsetViewController];
    if (nearsetVC){
        objc_setAssociatedObject(view, &TemporaryIdentify, @(NO), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        return NSStringFromClass([nearsetVC class]);
    }
    
    objc_setAssociatedObject(view, &TemporaryIdentify, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    UIViewController *visibleVC = [[[[UIApplication sharedApplication] delegate] window] visibleViewController];
    if (visibleVC) {
        return NSStringFromClass([visibleVC class]);
    }
    
    return ImageCacheIdentifyDefault;
}

- (void)setActiveDateForURL:(NSString *)url
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
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            for (NSString *key in waitArray) {
                NSString *path = [[UIImage diskCacheDirectory] stringByAppendingPathComponent:key];
                [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
            }
        });
    }
}

- (void)synchronizeVistDateList
{
    NSDictionary *lastList = [NSDictionary dictionaryWithDictionary:_visitDateDictionary];
    
    dispatch_async(_synchronizeQueue, ^{
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

- (void)bringIdentifyToFront:(NSString *)identify
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

- (void)bringURLToFront:(NSString *)url
{
    if(!url || !url.length){
        return;
    }
    
    @synchronized(_identifyQueue){
        
        //        //取消当前正在下载的任务
        //        [_requestOperation cancel];
        
        [_identifyQueue removeObject:ImageCacheIdentifyImprove];
        [_identifyQueue insertObject:ImageCacheIdentifyImprove atIndex:0];
        
        NSMutableArray *targetArray = _identifyClassify[ImageCacheIdentifyImprove];
        if(!targetArray){
            targetArray = [NSMutableArray array];
            [_identifyClassify setObject:targetArray forKey:ImageCacheIdentifyImprove];
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

- (void)bringURLArrayToFront:(NSArray *)urlArray
{
    if(!urlArray || !urlArray.count){
        return;
    }
    
    @synchronized(_identifyQueue){
        
        //        //取消当前正在下载的任务
        //        [_requestOperation cancel];
        
        [_identifyQueue removeObject:ImageCacheIdentifyImprove];
        [_identifyQueue insertObject:ImageCacheIdentifyImprove atIndex:0];
        
        NSMutableArray *targetArray = _identifyClassify[ImageCacheIdentifyImprove];
        if(!targetArray){
            targetArray = [NSMutableArray array];
            [_identifyClassify setObject:targetArray forKey:ImageCacheIdentifyImprove];
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

- (void)cancelLoadingURL:(NSString *)url
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
        
        void(^processBlock)(int64_t, int64_t) = ^(int64_t readBytes, int64_t totalBytes)
        {
            NSArray *urlArray = _urlClassify[_downloadingUrl];
            if(urlArray && urlArray.count){
                for (NSString *uniqueId in urlArray) {
                    if (_operationClassify[uniqueId]) {
                        void(^processBlock)(int64_t, int64_t) = _operationClassify[uniqueId][@"process"];
                        processBlock?processBlock(readBytes,totalBytes):nil;
                    }
                }
            }
        };
        
        void(^completeBlock)(BOOL, HttpResponse *response) = ^(BOOL successed, HttpResponse *response)
        {
            NSData *lastData = nil;
            if (successed && !response.payload) {
                lastData = [NSData dataWithContentsOfFile:filePath];
            }
            
            @synchronized(_identifyQueue){
                
                NSError *resError = _requestOperation.error;
                BOOL fileExist = YES;
                BOOL isThumbnail = [_downloadingUrl rangeOfString:@"x_"].length?YES:NO;
                
                //404：表示文件不存在
                if (resError.code==NSURLErrorBadServerResponse && [resError.localizedDescription hasSuffix:@"(404)"] && !isThumbnail) {
                    fileExist = NO;
                    
                    //                    lastData = [NSData dataWithContentsOfFile:[ResourcePath stringByAppendingPathComponent:@"pub_default_not_exist.png"]];
                    //                    [lastData writeToFile:filePath atomically:true];
                }
                
                if (!_requestOperation || !resError || resError.code != NSURLErrorCancelled || !fileExist) {
                    
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
                                void(^completedHandler)(NSData *) = _operationClassify[uniqueId][@"completed"];
                                completedHandler?completedHandler(lastData):nil;
                                
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
