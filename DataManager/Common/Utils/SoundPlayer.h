//
//  SoundPlayer.h
//  MCFriends
//
//  Created by marujun on 14-4-25.
//  Copyright (c) 2014年 marujun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface SoundPlayer : NSObject


@property (nonatomic, assign) SystemSoundID soundID;
@property (nonatomic, assign) BOOL isPlaying;


/**
 *  @brief  为播放震动效果初始化
 *
 *  @return self
 */
+ (instancetype)initVibratePlayer;

/**
 *  @brief  为播放系统音效初始化(无需提供音频文件)
 *
 *  SoundID 类型 http://iphonedevwiki.net/index.php/AudioService
 *
 *  @param fileName 系统音效名称
 *
 *  @return self
 */
+ (instancetype)initSystemPlayerWithFileName:(NSString *)fileName;

/**
 *  @brief  为播放特定的音频文件初始化（需提供音频文件）
 *
 *  @param fileName 音频文件名（加在工程中）
 *
 *  @return self
 */
+ (instancetype)initPlayerWithFileName:(NSString *)fileName;

/**
 *  @brief  播放音效
 */
- (void)play;

@end
