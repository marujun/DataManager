//
//  NSManagedObject+Explain.m
//  CoreDataUtil
//
//  Created by marujun on 14-1-13.
//  Copyright (c) 2014年 jizhi. All rights reserved.
//

#import "NSManagedObject+Explain.h"
#import "NLCoreData.h"


@implementation NSManagedObject (Explain)

//通过dictionary生成一个临时的object对象但不保存到数据库中
+ (instancetype)objectWithDictionary:(NSDictionary *)dictionary
{
    //    NSManagedObjectContext *tempContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    //    [tempContext setParentContext:[NSManagedObjectContext backgroundContext]];
    //    NSManagedObject *object = [self insertInContext:tempContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:[NSManagedObjectContext backgroundContext]];
    NSManagedObject *object = [[self alloc] initWithEntity:entity insertIntoManagedObjectContext:nil];
    
    [object populateWithDictionary:dictionary];
    
    return object;
}

- (void)synchronize
{
    [self syncWithComplete:nil];
}

- (void)synchronizeAndWait
{
    NSManagedObjectContext *context = [NSManagedObjectContext backgroundContext];
    [context performBlockAndWait:^{
        [context saveNested];
    }];
}

- (void)syncWithComplete:(NLCoreDataSaveCompleteBlock)block
{
    [self relateContext];
    [[self class] syncContextWithComplete:block];
}

+ (void)syncContext
{
    [self syncContextWithComplete:nil];
}

+ (void)syncContextWithComplete:(NLCoreDataSaveCompleteBlock)block
{
    NSManagedObjectContext *context = [NSManagedObjectContext backgroundContext];
    [context performBlock:^{
        BOOL success = [context saveNested];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            block ? block(success) : nil;
        });
    }];
}

- (void)relateContext
{
    if (!self.managedObjectContext) {
        /*必须放到storeContext中，在子线程中会报错：
         Child context objects become empty after merge to parent/main context*/
        [[NSManagedObjectContext storeContext] insertObject:self];
    }
}

+ (instancetype)newRelated:(NSManagedObject *)obj
{
    return [self insertInContext:obj.managedObjectContext];;
}

- (void)remove
{
    NSManagedObjectContext *context = [NSManagedObjectContext backgroundContext];
    //    [context performBlockAndWait:^{
    //        [[[self class] fetchWithObjectID:self.objectID context:context] delete];
    //        [context saveNested];
    //    }];
    
    [[[self class] fetchWithObjectID:self.objectID context:context] delete];
    [context saveNested];
}

- (NSDictionary *)dictionary
{
    NSArray *keys = [[[self entity] attributesByName] allKeys];
    return [[self dictionaryWithValuesForKeys:keys] mutableCopy];
}

- (instancetype)objectOnBgContext
{
    if (!self.managedObjectContext) {
        return self;
    }
    return [[self class] fetchWithObjectID:self.objectID context:[NSManagedObjectContext backgroundContext]];
}

- (instancetype)objectOnMainContext
{
    if (!self.managedObjectContext) {
        return self;
    }
    return [[self class] fetchWithObjectID:self.objectID context:[NSManagedObjectContext mainContext]];
}

/***异步执行任务****/
+ (void)insertObjectsAsync:(NSArray *)array complete:(void (^)(NSArray *objects))complete
{
    NSManagedObjectContext *context = [NSManagedObjectContext backgroundContext];
    [context performBlock:^{
        NSMutableArray *objects = [NSMutableArray array];
        NSManagedObject *object = nil;
        for (NSDictionary *item in array) {
            object = [self insertInContext:context];
            [object populateWithDictionary:item];
            [objects addObject:object];
        }
        [context saveNestedAsynchronousWithCallback:^(BOOL success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                complete?complete(objects):nil;
            });
        }];
    }];
}

+ (void)deleteObjectsAsync:(NSArray *)manyObject complete:(void (^)(BOOL success))complete
{
    NSManagedObjectContext *context = [NSManagedObjectContext backgroundContext];
    [context performBlock:^{
        for (NSManagedObject *object in manyObject){
            [[self fetchWithObjectID:object.objectID context:context] delete];
        }
        [context saveNestedAsynchronousWithCallback:^(BOOL success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                complete?complete(success):nil;
            });
        }];
    }];
}

+ (void)fetchAsyncWithPredicate:(id)predicateOrString complete:(void (^)(NSArray *objects))complete
{
    [self fetchAsyncWithPredicate:predicateOrString sortDescriptors:nil complete:complete];
}

+ (void)fetchAsyncWithPredicate:(id)predicateOrString sortDescriptors:(NSArray *)sortDescriptors complete:(void (^)(NSArray *objects))complete
{
    [self fetchAsyncToMainContextWithRequest:^(NSFetchRequest *request) {
        NSPredicate *predicate = predicateOrString;
        if ([predicateOrString isKindOfClass:[NSString class]]) {
            predicate = [NSPredicate predicateWithFormat:predicateOrString];
        }
        [request setPredicate:predicate];
        [request setSortDescriptors:sortDescriptors];
        
    } completion:^(NSArray *objects) {
        complete?complete(objects):nil;
    }];
}

/***同步执行任务****/
//在主线程中操作
+ (NSArray *)fetchAllObjects
{
    return [self fetchOnMainWithPredicate:nil];
}

+ (NSArray *)fetchOnMainWithPredicate:(id)predicateOrString, ...
{
    SET_PREDICATE_WITH_VARIADIC_ARGS
    return [self fetchInContext:[NSManagedObjectContext mainContext] predicate:predicate];
}

+ (NSArray *)fetchOnMainWithRequest:(void (^)(NSFetchRequest* request))block
{
    return [self fetchWithRequest:block context:[NSManagedObjectContext mainContext]];
}

+ (NSUInteger)countOnMainWithPredicate:(id)predicateOrString, ...
{
    SET_PREDICATE_WITH_VARIADIC_ARGS
    return [self countInContext:[NSManagedObjectContext mainContext] predicate:predicate];
}

//在子线程中操作
+ (instancetype)insertObjectWithDictionary:(NSDictionary *)dictionary
{
    __block NSManagedObject *object = nil;
    NSManagedObjectContext *context = [NSManagedObjectContext backgroundContext];
    //    [context performBlockAndWait:^{
    //        object = [self insertInContext:context];
    //        [object populateWithDictionary:dictionary];
    //        [context saveNested];
    //    }];
    
    object = [self insertInContext:context];
    [object populateWithDictionary:dictionary];
    [context saveNested];
    
    return object;
}

+ (NSMutableArray *)insertObjectsWithArray:(NSArray *)array
{
    __block NSManagedObject *object = nil;
    NSMutableArray *objects = [NSMutableArray array];
    
    NSManagedObjectContext *context = [NSManagedObjectContext backgroundContext];
    //    [context performBlockAndWait:^{
    //
    //    }];
    
    for (NSDictionary *item in array) {
        object = [self insertInContext:context];
        [object populateWithDictionary:item];
        [objects addObject:object];
    }
    [context saveNested];
    
    return objects;
}

+ (void)deleteObjects:(NSArray *)manyObject
{
    NSManagedObjectContext *context = [NSManagedObjectContext backgroundContext];
    //    [context performBlockAndWait:^{
    //        for (NSManagedObject *object in manyObject){
    //            [[self fetchWithObjectID:object.objectID context:context] delete];
    //        }
    //        [context saveNested];
    //    }];
    
    for (NSManagedObject *object in manyObject){
        [[self fetchWithObjectID:object.objectID context:context] delete];
    }
    [context saveNested];
}

+ (void)emptyTable
{
    NSManagedObjectContext *context = [NSManagedObjectContext backgroundContext];
    //    [context performBlockAndWait:^{
    //
    //    }];
    
    NSArray *objects = [self fetchInContext:context predicate:nil];
    for (NSManagedObject *object in objects){
        [object delete];
    }
    [context saveNested];
}

+ (NSUInteger)countOnBgWithPredicate:(id)predicateOrString, ...
{
    SET_PREDICATE_WITH_VARIADIC_ARGS
    return [self countInContext:[NSManagedObjectContext backgroundContext] predicate:predicate];
}

+ (NSArray *)fetchOnBgWithPredicate:(id)predicateOrString, ...
{
    SET_PREDICATE_WITH_VARIADIC_ARGS
    return [self fetchInContext:[NSManagedObjectContext backgroundContext] predicate:predicate];
}

+ (NSArray *)fetchOnBgWithRequest:(void (^)(NSFetchRequest* request))block
{
    return [self fetchWithRequest:block context:[NSManagedObjectContext backgroundContext]];
}



@end
