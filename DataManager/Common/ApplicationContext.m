//
//  ApplicationContext.m
//  USEvent
//
//  Created by marujun on 15/9/14.
//  Copyright (c) 2015年 MaRuJun. All rights reserved.
//

#import "ApplicationContext.h"
#import "AppDelegate.h"

@interface ApplicationContext ()
{
    UINavigationController *presentNavigationController;
}

@end

@implementation ApplicationContext

+ (instancetype)sharedContext
{
    static ApplicationContext *sharedContext = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedContext = [[self alloc] init];
    });
    return sharedContext;
}

@end
