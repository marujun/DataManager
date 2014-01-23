//
//  NSManagedObject+Explain.m
//  CoreDataUtil
//
//  Created by marujun on 14-1-13.
//  Copyright (c) 2014年 jizhi. All rights reserved.
//

#import "NSManagedObject+Explain.h"
#import "CoreDataUtil.h"

#define SuppressPerformSelectorLeakWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)

static dispatch_queue_t myCustomQueue;

extern NSManagedObjectContext *globalManagedObjectContext;
extern NSManagedObjectModel *globalManagedObjectModel;

@implementation NSManagedObject (Explain)
@dynamic index;

//异步执行任务
+ (void)addObject_async:(NSDictionary *)dictionary  toTable:(NSString *)tableName complete:(void (^)(NSManagedObject *object))complete
{
    [self asyncQueue:true actions:^{
        __block NSManagedObject *oneObject = [self addObject:dictionary toTable:tableName];
        [self save:^(NSError *error) { error?oneObject=nil:nil; }];
        if (complete) {
            complete(oneObject);
        }
    }];
}
+ (void)addObjectsFromArray_async:(NSArray *)otherArray  toTable:(NSString *)tableName complete:(void (^)(NSArray *resultArray))complete
{
    [self asyncQueue:true actions:^{
        __block NSArray *resultArray = [self addObjectsFromArray:otherArray toTable:tableName];
        [self save:^(NSError *error) { error?resultArray=nil:nil; }];
        if (complete) {
            complete(resultArray);
        }
    }];
}
+ (void)deleteObject_async:(NSArray *)manyObject complete:(void (^)(BOOL success))complete
{
    [self asyncQueue:true actions:^{
        [self deleteObject:manyObject];
        __block BOOL success = true;
        [self save:^(NSError *error) { error?success=false:true; }];
        if (complete) {
            complete(success);
        }
    }];
}
+ (void)updateTable_async:(NSString *)tableName predicate:(NSPredicate *)predicate params:(NSDictionary *)params complete:(void (^)(NSArray *resultArray))complete
{
    [self asyncQueue:true actions:^{
        __block NSArray *resultArray = [self updateTable:tableName predicate:predicate params:params];
        [self save:^(NSError *error) { error?resultArray=nil:nil; }];
        if (complete) {
            complete(resultArray);
        }
    }];
}
+ (void)updateObject_async:(NSManagedObject *)object params:(NSDictionary *)params complete:(void (^)(NSManagedObject *object))complete
{
    [self asyncQueue:true actions:^{
        __block NSManagedObject *oneObject = [self updateObject:object params:params];
        [self save:^(NSError *error) { error?oneObject=nil:nil; }];
        if (complete) {
            complete(oneObject);
        }
    }];
}
+ (void)getTable_async:(NSString *)tableName predicate:(NSPredicate *)predicate complete:(void (^)(NSArray *result))complete
{
    [self asyncQueue:true actions:^{
        NSArray *resultArr = [self getTable:tableName predicate:predicate];
        if (complete) {
            complete(resultArr);
        }
    }];
}

//同步执行任务
+ (NSManagedObject *)addObject_sync:(NSDictionary *)dictionary  toTable:(NSString *)tableName
{
    __block NSManagedObject *oneObject = nil;
    [self asyncQueue:false actions:^{
        oneObject = [self addObject:dictionary toTable:tableName];
        [self save:^(NSError *error) { error?oneObject=nil:nil; }];
    }];
    return oneObject;
}
+ (NSArray *)addObjectsFromArray_sync:(NSArray *)otherArray  toTable:(NSString *)tableName
{
    __block NSArray *resultArr = nil;
    [self asyncQueue:false actions:^{
        resultArr = [self addObjectsFromArray:otherArray toTable:tableName];
        [self save:^(NSError *error) { error?resultArr=nil:nil; }];
    }];
    return resultArr;
}
+ (BOOL)deleteObject_sync:(NSArray *)manyObject
{
    __block BOOL success = true;
    [self asyncQueue:false actions:^{
        [self deleteObject:manyObject];
        [self save:^(NSError *error) { error?success=false:true; }];
    }];
    return success;
}
+ (NSArray *)updateTable_sync:(NSString *)tableName predicate:(NSPredicate *)predicate params:(NSDictionary *)params
{
    __block NSArray *resultArray = nil;
    [self asyncQueue:false actions:^{
        resultArray = [self updateTable:tableName predicate:predicate params:params];
        [self save:^(NSError *error) { error?resultArray=nil:nil; }];
    }];
    return resultArray;
}
+ (NSManagedObject *)updateObject_sync:(NSManagedObject *)object params:(NSDictionary *)params
{
    __block NSManagedObject *oneObject = nil;
    [self asyncQueue:false actions:^{
        oneObject = [self updateObject:object params:params];
        [self save:^(NSError *error) { error?oneObject=nil:nil; }];
    }];
    return oneObject;
}
+ (NSArray *)getTable_sync:(NSString *)tableName predicate:(NSPredicate *)predicate
{
    __block NSArray *resultArr = nil;
    [self asyncQueue:false actions:^{
        resultArr = [self getTable:tableName predicate:predicate];
    }];
    return resultArr;
}

//扩展方法
+ (NSString *)upHeadString:(NSString *)string
{
    return [[[string substringToIndex:1] uppercaseString] stringByAppendingString:[string substringFromIndex:1]];
}
- (void)setContentDictionary:(NSDictionary *)dictionary
{
    for (NSString *key in [dictionary allKeys])
    {
        id value = [dictionary objectForKey:key];
        
        if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSDate class]]){
            @try {
                [self setValue:value forKey:key];
            }
            @catch (NSException *exception) {
                NSLog(@"解析基本类型出错了-->%@",exception);
            }
            @finally {
            }
            
        }else if ([value isKindOfClass:[NSDictionary class]]){
            @try {
                NSEntityDescription *entityDescirp = [NSEntityDescription entityForName:NSStringFromClass([self class]) inManagedObjectContext:globalManagedObjectContext];
                NSRelationshipDescription *relationshipDescrip = [entityDescirp.relationshipsByName objectForKey:key];
                NSString *tableName = relationshipDescrip.destinationEntity.name;
                
                NSManagedObject *object = [NSManagedObject addObject:value toTable:tableName];
                
                [self setValue:object forKey:key];
            }
            @catch (NSException *exception) {
                NSLog(@"解析字典出错了-->%@",exception);
            }
            @finally {
            }
        }else if ([value isKindOfClass:[NSArray class]]){
            
            @try {
                int index = 0;
                
                for (NSDictionary *oneJsonObject in value)
                {
                    NSEntityDescription *entiDescirp = [NSEntityDescription entityForName:NSStringFromClass([self class]) inManagedObjectContext:globalManagedObjectContext];
                    NSRelationshipDescription *relationshipDescrip = [entiDescirp.relationshipsByName objectForKey:key];
                    NSString *tableName = relationshipDescrip.destinationEntity.name;
                    
                    NSManagedObject *object = [NSManagedObject addObject:oneJsonObject toTable:tableName];
                    if ([object respondsToSelector:@selector(setIndex:)]) {
                        object.index = [NSNumber numberWithInt:index];
                    }
                    SEL addSelector = NSSelectorFromString([NSString stringWithFormat:@"add%@Object:",[NSManagedObject upHeadString:key]]);
                    SuppressPerformSelectorLeakWarning([self performSelector:addSelector withObject:object]);

                    index++;
                }
            }
            @catch (NSException *exception) {
                NSLog(@"解析数组出错了-->%@",exception);
            }
            @finally {
            }
        }
    }
}

//在当前队列执行任务
+ (NSManagedObject *)addObject:(NSDictionary *)dictionary  toTable:(NSString *)tableName
{
    NSManagedObject *oneObject = nil;
    
    Class class = NSClassFromString(tableName);
    
    NSEntityDescription *entityDescrip = [[globalManagedObjectModel entitiesByName] objectForKey:tableName];
    oneObject = [[class alloc] initWithEntity:entityDescrip insertIntoManagedObjectContext:globalManagedObjectContext];
    [oneObject setContentDictionary:dictionary];
    return oneObject;
}

+ (NSArray *)addObjectsFromArray:(NSArray *)otherArray  toTable:(NSString *)tableName
{
    NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    
    Class class = NSClassFromString(tableName);
    NSEntityDescription *entityDescrip = [[globalManagedObjectModel entitiesByName] objectForKey:tableName];
    
    for (NSDictionary *dictionary in otherArray)
    {
        NSManagedObject *oneObject = [[class alloc] initWithEntity:entityDescrip insertIntoManagedObjectContext:globalManagedObjectContext];
        [oneObject setContentDictionary:dictionary];
        
        [resultArray addObject:oneObject];
    }
    return [resultArray copy];
}

+ (void)deleteObject:(NSArray *)manyObject
{
    for (NSManagedObject *object in manyObject)
    {
        [globalManagedObjectContext deleteObject:object];
    }
}

+ (NSArray *)updateTable:(NSString *)tableName predicate:(NSPredicate *)predicate params:(NSDictionary *)params
{
    //查询数据
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    NSEntityDescription *description = [NSEntityDescription entityForName:tableName inManagedObjectContext:globalManagedObjectContext];
    [request setEntity:description];
    if (predicate) {
        [request setPredicate:predicate];
    }
    
    NSArray *queryArr = [globalManagedObjectContext executeFetchRequest:request error:nil];
    //有匹配的记录时则更新记录
    if(queryArr && queryArr.count){
        for (NSManagedObject *object in queryArr)
        {
            [self updateObject:object params:params];
        }
    } else //没有匹配的记录时添加记录
    {
        [self addObject:params toTable:tableName];
        queryArr = [globalManagedObjectContext executeFetchRequest:request error:nil];
    }
    return queryArr;
}

+ (NSManagedObject *)updateObject:(NSManagedObject *)object params:(NSDictionary *)params
{
    for (NSString *key in params.allKeys)
    {
        id value = [params objectForKey:key];
        
        if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSDate class]]){
            @try {
                [object setValue:value forKey:key];
            }
            @catch (NSException *exception) {
                NSLog(@"key值出错了-->%@",exception);
            }
            @finally {
            }
            
        }else if ([value isKindOfClass:[NSDictionary class]]){
            @try {
                NSManagedObject *otherObject = [object valueForKey:key];
                if(otherObject){
                    [self updateObject:otherObject params:value];
                }else{
                    NSEntityDescription *entityDescirp = [NSEntityDescription entityForName:NSStringFromClass([self class]) inManagedObjectContext:globalManagedObjectContext];
                    NSRelationshipDescription *relationshipDescrip = [entityDescirp.relationshipsByName objectForKey:key];
                    NSString *tableName = relationshipDescrip.destinationEntity.name;
                    
                    otherObject = [NSManagedObject addObject:value toTable:tableName];
                    [object setValue:otherObject forKey:key];
                }
            }
            @catch (NSException *exception) {
                NSLog(@"解析字典出错了-->%@",exception);
            }
            @finally {
            }
        }else if ([value isKindOfClass:[NSArray class]]){
            @try {
                NSArray *objectArray = [[object valueForKey:key] allObjects];
                
                for (int index=0; index<[(NSArray *)value count]; index++)
                {
                    NSDictionary *tempParams = [(NSArray *)value objectAtIndex:index];
                    if (objectArray && index<objectArray.count) {
                        [self updateObject:objectArray[index] params:tempParams];
                    }else{
                        NSEntityDescription *entiDescirp = [NSEntityDescription entityForName:NSStringFromClass([object class])
                                                                       inManagedObjectContext:globalManagedObjectContext];
                        NSRelationshipDescription *relationshipDescrip = [entiDescirp.relationshipsByName objectForKey:key];
                        NSString *tableName = relationshipDescrip.destinationEntity.name;
                        
                        NSManagedObject *tempObject = [self addObject:tempParams toTable:tableName];
                        if ([tempObject respondsToSelector:@selector(setIndex:)]) {
                            tempObject.index = [NSNumber numberWithInt:index];
                        }
                        SEL addSelector = NSSelectorFromString([NSString stringWithFormat:@"add%@Object:",[NSManagedObject upHeadString:key]]);
                        SuppressPerformSelectorLeakWarning([object performSelector:addSelector withObject:tempObject]);
                    }
                }
            }
            @catch (NSException *exception) {
                NSLog(@"解析数组出错了-->%@",exception);
            }
            @finally {
            }
        }
    }
    return object;
}

+ (NSArray *)getTable:(NSString *)tableName predicate:(NSPredicate *)predicate
{
    NSArray *resultArr = nil;
    
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    NSEntityDescription *description = [NSEntityDescription entityForName:tableName inManagedObjectContext:globalManagedObjectContext];
    [request setEntity:description];
    if (predicate) {
        [request setPredicate:predicate];
    }
    
    resultArr = [globalManagedObjectContext executeFetchRequest:request error:nil];
    
    return resultArr;
}


+ (void)save:(void (^)(NSError *error))complete
{
    NSError *error;
    if (![globalManagedObjectContext save:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        
        exit(-1);  // Fail
    }
}

//是否在异步队列中操作数据库
+ (void)asyncQueue:(BOOL)async actions:(void (^)(void))actions
{
    static int specificKey;
    if (myCustomQueue == NULL)
    {
        myCustomQueue = dispatch_queue_create("com.jizhi.coredata", DISPATCH_QUEUE_SERIAL); //生成一个串行队列
        
        CFStringRef specificValue = CFSTR("com.jizhi.coredata");
        dispatch_queue_set_specific(myCustomQueue, &specificKey, (void*)specificValue,(dispatch_function_t)CFRelease);
    }
    
    NSString *retrievedValue = (NSString *)CFBridgingRelease(dispatch_get_specific(&specificKey));
    if (retrievedValue && [retrievedValue isEqualToString:@"com.jizhi.coredata"]) {
        if (actions) {
            actions();
        }
    }else{
        if(async)
        {
            dispatch_async(myCustomQueue, ^{
                if (actions) {
                    actions();
                }
            });
        }else{
            dispatch_sync(myCustomQueue, ^{
                if (actions) {
                    actions();
                }
            });
        }
    }
}

@end
