//
//  Bank.h
//  DataManager_iOS5
//
//  Created by marujun on 14/11/28.
//  Copyright (c) 2014年 marujun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Bank : NSManagedObject

@property (nonatomic, retain) NSString * account;
@property (nonatomic, retain) User *user;

@end
