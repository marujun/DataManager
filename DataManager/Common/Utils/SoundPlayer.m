//
//  SoundPlayer.m
//  MCFriends
//
//  Created by marujun on 14-4-25.
//  Copyright (c) 2014年 marujun. All rights reserved.
//

#import "SoundPlayer.h"

@implementation SoundPlayer

/**
 *  @brief  为播放震动效果初始化
 */
+ (instancetype)initVibratePlayer
{
    SoundPlayer *player = [[SoundPlayer alloc] init];
    player.soundID = kSystemSoundID_Vibrate;
    return player;
}


/**
 *  @brief  为播放系统音效初始化(无需提供音频文件)
 */
+ (instancetype)initSystemPlayerWithFileName:(NSString *)fileName
{
    SoundPlayer *player = [[SoundPlayer alloc] init];
    NSString *path = [NSString stringWithFormat:@"/System/Library/Audio/UISounds/%@",fileName];
    if (path) {
        SystemSoundID theSoundID;
        OSStatus error = AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:path],&theSoundID);
        
        if (error == kAudioServicesNoError) {
            player.soundID = theSoundID;
        }else {
            NSLog(@"Failed to create sound ");
        }
    }
    return player;
}

/**
 *  @brief  为播放特定的音频文件初始化（需提供音频文件）
 */
+ (instancetype)initPlayerWithFileName:(NSString *)fileName
{
    SoundPlayer *player = [[SoundPlayer alloc] init];
    NSURL *fileURL = [[NSBundle mainBundle] URLForResource:fileName withExtension:nil];
    if (fileURL != nil)
    {
        SystemSoundID theSoundID;
        OSStatus error = AudioServicesCreateSystemSoundID((__bridge CFURLRef)fileURL, &theSoundID);
        if (error == kAudioServicesNoError){
            player.soundID = theSoundID;
        }else {
            NSLog(@"Failed to create sound ");
        }
    }
    return player;
}

/**
 *  @brief  播放音效
 */
- (void)play
{
    if (_soundID == kSystemSoundID_Vibrate) {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    }else{
        if (_isPlaying) {
            return;
        }
        // 根据ID播放自定义系统声音
        AudioServicesPlaySystemSound(_soundID);
        _isPlaying = true;
        
        AudioServicesAddSystemSoundCompletion(_soundID, NULL, NULL, &playFinished, (__bridge void *)(self));
    }
}


/**
 *参数说明:
 * 1、刚刚播放完成自定义系统声音的ID
 * 2、回调函数（playFinished）执行的run Loop，NULL表示main run loop
 * 3、回调函数执行所在run loop的模式，NULL表示默认的run loop mode
 * 4、需要回调的函数
 * 5、传入的参数， 此参数会被传入回调函数里
 */
void playFinished(SystemSoundID soundId, void* clientData)
{
    SystemSoundID ID = soundId; // soundId 不能直接作为参数打印出来，需要中转一次
    
    NSLog(@"播放完成-传入ID为: %@, 传入的参数为%@", @(ID), clientData);
    
    ((__bridge SoundPlayer *)clientData).isPlaying = false;
    
    // 移除完成后执行的函数
    AudioServicesRemoveSystemSoundCompletion(ID);
}

-(void)dealloc
{
    // 根据ID释放自定义系统声音
    AudioServicesDisposeSystemSoundID(_soundID);
}

@end
