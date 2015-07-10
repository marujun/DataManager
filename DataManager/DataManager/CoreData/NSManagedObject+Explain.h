//
//  NSManagedObject+Explain.h
//  CoreDataUtil
//
//  Created by marujun on 14-1-13.
//  Copyright (c) 2014年 jizhi. All rights reserved.
//

/*导入所有通过model生成的SubClass*/

@interface NSManagedObject (Explain)


- (NSDictionary *)dictionary;

- (void)saveAndWait;
- (void)removeAndWait;
- (void)saveWithComplete:(NLCoreDataSaveCompleteBlock)block;

- (void)relateContext;
- (instancetype)objectOnBgContext;
- (instancetype)objectOnMainContext;

+ (void)saveWithComplete:(NLCoreDataSaveCompleteBlock)block;

//在bg线程操作数据，主线程执行完成
+ (void)performBlock:(void (^)())block complete:(void (^)())complete;

//创建一个新的对象和obj对象在同一个Context中
+ (instancetype)newRelated:(NSManagedObject *)obj;

//通过dictionary生成一个临时的object对象但不保存到数据库中
+ (instancetype)objectWithDictionary:(NSDictionary *)dictionary;

/***异步执行任务****/
+ (void)insertObjectsAsync:(NSArray *)array complete:(void (^)(NSArray *objects))complete;
+ (void)deleteObjectsAsync:(NSArray *)manyObject complete:(void (^)(BOOL success))complete;
+ (void)fetchAsyncWithPredicate:(id)predicateOrString complete:(void (^)(NSArray *objects))complete;
+ (void)fetchAsyncWithPredicate:(id)predicateOrString sortDescriptors:(NSArray *)sortDescriptors complete:(void (^)(NSArray *objects))complete;

/***同步执行任务****/

//在主线程中操作
+ (NSArray *)fetchAllObjects;
+ (NSArray *)fetchOnMainWithPredicate:(id)predicateOrString, ...;
+ (NSArray *)fetchOnMainWithRequest:(void (^)(NSFetchRequest* request))block;
+ (NSUInteger)countOnMainWithPredicate:(id)predicateOrString, ...;

//在子线程中操作
+ (instancetype)insertObjectWithDictionary:(NSDictionary *)dictionary;
+ (NSMutableArray *)insertObjectsWithArray:(NSArray *)array;
+ (void)deleteObjects:(NSArray *)manyObject;
+ (void)emptyTable;

+ (NSUInteger)countOnBgWithPredicate:(id)predicateOrString, ...;
+ (NSArray *)fetchOnBgWithPredicate:(id)predicateOrString, ...;
+ (NSArray *)fetchOnBgWithRequest:(void (^)(NSFetchRequest* request))block;

@end
