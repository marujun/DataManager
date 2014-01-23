//
//  NSManagedObject+Magic.m
//  CoreDataUtil
//
//  Created by marujun on 14-1-13.
//  Copyright (c) 2014年 jizhi. All rights reserved.
//

#import "NSManagedObject+Magic.h"
#import "CoreDataUtil.h"

@implementation NSSet (TCNSManagedObjectMethods)
- (NSArray *)sortObjects
{
    return [[self allObjects] sortedArrayUsingComparator:^NSComparisonResult(NSManagedObject *obj1, NSManagedObject *obj2) {
        if (obj1.index.intValue > obj2.index.intValue) {
            return (NSComparisonResult)NSOrderedDescending;
        }else if (obj1.index.intValue < obj2.index.intValue){
            return NSOrderedAscending;
        }
        return NSOrderedSame;
    }];
}
@end

extern NSManagedObjectContext *globalManagedObjectContext;
extern NSManagedObjectModel *globalManagedObjectModel;

@implementation NSManagedObject (Magic)

+ (NSArray *)getTable:(NSString *)tableName
{
    NSArray *resultArr = [NSManagedObject getTable_sync:tableName predicate:nil];
    return (resultArr && resultArr.count != 0)?resultArr:nil;
}

+ (void)cleanTable:(NSString *)tableName
{
    NSArray *array = [self getTable_sync:tableName predicate:nil];
    [self deleteObject_sync:array];
}

@end
