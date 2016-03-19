//
//  DBLoginUser.m
//  MCFriends
//
//  Created by 马汝军 on 15/7/19.
//  Copyright (c) 2015年 marujun. All rights reserved.
//

#import "DBLoginUser.h"
#import "AuthData.h"

@implementation DBLoginUser

- (void)synchronize
{
    [AuthData synchronize];
}

@end
