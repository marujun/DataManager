//
//  USDataController.m
//  USEvent
//
//  Created by marujun on 16/1/7.
//  Copyright © 2016年 MaRuJun. All rights reserved.
//

#import "USDataController.h"

@implementation USDataController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self fInit];
    }
    return self;
}

- (void)fInit
{
    FLOG(@"init 创建类 %@", NSStringFromClass([self class]));
}

- (void)requestDataWithCompletionBlock:(USRequestCompletionBlock)completionBlock
{
    
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    FLOG(@"dealloc 释放类 %@",  NSStringFromClass([self class]));
}

@end
