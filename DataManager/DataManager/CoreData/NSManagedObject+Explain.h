//
//  NSManagedObject+Explain.h
//  CoreDataUtil
//
//  Created by marujun on 14-1-13.
//  Copyright (c) 2014年 jizhi. All rights reserved.
//

/*导入所有通过model生成的SubClass*/

typedef void(^NLCoreDataFetchCompleteBlock)(NSArray *objects);

@interface NSManagedObject (Explain)

- (NSDictionary *)dictionary;

- (void)saveAndWait;
- (void)deleteAndWait;
- (void)saveWithComplete:(NLCoreDataSaveCompleteBlock)complete;

- (instancetype)objectInBgContext;
- (instancetype)objectInMainContext;
- (instancetype)objectInContext:(NSManagedObjectContext *)context;

/** 保存BackgroundContext里的数据变化，主线程执行完成回调 */
+ (void)saveWithComplete:(NLCoreDataSaveCompleteBlock)complete;

/** 在BackgroundContext里操作数据，主线程执行完成回调 */
+ (void)performBlock:(void (^)(NSManagedObjectContext *context))block complete:(NLCoreDataSaveCompleteBlock)complete;

/** 创建一个private queue context，然后在该context中保存。一般情况下不要使用这个方法！！！ */
+ (void)saveInPrivateQueueWithBlock:(void(^)(NSManagedObjectContext *localContext))block complete:(NLCoreDataSaveCompleteBlock)complete;

//TODO：异步执行任务
+ (void)insertObjectsAsync:(NSArray *)array complete:(NLCoreDataFetchCompleteBlock)complete;
+ (void)deleteObjectsAsync:(NSArray *)array complete:(NLCoreDataSaveCompleteBlock)complete;
+ (void)deleteAsyncWithPredicate:(id)predicateOrString complete:(NLCoreDataSaveCompleteBlock)complete;
+ (void)updateAsyncWithPredicate:(id)predicateOrString properties:(NSDictionary *)properties complete:(NLCoreDataSaveCompleteBlock)complete;
+ (void)fetchAllAsyncWithComplete:(NLCoreDataFetchCompleteBlock)complete;
+ (void)fetchAsyncWithPredicate:(id)predicateOrString complete:(NLCoreDataFetchCompleteBlock)complete;
+ (void)fetchAsyncWithPredicate:(id)predicateOrString sortDescriptors:(NSArray *)sortDescriptors complete:(NLCoreDataFetchCompleteBlock)complete;

//TODO：在主线程中操作
+ (NSUInteger)countInMainWithPredicate:(id)predicateOrString, ...;
+ (instancetype)fetchSingleInMainWithPredicate:(id)predicateOrString, ...;
+ (instancetype)fetchOrInsertSingleInMainWithPredicate:(id)predicateOrString, ...;
+ (NSArray *)fetchInMainWithPredicate:(id)predicateOrString, ...;
+ (NSArray *)fetchInMainWithRequest:(void (^)(NSFetchRequest* request))block;

//TODO：在子线程中操作
+ (NSUInteger)countInBgWithPredicate:(id)predicateOrString, ...;
+ (instancetype)fetchSingleInBgWithPredicate:(id)predicateOrString, ...;
+ (instancetype)fetchOrInsertSingleInBgWithPredicate:(id)predicateOrString, ...;
+ (NSArray *)fetchInBgWithPredicate:(id)predicateOrString, ...;
+ (NSArray *)fetchInBgWithRequest:(void (^)(NSFetchRequest* request))block;

@end
