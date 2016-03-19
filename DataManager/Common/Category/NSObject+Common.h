//
//  NSObject+Common.h
//  MCFriends
//
//  Created by marujun on 14-7-7.
//  Copyright (c) 2014年 marujun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Common)

//去掉 json 中的多余的 null
- (id)cleanNull;

- (NSString *)stringValue;

- (id)performSelector:(SEL)aSelector withArguments:(id)arg, ... NS_REQUIRES_NIL_TERMINATION;


@end
