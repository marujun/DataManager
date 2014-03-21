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

extern NSManagedObjectContext *globalManagedObjectContext_util;
extern NSManagedObjectModel *globalManagedObjectModel_util;

@implementation NSManagedObject (Explain)

//通过dictionary生成一个临时的object对象但不保存到数据库中
+ (id)objectWithDictionary:(NSDictionary *)dictionary
{
    NSEntityDescription *entity = [[globalManagedObjectModel_util entitiesByName] objectForKey:NSStringFromClass([self class])];
    NSManagedObject *oneObject = [[[self class] alloc] initWithEntity:entity insertIntoManagedObjectContext:nil];
    [oneObject setContentDictionary:dictionary?dictionary:@{}];
    return oneObject;
}
- (void)save
{
    [NSManagedObject asyncQueue:false actions:^{
        if (!self.managedObjectContext) {
            [globalManagedObjectContext_util insertObject:self];
        }
        [NSManagedObject save:nil];
    }];
}
- (void)remove
{
    if (self.managedObjectContext) {
        [NSManagedObject deleteObjects_sync:@[self]];
    }
}
- (NSDictionary *)dictionary
{
    NSArray *keys = [[[self entity] attributesByName] allKeys];
    return [[self dictionaryWithValuesForKeys:keys] mutableCopy];
}

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
        [self save:^(NSError *error) { error?resultArray=@[]:nil; }];
        if (complete) {
            complete(resultArray);
        }
    }];
}
+ (void)deleteObjects_async:(NSArray *)manyObject complete:(void (^)(BOOL success))complete
{
    [self asyncQueue:true actions:^{
        [self deleteObjects:manyObject];
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
        [self save:^(NSError *error) { error?resultArray=@[]:nil; }];
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
    [self getTable_async:tableName predicate:predicate sortDescriptors:nil complete:complete];
}
+ (void)getTable_async:(NSString *)tableName actions:(void (^)(NSFetchRequest *request))actions complete:(void (^)(NSArray *result))complete
{
    [self asyncQueue:true actions:^{
        NSArray *resultArr = [self getTable:tableName predicate:nil sortDescriptors:nil actions:actions];
        if (complete) {
            complete(resultArr);
        }
    }];
}
+ (void)getTable_async:(NSString *)tableName predicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors complete:(void (^)(NSArray *result))complete
{
    [self asyncQueue:true actions:^{
        NSArray *resultArr = [self getTable:tableName predicate:predicate sortDescriptors:sortDescriptors actions:nil];
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
        [self save:^(NSError *error) { error?resultArr=@[]:nil; }];
    }];
    return resultArr;
}
+ (BOOL)deleteObjects_sync:(NSArray *)manyObject
{
    __block BOOL success = true;
    [self asyncQueue:false actions:^{
        [self deleteObjects:manyObject];
        [self save:^(NSError *error) { error?success=false:true; }];
    }];
    return success;
}
+ (NSArray *)updateTable_sync:(NSString *)tableName predicate:(NSPredicate *)predicate params:(NSDictionary *)params
{
    __block NSArray *resultArray = nil;
    [self asyncQueue:false actions:^{
        resultArray = [self updateTable:tableName predicate:predicate params:params];
        [self save:^(NSError *error) { error?resultArray=@[]:nil; }];
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
    return [self getTable_sync:tableName predicate:predicate sortDescriptors:nil];
}
+ (NSArray *)getTable_sync:(NSString *)tableName actions:(void (^)(NSFetchRequest *request))actions
{
    __block NSArray *resultArr = nil;
    [self asyncQueue:false actions:^{
        resultArr = [self getTable:tableName predicate:nil sortDescriptors:nil actions:actions];
    }];
    return resultArr;
}
+ (NSArray *)getTable_sync:(NSString *)tableName predicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors
{
    __block NSArray *resultArr = nil;
    [self asyncQueue:false actions:^{
        resultArr = [self getTable:tableName predicate:predicate sortDescriptors:sortDescriptors actions:nil];
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
            
        }else if ([value isKindOfClass:[NSDictionary class]]){
            @try {
                NSEntityDescription *entityDescirp = [NSEntityDescription entityForName:NSStringFromClass([self class]) inManagedObjectContext:globalManagedObjectContext_util];
                NSRelationshipDescription *relationshipDescrip = [entityDescirp.relationshipsByName objectForKey:key];
                NSString *tableName = relationshipDescrip.destinationEntity.name;
                
                NSManagedObject *object = [NSManagedObject addObject:value toTable:tableName];
                
                [self setValue:object forKey:key];
            }
            @catch (NSException *exception) {
                NSLog(@"解析字典出错了-->%@",exception);
            }
        }else if ([value isKindOfClass:[NSArray class]]){
            
            @try {
                for (NSDictionary *oneJsonObject in value)
                {
                    NSEntityDescription *entiDescirp = [NSEntityDescription entityForName:NSStringFromClass([self class]) inManagedObjectContext:globalManagedObjectContext_util];
                    NSRelationshipDescription *relationshipDescrip = [entiDescirp.relationshipsByName objectForKey:key];
                    NSString *tableName = relationshipDescrip.destinationEntity.name;
                    
                    NSManagedObject *object = [NSManagedObject addObject:oneJsonObject toTable:tableName];
                    SEL addSelector = NSSelectorFromString([NSString stringWithFormat:@"add%@Object:",[NSManagedObject upHeadString:key]]);
                    SuppressPerformSelectorLeakWarning([self performSelector:addSelector withObject:object]);
                }
            }
            @catch (NSException *exception) {
                NSLog(@"解析数组出错了-->%@",exception);
            }
        }
    }
}

//在当前队列执行任务
+ (NSManagedObject *)addObject:(NSDictionary *)dictionary toTable:(NSString *)tableName
{
    NSManagedObject *oneObject = nil;
    Class class = NSClassFromString(tableName);
    
    NSEntityDescription *entityDescrip = [[globalManagedObjectModel_util entitiesByName] objectForKey:tableName];
    oneObject = [[class alloc] initWithEntity:entityDescrip insertIntoManagedObjectContext:globalManagedObjectContext_util];
    [oneObject setContentDictionary:dictionary];
    
    return oneObject;
}


+ (NSArray *)addObjectsFromArray:(NSArray *)otherArray toTable:(NSString *)tableName
{
    NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    
    Class class = NSClassFromString(tableName);
    NSEntityDescription *entityDescrip = [[globalManagedObjectModel_util entitiesByName] objectForKey:tableName];
    
    for (NSDictionary *dictionary in otherArray)
    {
        NSManagedObject *oneObject = [[class alloc] initWithEntity:entityDescrip insertIntoManagedObjectContext:globalManagedObjectContext_util];
        [oneObject setContentDictionary:dictionary];
        [resultArray addObject:oneObject];
    }
    return [resultArray copy];
}

+ (NSArray *)updateTable:(NSString *)tableName predicate:(NSPredicate *)predicate params:(NSDictionary *)params
{
    //查询数据
    NSArray *queryArr = [self getTable:tableName predicate:predicate sortDescriptors:nil actions:nil];
    
    //有匹配的记录时则更新记录
    if(queryArr && queryArr.count){
        for (NSManagedObject *object in queryArr.copy)
        {
            [self updateObject:object params:params];
        }
    } else //没有匹配的记录时添加记录
    {
        queryArr = @[[self addObject:params toTable:tableName]];
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
        }else if ([value isKindOfClass:[NSDictionary class]]){
            @try {
                NSManagedObject *otherObject = [object valueForKey:key];
                if(otherObject){
                    [self updateObject:otherObject params:value];
                }else{
                    NSEntityDescription *entityDescirp = [NSEntityDescription entityForName:NSStringFromClass([self class])
                                                                     inManagedObjectContext:globalManagedObjectContext_util];
                    NSRelationshipDescription *relationshipDescrip = [entityDescirp.relationshipsByName objectForKey:key];
                    NSString *tableName = relationshipDescrip.destinationEntity.name;
                    
                    otherObject = [NSManagedObject addObject:value toTable:tableName];
                    [object setValue:otherObject forKey:key];
                }
            }
            @catch (NSException *exception) {
                NSLog(@"解析字典出错了-->%@",exception);
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
                                                                       inManagedObjectContext:globalManagedObjectContext_util];
                        NSRelationshipDescription *relationshipDescrip = [entiDescirp.relationshipsByName objectForKey:key];
                        NSString *tableName = relationshipDescrip.destinationEntity.name;
                        
                        NSManagedObject *tempObject = [self addObject:tempParams toTable:tableName];
                        SEL addSelector = NSSelectorFromString([NSString stringWithFormat:@"add%@Object:",[NSManagedObject upHeadString:key]]);
                        SuppressPerformSelectorLeakWarning([object performSelector:addSelector withObject:tempObject]);
                    }
                }
            }
            @catch (NSException *exception) {
                NSLog(@"解析数组出错了-->%@",exception);
            }
        }
    }
    return object;
}

+ (NSArray *)getTable:(NSString *)tableName predicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors actions:(void (^)(NSFetchRequest *request))actions
{
    NSArray *resultArr = @[];
    
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    NSEntityDescription *description = [NSEntityDescription entityForName:tableName inManagedObjectContext:globalManagedObjectContext_util];
    [request setEntity:description];
    if (predicate) {
        [request setPredicate:predicate];
    }
    if (sortDescriptors && sortDescriptors.count) {
        [request setSortDescriptors:sortDescriptors];
    }
    actions?actions(request):nil;
    @try {
        @synchronized(globalManagedObjectContext_util) {
            resultArr = [globalManagedObjectContext_util executeFetchRequest:request error:nil];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"查询数据库出错了-->%@",exception);
    }
    
    return resultArr;
}


+ (void)save:(void (^)(NSError *error))complete
{
    NSError *error;
    @synchronized(globalManagedObjectContext_util) {
        if (![globalManagedObjectContext_util save:&error]) {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        }
        complete ? complete(error) : nil;
    }
}

+ (void)deleteObjects:(NSArray *)manyObject
{
    @synchronized(globalManagedObjectContext_util) {
        for (NSManagedObject *object in manyObject){
            [globalManagedObjectContext_util deleteObject:object];
        }
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
        actions ? actions() : nil;
    }else{
        if(async){
            dispatch_async(myCustomQueue, ^{
                actions ? actions() : nil;
            });
        }else{
            dispatch_sync(myCustomQueue, ^{
                actions ? actions() : nil;
            });
        }
    }
}

@end
