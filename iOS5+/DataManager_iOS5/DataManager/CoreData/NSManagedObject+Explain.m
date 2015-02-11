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
    NSEntityDescription *entity = [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:[NSManagedObjectContext storeContext]];
    NSManagedObject *object = [[self alloc] initWithEntity:entity insertIntoManagedObjectContext:nil];
    
    [object populateWithDictionary:dictionary];
    
    return object;
}

- (NSDictionary *)dictionary
{
    NSArray *keys = [[[self entity] attributesByName] allKeys];
    return [[self dictionaryWithValuesForKeys:keys] mutableCopy];
}

- (void)saveAndWait
{
    [self relateContext];
    [[NSManagedObjectContext backgroundContext] saveNested];
}

- (void)removeAndWait
{
    NSManagedObjectContext *context = [NSManagedObjectContext backgroundContext];
    
    [[[self class] fetchWithObjectID:self.objectID context:context] delete];
    [context saveNested];
}

- (void)saveWithComplete:(NLCoreDataSaveCompleteBlock)block
{
    [self relateContext];
    [[self class] saveWithComplete:block];
}

- (void)relateContext
{
    if (!self.managedObjectContext) {
        /*必须放到storeContext中，在子线程中会报错：
         Child context objects become empty after merge to parent/main context*/
        [[NSManagedObjectContext storeContext] insertObject:self];
    }
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


+ (instancetype)newRelated:(NSManagedObject *)obj
{
    return [self insertInContext:obj.managedObjectContext];;
}

+ (void)saveWithComplete:(NLCoreDataSaveCompleteBlock)block
{
    NSManagedObjectContext *context = [NSManagedObjectContext backgroundContext];
    [context performBlock:^{
        [context saveNestedAsynchronousWithCallback:^(BOOL success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block ? block(success) : nil;
            });
        }];
    }];
}


//在bg线程操作数据，主线程执行完成
+ (void)performBlock:(void (^)())block complete:(void (^)())complete
{
    NSManagedObjectContext* mainContext	= [NSManagedObjectContext mainContext];
    NSManagedObjectContext* bgContext	= [NSManagedObjectContext backgroundContext];
    [bgContext performBlock:^{
        block?block():nil;
        
        [bgContext saveNestedAsynchronousWithCallback:^(BOOL success) {
            [mainContext performBlock:^{
                
                complete?complete():nil;
            }];
        }];
    }];
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
    NSManagedObjectContext *context = [NSManagedObjectContext backgroundContext];
    
    NSManagedObject *object = [self insertInContext:context];
    [object populateWithDictionary:dictionary];
    [context saveNested];
    
    return object;
}

+ (NSMutableArray *)insertObjectsWithArray:(NSArray *)array
{
    NSManagedObject *object = nil;
    NSMutableArray *objects = [NSMutableArray array];
    
    NSManagedObjectContext *context = [NSManagedObjectContext backgroundContext];
    
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
    for (NSManagedObject *object in manyObject){
        [[self fetchWithObjectID:object.objectID context:context] delete];
    }
    [context saveNested];
}

+ (void)emptyTable
{
    NSManagedObjectContext *context = [NSManagedObjectContext backgroundContext];
    
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
