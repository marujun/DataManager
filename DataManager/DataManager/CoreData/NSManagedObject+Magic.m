//
//  NSManagedObject+Magic.m
//  CoreDataUtil
//
//  Created by marujun on 14-1-13.
//  Copyright (c) 2014年 jizhi. All rights reserved.
//

#import "NSManagedObject+Magic.h"
#import "CoreDataUtil.h"

extern NSManagedObjectContext *globalManagedObjectContext_util;
extern NSManagedObjectModel *globalManagedObjectModel_util;

@implementation NSManagedObject (Magic)

+ (NSArray *)getTable:(NSString *)tableName
{
    NSArray *resultArr = [NSManagedObject getTable_sync:tableName predicate:nil];
    return (resultArr && resultArr.count != 0)?resultArr:nil;
}

+ (void)cleanTable:(NSString *)tableName
{
    NSArray *array = [self getTable_sync:tableName predicate:nil];
    [self deleteObjects_sync:array];
}

@end
