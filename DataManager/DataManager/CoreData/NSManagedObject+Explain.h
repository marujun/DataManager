//
//  NSManagedObject+Explain.h
//  CoreDataUtil
//
//  Created by marujun on 14-1-13.
//  Copyright (c) 2014年 jizhi. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (Explain)

@property (nonatomic, retain) NSNumber * index;

//异步执行任务
+ (void)addObject_async:(NSDictionary *)dictionary toTable:(NSString *)tableName complete:(void (^)(NSManagedObject *object))complete;
+ (void)addObjectsFromArray_async:(NSArray *)otherArray  toTable:(NSString *)tableName complete:(void (^)(NSArray *resultArray))complete;
+ (void)deleteObjects_async:(NSArray *)manyObject complete:(void (^)(BOOL success))complete;
+ (void)updateTable_async:(NSString *)tableName predicate:(NSPredicate *)predicate params:(NSDictionary *)params complete:(void (^)(NSArray *resultArray))complete;
+ (void)updateObject_async:(NSManagedObject *)object params:(NSDictionary *)params complete:(void (^)(NSManagedObject *object))complete;
+ (void)getTable_async:(NSString *)tableName predicate:(NSPredicate *)predicate complete:(void (^)(NSArray *result))complete;
+ (void)getTable_async:(NSString *)tableName callback:(void (^)(NSFetchRequest *request))callback complete:(void (^)(NSArray *result))complete;
+ (void)getTable_async:(NSString *)tableName predicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors complete:(void (^)(NSArray *result))complete;

//同步执行任务
+ (NSManagedObject *)addObject_sync:(NSDictionary *)dictionary toTable:(NSString *)tableName;
+ (NSArray *)addObjectsFromArray_sync:(NSArray *)otherArray  toTable:(NSString *)tableName;
+ (BOOL)deleteObjects_sync:(NSArray *)manyObject;
+ (NSArray *)updateTable_sync:(NSString *)tableName predicate:(NSPredicate *)predicate params:(NSDictionary *)params;
+ (NSManagedObject *)updateObject_sync:(NSManagedObject *)object params:(NSDictionary *)params;
+ (NSArray *)getTable_sync:(NSString *)tableName predicate:(NSPredicate *)predicate;
+ (NSArray *)getTable_sync:(NSString *)tableName callback:(void (^)(NSFetchRequest *request))callback;
+ (NSArray *)getTable_sync:(NSString *)tableName predicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors;

//是否在异步队列中操作数据库
+ (void)asyncQueue:(BOOL)async actions:(void (^)(void))actions;

@end
