//
//  User.h
//  CoreDataUtil
//
//  Created by marujun on 14-1-16.
//  Copyright (c) 2014年 马汝军. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BaseObject.h"

@class Bank;

@interface User : BaseObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * age;
@property (nonatomic, retain) NSNumber * gender;
@property (nonatomic, retain) NSSet *bank;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addBankObject:(Bank *)value;
- (void)removeBankObject:(Bank *)value;
- (void)addBank:(NSSet *)values;
- (void)removeBank:(NSSet *)values;

@end
