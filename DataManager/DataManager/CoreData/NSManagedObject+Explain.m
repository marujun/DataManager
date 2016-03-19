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

- (NSDictionary *)dictionary
{
    NSArray *keys = [[[self entity] attributesByName] allKeys];
    return [[self dictionaryWithValuesForKeys:keys] mutableCopy];
}

- (void)saveAndWait
{
    [_backgroundContext performBlockAndWait:^{
        [_backgroundContext saveNested];
    }];
}

- (void)deleteAndWait
{
    [_backgroundContext performBlockAndWait:^{
        [[[self class] fetchWithObjectID:self.objectID context:_backgroundContext] delete];
        [_backgroundContext saveNested];
    }];
}

- (void)saveWithComplete:(NLCoreDataSaveCompleteBlock)complete
{
    [[self class] saveWithComplete:complete];
}

- (instancetype)objectInBgContext
{
    return [self objectInContext:_backgroundContext];
}

- (instancetype)objectInMainContext
{
    return [self objectInContext:_mainContext];
}

- (instancetype)objectInContext:(NSManagedObjectContext *)context
{
    if ([[self objectID] isTemporaryID]) {
        if (![self obtainPermanentID]) return nil;
    }
    
    return [[self class] fetchWithObjectID:[self objectID] context:context];
}

+ (void)saveWithComplete:(NLCoreDataSaveCompleteBlock)complete
{
    [self performBlock:nil complete:complete];
}

+ (void)performBlock:(void (^)(NSManagedObjectContext *context))block complete:(NLCoreDataSaveCompleteBlock)complete
{
    [_backgroundContext performBlock:^{
        if (block) block(_backgroundContext);
        
        [_backgroundContext saveNestedAsynchronousWithCallback:^(BOOL success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (complete) complete(success);
            });
        }];
    }];
}

+ (void)saveInPrivateQueueWithBlock:(void(^)(NSManagedObjectContext *context))block complete:(NLCoreDataSaveCompleteBlock)complete
{
    NSManagedObjectContext *localContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [localContext setParentContext:_mainContext];
    [localContext setDisplay_name:NSStringFromSelector(_cmd)];
    
    [localContext performBlock:^{
        if (block) block(localContext);
        
        [localContext saveNestedAsynchronousWithCallback:^(BOOL success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (complete) complete(success);
            });
        }];
    }];
}


//TODO：异步执行任务
+ (void)insertObjectsAsync:(NSArray *)array complete:(NLCoreDataFetchCompleteBlock)complete
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
                if (complete) complete(objects);
            });
        }];
    }];
}

+ (void)deleteObjectsAsync:(NSArray *)array complete:(NLCoreDataSaveCompleteBlock)complete
{
    NSManagedObjectContext *context = [NSManagedObjectContext backgroundContext];
    [context performBlock:^{
        for (NSManagedObject *object in array){
            [[self fetchWithObjectID:object.objectID context:context] delete];
        }
        [context saveNestedAsynchronousWithCallback:^(BOOL success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (complete) complete(success);
            });
        }];
    }];
}

+ (void)deleteAsyncWithPredicate:(id)predicateOrString complete:(NLCoreDataSaveCompleteBlock)complete
{
    NSManagedObjectContext *bgContext = [NSManagedObjectContext backgroundContext];
    NSPredicate *predicate = predicateOrString;
    if (predicateOrString && [predicateOrString isKindOfClass:[NSString class]]) {
        predicate = [NSPredicate predicateWithFormat:predicateOrString];
    }
    
    [bgContext performBlock:^{
        if ([self deleteInContext:bgContext predicate:predicate]) {
            [bgContext saveNestedAsynchronousWithCallback:^(BOOL success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (complete) complete(success);
                });
            }];
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (complete) complete(NO);
            });
        }
    }];
    
}

+ (void)updateAsyncWithPredicate:(id)predicateOrString properties:(NSDictionary *)properties complete:(NLCoreDataSaveCompleteBlock)complete
{
    NSManagedObjectContext *bgContext = [NSManagedObjectContext backgroundContext];
    NSPredicate *predicate = predicateOrString;
    if (predicateOrString && [predicateOrString isKindOfClass:[NSString class]]) {
        predicate = [NSPredicate predicateWithFormat:predicateOrString];
    }
    
    [bgContext performBlock:^{
        if ([self updateInContext:bgContext properties:properties predicate:predicate]) {
            [bgContext saveNestedAsynchronousWithCallback:^(BOOL success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (complete) complete(success);
                });
            }];
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (complete) complete(NO);
            });
        }
    }];
}

+ (void)fetchAllAsyncWithComplete:(NLCoreDataFetchCompleteBlock)complete
{
    [self fetchAsyncWithPredicate:nil sortDescriptors:nil complete:complete];
}

+ (void)fetchAsyncWithPredicate:(id)predicateOrString complete:(NLCoreDataFetchCompleteBlock)complete
{
    [self fetchAsyncWithPredicate:predicateOrString sortDescriptors:nil complete:complete];
}

+ (void)fetchAsyncWithPredicate:(id)predicateOrString sortDescriptors:(NSArray *)sortDescriptors complete:(NLCoreDataFetchCompleteBlock)complete
{
    [self fetchAsyncToMainContextWithRequest:^(NSFetchRequest *request) {
        NSPredicate *predicate = predicateOrString;
        if ([predicateOrString isKindOfClass:[NSString class]]) {
            predicate = [NSPredicate predicateWithFormat:predicateOrString];
        }
        [request setPredicate:predicate];
        [request setSortDescriptors:sortDescriptors];
        
    } completion:^(NSArray *objects) {
        if (complete) complete(objects);
    }];
}




//TODO：在主线程中操作
+ (NSUInteger)countInMainWithPredicate:(id)predicateOrString, ...
{
    SET_PREDICATE_WITH_VARIADIC_ARGS
    return [self countInContext:[NSManagedObjectContext mainContext] predicate:predicate];
}

+ (instancetype)fetchSingleInMainWithPredicate:(id)predicateOrString, ...
{
    SET_PREDICATE_WITH_VARIADIC_ARGS
    return [self fetchSingleInContext:[NSManagedObjectContext mainContext] predicate:predicate];
}

+ (instancetype)fetchOrInsertSingleInMainWithPredicate:(id)predicateOrString, ...
{
    SET_PREDICATE_WITH_VARIADIC_ARGS
    return [self fetchOrInsertSingleInContext:[NSManagedObjectContext mainContext] predicate:predicate];
}

+ (NSArray *)fetchInMainWithPredicate:(id)predicateOrString, ...
{
    SET_PREDICATE_WITH_VARIADIC_ARGS
    return [self fetchInContext:[NSManagedObjectContext mainContext] predicate:predicate];
}

+ (NSArray *)fetchInMainWithRequest:(void (^)(NSFetchRequest* request))block
{
    return [self fetchWithRequest:block context:[NSManagedObjectContext mainContext]];
}


//TODO：在子线程中操作
+ (NSUInteger)countInBgWithPredicate:(id)predicateOrString, ...
{
    SET_PREDICATE_WITH_VARIADIC_ARGS
    return [self countInContext:[NSManagedObjectContext backgroundContext] predicate:predicate];
}

+ (instancetype)fetchSingleInBgWithPredicate:(id)predicateOrString, ...
{
    SET_PREDICATE_WITH_VARIADIC_ARGS
    return [self fetchSingleInContext:[NSManagedObjectContext backgroundContext] predicate:predicate];
}

+ (instancetype)fetchOrInsertSingleInBgWithPredicate:(id)predicateOrString, ...
{
    SET_PREDICATE_WITH_VARIADIC_ARGS
    return [self fetchOrInsertSingleInContext:[NSManagedObjectContext backgroundContext] predicate:predicate];
}


+ (NSArray *)fetchInBgWithPredicate:(id)predicateOrString, ...
{
    SET_PREDICATE_WITH_VARIADIC_ARGS
    return [self fetchInContext:[NSManagedObjectContext backgroundContext] predicate:predicate];
}

+ (NSArray *)fetchInBgWithRequest:(void (^)(NSFetchRequest* request))block
{
    return [self fetchWithRequest:block context:[NSManagedObjectContext backgroundContext]];
}

@end
