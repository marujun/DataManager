//
//  UIDevice(Common).h
//  UIDeviceAddition
//
//  Created by Georg Kitz on 20.08.11.
//  Copyright 2011 Aurora Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIDevice (Common)

/**广告标识符 */
+ (NSString *)idfa;

+ (NSString *)idfv;

/** 是否越狱 */
+ (BOOL)jailbroken;

/** 是否被破解 */
+ (BOOL)isCracked;

+ (NSString *)chinaMobileModel;
+ (NSString *)IPv4;
+ (NSString *)IPv6;
+ (NSString *)deviceName;
+ (NSString *)deviceModel;

/** 已连接的wifi信息 */
+ (NSDictionary *)wifiInfo;

/** 是否已插入耳机 */
+ (BOOL)headphonesConnected;

/** 是否开启了Airplay */
+ (BOOL)isAirplayActived;

/** 是否已开启麦克风权限 */
+ (void)recordPermission:(void (^)(BOOL granted))response;


/** 剩余内存大小的格式化字符串 */
+ (NSString *)freeMemory;

/** 已使用内存大小的格式化字符串 */
+ (NSString *)usedMemory;

/** 剩余内存大小（单位：Bytes）*/
+ (vm_size_t)freeMemoryInBytes;

/** 已使用内存大小（单位：Bytes）*/
+ (vm_size_t)usedMemoryInBytes;

/** 总的磁盘空间大小的格式化字符串 */
+ (NSString *)totalDiskSpace;

/** 剩余磁盘空间大小的格式化字符串 */
+ (NSString *)freeDiskSpace;

/** 已使用磁盘空间大小的格式化字符串 */
+ (NSString *)usedDiskSpace;

/** 总的磁盘空间大小（单位：Bytes）*/
+ (CGFloat)totalDiskSpaceInBytes;

/** 剩余磁盘空间大小（单位：Bytes）*/
+ (CGFloat)freeDiskSpaceInBytes;

/** 已使用磁盘空间大小（单位：Bytes）*/
+ (CGFloat)usedDiskSpaceInBytes;

@end
