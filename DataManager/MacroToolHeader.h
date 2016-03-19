//
//  MacroToolHeader.h
//  HappyIn
//
//  Created by marujun on 16/3/2.
//  Copyright © 2016年 MaRuJun. All rights reserved.
//

#import "AuthData.h"
#import "ApplicationContext.h"

#ifndef MacroToolHeader_h
#define MacroToolHeader_h

#define IS_IPAD              (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE            (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_RETINA            ([[UIScreen mainScreen] scale] >= 2.0)

#define SCREEN_WIDTH         [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT        [[UIScreen mainScreen] bounds].size.height
#define SCREEN_MAX_LENGTH    (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define SCREEN_MIN_LENGTH    (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))


#define IS_IPHONE_4          (IS_IPHONE && SCREEN_MAX_LENGTH < 568.0)
#define IS_IPHONE_5          (IS_IPHONE && SCREEN_MAX_LENGTH == 568.0)
#define IS_IPHONE_6          (IS_IPHONE && SCREEN_MAX_LENGTH == 667.0)
#define IS_IPHONE_6P         (IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)


#define userDefaults        [NSUserDefaults standardUserDefaults]
#define KeyWindow           [[[UIApplication sharedApplication] delegate] window]
#define WindowZoomScale     (SCREEN_WIDTH/320.f)
#define UniversalZoomScale  (MIN(1.8, WindowZoomScale))  //适配iPad

#define DocumentPath        [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]    //获取Document文件夹的路径
#define ResourcePath        [[NSBundle mainBundle] resourcePath]    //获取自定义文件的bundle路径
#define ImageNamed(name)    [UIImage imageWithContentsOfFile:[ResourcePath stringByAppendingPathComponent:name]]
#define RGBCOLOR(r,g,b)     [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]         //RGB进制颜色值
#define RGBACOLOR(r,g,b,a)  [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:(a)]       //RGBA进制颜色值
#define HexColor(hexValue)  [UIColor colorWithRed:((float)(((hexValue) & 0xFF0000) >> 16))/255.0 green:((float)(((hexValue) & 0xFF00) >> 8))/255.0 blue:((float)((hexValue) & 0xFF))/255.0 alpha:1]   //16进制颜色值，如：#000000 , 注意：在使用的时候hexValue写成：0x000000

#define XcodeBundleVersion  [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]


#define _loginUser          [AuthData loginUser]
#define _applicationContext [ApplicationContext sharedContext]

#ifdef DEBUG
    #define USTakeTimeCountBegin       NSDate *takeTimeCountDate = [NSDate date];
    #define USTakeTimeCountEnd(flag)   DLOG(@"%@耗时 %.4f 秒",flag,[[NSDate date] timeIntervalSinceDate:takeTimeCountDate]);
#else
    #define USTakeTimeCountBegin       ((void)0);
    #define USTakeTimeCountEnd(flag)   ((void)0);
#endif

#ifdef DEBUG
#define FLOG(fmt,...)    NSLog((@"[%@][%d] " fmt),[[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__,##__VA_ARGS__)
#else
#define FLOG(str, args...) ((void)0)
#endif


//获取随机数
#define Random(from, to) (int)(from + (arc4random() % (to - from + 1))); //+1,result is [from to]; else is [from, to)!!!!!!!
#define ARC4RANDOM_MAX (0x100000000 * 20)


/**
 Synthsize a weak or strong reference.
 
 Example:
    @weakify(self)
    [self doSomething^{
        @strongify(self)
        if (!self) return;
        ...
    }];
 
 */
#ifndef weakify
    #if DEBUG
        #if __has_feature(objc_arc)
        #define weakify(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
        #else
        #define weakify(object) autoreleasepool{} __block __typeof__(object) block##_##object = object;
        #endif
    #else
        #if __has_feature(objc_arc)
        #define weakify(object) try{} @finally{} {} __weak __typeof__(object) weak##_##object = object;
        #else
        #define weakify(object) try{} @finally{} {} __block __typeof__(object) block##_##object = object;
        #endif
    #endif
#endif

#ifndef strongify
    #if DEBUG
        #if __has_feature(objc_arc)
        #define strongify(object) autoreleasepool{} __typeof__(object) object = weak##_##object;
        #else
        #define strongify(object) autoreleasepool{} __typeof__(object) object = block##_##object;
        #endif
    #else
        #if __has_feature(objc_arc)
        #define strongify(object) try{} @finally{} __typeof__(object) object = weak##_##object;
        #else
        #define strongify(object) try{} @finally{} __typeof__(object) object = block##_##object;
        #endif
    #endif
#endif



#endif /* MacroToolHeader_h */
