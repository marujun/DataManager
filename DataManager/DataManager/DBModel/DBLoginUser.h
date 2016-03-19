//
//  DBLoginUser.h
//  MCFriends
//
//  Created by 马汝军 on 15/7/19.
//  Copyright (c) 2015年 marujun. All rights reserved.
//

typedef enum {
    GENDER_WOMEN = 0,
    GENDER_MAN,
    GENDER_NONE
} GENDER;

@interface DBLoginUser : DBObject

@property (nonatomic, retain) NSString * avatar;
@property (nonatomic, retain) NSString * birthday;
@property (nonatomic, retain) NSMutableDictionary * extra;
@property (nonatomic, retain) NSString * nickname;
@property (nonatomic, assign) GENDER gender;
@property (nonatomic, retain) NSString * uid;

@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain, readonly) NSString * session_key;

- (void)synchronize;

@end
