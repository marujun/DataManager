//
//  AuthData.h
//  HLMagic
//
//  Created by marujun on 14-1-8.
//  Copyright (c) 2014年 chen ying. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DBLoginUser.h"

@interface AuthData : NSData

+ (DBLoginUser *)loginUser;

+ (void)removeLoginUser;

+ (void)synchronize;
+ (void)loginSuccess:(NSDictionary *)info;

//操作当前用户在UserDefault中对应的字典
+ (id)objectForKey:(NSString *)aKey;
+ (void)setObject:(id)anObject forKey:(NSString *)aKey;
+ (void)removeObjectForKey:(NSString *)aKey;

@end
