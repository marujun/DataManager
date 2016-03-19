//
//  AuthData.m
//  HLMagic
//
//  Created by marujun on 14-1-8.
//  Copyright (c) 2014年 chen ying. All rights reserved.
//

#import "AuthData.h"

static DBLoginUser *loginUser;

@implementation AuthData

+ (DBLoginUser *)loginUser
{
    if (!loginUser) {
        NSDictionary *info = [userDefaults objectForKey:@"LoginUser"];
        if (info) {
            loginUser = [[DBLoginUser alloc] initWithObject:info];
        }
    }
    return loginUser;
}

+ (void)removeLoginUser
{
    loginUser = nil;
    [self synchronize];
}

+ (void)loginSuccess:(NSDictionary *)info
{
    loginUser = [[DBLoginUser alloc] initWithObject:info];
    [self synchronize];
    
    //通知其他页面刷新数据
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LoginSuccess" object:nil];
}

+ (void)synchronize
{
    if (loginUser) {
        [userDefaults setObject:[loginUser dictionary] forKey:@"LoginUser"];
    } else {
        [userDefaults removeObjectForKey:@"LoginUser"];
    }
    
    [userDefaults synchronize];
}

+ (NSDictionary *)authData
{
    NSMutableDictionary *allAuthData = [[userDefaults objectForKey:@"AllAuthData"] mutableCopy];
    if (allAuthData) {
        NSString *userId = @"0";
        if (loginUser) {
            userId = [loginUser uid];
        }
        NSMutableDictionary *userAuthData = [[allAuthData objectForKey:userId] mutableCopy];
        return userAuthData.copy;
    }
    return nil;
}

+ (id)objectForKey:(NSString *)aKey
{
    id value = nil;
    @try {
        NSMutableDictionary *userAuthData = [[AuthData authData] mutableCopy];
        if(userAuthData){
            value = [userAuthData objectForKey:aKey];
        }
        value = [self defaultValue:value key:aKey];
    }
    @catch (NSException *exception) {
        NSLog(@"%s [Line %d] exception:\n%@",__PRETTY_FUNCTION__, __LINE__,exception);
    }
    return value;
}

+ (id)defaultValue:(id)value key:(NSString *)key
{
    if (value == nil) {
        
    }
    return value;
}

+ (void)setObject:(id)anObject forKey:(NSString *)aKey
{
    @try {
        [AuthData operateUserData:^(NSMutableDictionary *userData) {
            [userData setValue:anObject forKey:aKey];
        }];
    }
    @catch (NSException *exception) {
        NSLog(@"%s [Line %d] exception:\n%@",__PRETTY_FUNCTION__, __LINE__,exception);
    }
}

+ (void)removeObjectForKey:(NSString *)aKey
{
    @try {
        [AuthData operateUserData:^(NSMutableDictionary *userData) {
            [userData removeObjectForKey:aKey];
        }];
    }
    @catch (NSException *exception) {
        NSLog(@"%s [Line %d] exception:\n%@",__PRETTY_FUNCTION__, __LINE__,exception);
    }
}

+ (void)operateUserData:(void (^)(NSMutableDictionary *userData))callback
{
    NSMutableDictionary *allAuthData = [[userDefaults objectForKey:@"AllAuthData"] mutableCopy];
    if (!allAuthData) {
        allAuthData = [[NSMutableDictionary alloc] init];
    }
    NSString *userId = @"0";
    if (loginUser) {
        userId = [loginUser uid];
    }
    NSMutableDictionary *userAuthData = [[allAuthData objectForKey:userId] mutableCopy];
    if(!userAuthData){
        userAuthData = [[NSMutableDictionary alloc] init];
    }
    
    //执行回调 
    callback ? callback(userAuthData) : nil;
    
    [allAuthData setValue:userAuthData forKey:userId];
    
    [userDefaults setValue:allAuthData forKey:@"AllAuthData"];
    [userDefaults synchronize];
}

@end
