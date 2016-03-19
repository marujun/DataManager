//
//  ApplicationContext.h
//  USEvent
//
//  Created by marujun on 15/9/14.
//  Copyright (c) 2015年 MaRuJun. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ApplicationContext;

@interface ApplicationContext : DBObject

+ (instancetype)sharedContext;

/*!
 @property
 @brief 是否允许横屏
 */
@property (nonatomic, assign) BOOL enableLandscape;

/*!
 @property
 @brief 是否正在执行后台刷新
 */
@property (nonatomic, assign) BOOL fetchingInBackground;

/*!
 @property
 @brief 是否禁止侧滑
 */
@property (nonatomic, assign) BOOL disableInteractiveGesture;

/*!
 @property
 @brief 是否已跳转到其他应用，如微信、QQ、facebook、微博
 */
@property (nonatomic, assign) BOOL hasSwitchToOtherApp;

@end
