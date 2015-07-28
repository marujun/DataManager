//
//  DBObject.h
//  MCFriends
//
//  Created by marujun on 15/7/18.
//  Copyright (c) 2015年 marujun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface DBObject : NSObject

@property (nonatomic, readonly, strong) NSManagedObjectID *objectID;

- (NSArray *)properties;

- (NSDictionary *)dictionary;

- (instancetype)initWithObject:(id)object;

- (void)populateValue:(id)value forKey:(NSString *)key;

- (void)populateWithObject:(id)object;

- (void)saveTo:(NSManagedObject **)obj complete:(void (^)(BOOL success))complete;

@end
