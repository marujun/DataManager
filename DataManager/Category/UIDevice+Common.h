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


//广告标识符
+ (NSString *)idfa;

//MAC地址（iOS7以后默认返回02:00:00:00:00:00）
+ (NSString *)macAddress;

//是否越狱
+ (BOOL)jailbroken;

//是否被破解
+ (BOOL)isCracked;

+ (NSString *)chinaMobileModel;
+ (NSString *)IPv4;
+ (NSString *)IPv6;
+ (NSString *)deviceName;
+ (NSString *)deviceModel;


//是否已插入耳机
+ (BOOL)headphonesConnected;

//是否开启了Airplay
+ (BOOL)isAirplayActived;

//是否已开启麦克风权限
+ (void)recordPermission:(void (^)(BOOL granted))response;
// 获取当前设备可用内存(单位：MB）
+ (double)availableMemory;
// 获取当前任务所占用的内存（单位：MB）
+ (double)usedMemory;
@end
