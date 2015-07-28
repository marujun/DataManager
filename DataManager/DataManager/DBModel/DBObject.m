//
//  DBObject.m
//  MCFriends
//
//  Created by marujun on 15/7/18.
//  Copyright (c) 2015年 marujun. All rights reserved.
//

#import "DBObject.h"
#import <objc/runtime.h>

//http://nshipster.cn/type-encodings/
//https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
// 32-bit下，BOOL被定义为signed char，@encode(BOOL)的结果是'c'
// 64-bit下，BOOL被定义为bool，@encode(BOOL)结果是'B'


@interface DBObject ()
{
    BOOL _saveIng;
    BOOL _hasRegObserver;
    
    NSManagedObjectID *_objectID;
}

@end

@implementation DBObject

- (id)init
{
    self = [super init];
    if (self) {
        [self setDefaultValue];
    }
    
    return self;
}

- (instancetype)initWithObject:(id)object
{
    self = [super init];
    if (self) {
        [self setDefaultValue];
        [self populateWithObject:object];
    }
    
    return self;
}

/**
 *  为 NSMutableDictionary、NSMutableArray 类型的成员变量初始化一个值
 */
- (void)setDefaultValue
{
    [self.properties enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        NSString *type_string = [self typeWithKey:key];
        if ([type_string hasPrefix:@"@\""] && [type_string hasSuffix:@"\""]) {
            NSRange range = NSMakeRange(2, type_string.length-3);
            Class class = NSClassFromString([type_string substringWithRange:range]);
            if (class==[NSMutableDictionary class]) {
                [self setValue:[NSMutableDictionary dictionary] forKey:key];
            } else if (class==[NSMutableArray class]) {
                [self setValue:[NSMutableArray array] forKey:key];
            }
        }
    }];
}

/**
 *  NSManagedObjectContextObjectsDidChangeNotification 监听方法
 */
- (void)handleManagedObjectChange:(NSNotification *)note
{
    NSSet *updatedObjects = [[note userInfo] objectForKey:NSUpdatedObjectsKey];
    for (NSManagedObject *changedObject in updatedObjects) {
        if ([changedObject.objectID isEqual:_objectID]) {
            if (_saveIng) {
                _saveIng = NO;
            }else{
                [self populateWithObject:changedObject];
            }
            
            break;
        }
    }
}

/**
 *  通过其他对象为当前对象填充对应成员变量的值
 */
- (void)populateWithObject:(id)object
{
    if (!object) {
        return;
    }
    
    NSArray *properties = nil;
    if ([object isKindOfClass:[NSManagedObject class]]) {
        _objectID = [(NSManagedObject *)object objectID];
        properties = [[self class] propertiesOfClass:[object class] baseClass:[NSManagedObject class]];
        
        if (!_hasRegObserver) {
            _hasRegObserver = YES;
            
            /**
             *  监听绑定的NSManagedObject对象的值的变化
             */
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleManagedObjectChange:)
                                                         name:NSManagedObjectContextObjectsDidChangeNotification
                                                       object:[NSManagedObjectContext backgroundContext]];
        }
    }
    else if ([object isKindOfClass:[NSDictionary class]]){
        properties = [object allKeys];
    }
    else{
        properties = [[self class] propertiesOfClass:[object class] baseClass:[NSObject class]];
    }
    
    for (NSString *key in properties){
        @try {
            [self populateValue:[object valueForKey:key] forKey:key];
        }@catch (NSException *exception) { }
    }
}

/**
 *  为当前对象的某个成员变量填充值
 */
- (void)populateValue:(id)value forKey:(NSString *)key
{
    objc_property_t property = class_getProperty([self class], [key UTF8String]);
    if (!property) {
        return;
    }
    
    @try {
        NSString *type_string = [self typeWithKey:key];;
        const char *raw_type = [type_string UTF8String];
        
        if (strcmp(raw_type, @encode(int)) == 0) {
            value = [NSNumber numberWithInt:[value intValue]];
        } else if (strcmp(raw_type, @encode(BOOL)) == 0) {
            value = [NSNumber numberWithBool:[value boolValue]];
        } else if (strcmp(raw_type, @encode(float)) == 0) {
            value = [NSNumber numberWithFloat:[value floatValue]];
        } else if (strcmp(raw_type, @encode(double)) == 0) {
            value = [NSNumber numberWithDouble:[value doubleValue]];
        } else if (strcmp(raw_type, @encode(char)) == 0) {
            value = [NSNumber numberWithChar:[value charValue]];
        } else if (strcmp(raw_type, @encode(short)) == 0) {
            value = [NSNumber numberWithShort:[value shortValue]];
        } else if (strcmp(raw_type, @encode(long)) == 0) {
            value = [NSNumber numberWithLong:[value longValue]];
        } else if (strcmp(raw_type, @encode(long long)) == 0) {
            value = [NSNumber numberWithLongLong:[value longLongValue]];
        } else if (strcmp(raw_type, @encode(unsigned char)) == 0) {
            value = [NSNumber numberWithUnsignedChar:[value unsignedCharValue]];
        } else if (strcmp(raw_type, @encode(unsigned int)) == 0) {
            value = [NSNumber numberWithUnsignedInt:[value unsignedIntValue]];
        } else if (strcmp(raw_type, @encode(unsigned short)) == 0) {
            value = [NSNumber numberWithUnsignedShort:[value unsignedShortValue]];
        } else if (strcmp(raw_type, @encode(unsigned long)) == 0) {
            value = [NSNumber numberWithUnsignedLong:[value unsignedLongValue]];
        } else if (strcmp(raw_type, @encode(unsigned long long)) == 0) {
            value = [NSNumber numberWithUnsignedLongLong:[value unsignedLongLongValue]];
        } else if (type_string.length>3 && [type_string hasPrefix:@"@\""] && [type_string hasSuffix:@"\""]) {
            NSRange range = NSMakeRange(2, type_string.length-3);
            Class class = NSClassFromString([type_string substringWithRange:range]);
            value = [self objectWithValue:value class:class];
        }
        
        [self setValue:value forKey:key];
    }
    @catch (NSException *exception) {
        FLOG(@"populate key:%@ value:%@ exception: %@", key, value, exception);
    }
}

#define ConvertValueToObject  if (value && [value isKindOfClass:[NSString class]]) {\
@try {  NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];\
value = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];\
} @catch (NSException *exception) { }}

- (id)objectWithValue:(id)value class:(Class)class
{
    if (class==[NSMutableDictionary class]) {
        ConvertValueToObject
        if (value && [value isKindOfClass:[NSDictionary class]]) {
            value = [NSMutableDictionary dictionaryWithDictionary:value];
        }else{
            value = [NSMutableDictionary dictionary];
        }
    } else if (class==[NSMutableArray class]) {
        ConvertValueToObject
        if (value && [value isKindOfClass:[NSArray class]]) {
            value = [NSMutableArray arrayWithArray:value];
        }else{
            value = [NSMutableArray array];
        }
    } else if (class==[NSDictionary class]) {
        ConvertValueToObject
        if (![value isKindOfClass:[NSDictionary class]]) {
            value = nil;
        }
    } else if (class==[NSArray class]) {
        ConvertValueToObject
        if (![value isKindOfClass:[NSArray class]]) {
            value = nil;
        }
    }
    
    return value;
}

/**
 *  把模型数据保存到数据库
 *
 *  @param obj      即将保存到的数据库对象
 *  @param complete 保存完成后的回调
 */
- (void)saveTo:(NSManagedObject **)obj complete:(void (^)(BOOL success))complete
{
    NSManagedObjectContext *bgContext = [NSManagedObjectContext backgroundContext];
    NSManagedObject *bgObject = nil;
    
    if (_objectID) {
        bgObject = [bgContext objectRegisteredForID:_objectID];
    }
    
    Class cdClass = NSClassFromString([NSStringFromClass([self class]) stringByReplacingCharactersInRange:NSMakeRange(0, 2) withString:@""]);
    if (!bgObject && cdClass) {
        bgObject = [cdClass insertInContext:bgContext];
        _objectID  = bgObject.objectID;
    }
    
    if(obj){
        *obj = bgObject;
    }
    
    if (bgObject) {
        for (NSString *key in self.properties) {
            @try {
                id value = [self valueForKey:key];
                if (value && ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]])) {
                    if ([NSJSONSerialization isValidJSONObject:value]) {
                        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:value options:0  error:nil];
                        value = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    }else{
                        FLOG(@"check All objects for key:%@ are NSString, NSNumber, NSArray, NSDictionary, or NSNull !!!!!",key);
                    }
                }
                
                objc_property_t property = class_getProperty([bgObject class], [key UTF8String]);
                if (property) {
                    [bgObject setValue:value forKey:key];
                }
            }
            @catch (NSException *exception) {
                FLOG(@"DBObject Save To CoreData exception: %@",exception);
            }
        }
        
        _saveIng = YES;
        [bgObject saveWithComplete:complete];
    }else{
        complete?complete(NO):nil;
    }
}

/**
 *  通过类名和其基类名获取其对应的所有成员变量名称列表（包括基类）
 */
+ (NSArray *)propertiesOfClass:(Class)class baseClass:(Class)baseClass
{
    NSMutableArray *array = [NSMutableArray array];
    while ((class != baseClass) && [class isSubclassOfClass:baseClass]) {
        NSArray *pros = [self propertiesOfMemberClass:class];
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, pros.count)];
        [array insertObjects:pros atIndexes:indexSet];
        class = [class superclass];
    }
    
    return [array copy];
}

/**
 *  通过类名获取其对应的成员变量名称列表（不包括基类）
 */
+ (NSArray *)propertiesOfMemberClass:(Class)class
{
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(class, &outCount);
    NSMutableArray *propertys = [NSMutableArray arrayWithCapacity:outCount];
    
    //iOS8 新增的4个属性，如果类实现了Protocol可能会被取出来
    //    The objective-c runtime stuff does NOT include superclass properties in what is returned it will however include properties declared in protocol extensions (protocols that force adherence to other protocols).
    NSArray *newProperties = @[@"superclass", @"description", @"debugDescription", @"hash"];
    
    for(i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propertyName = property_getName(property);
        NSString *name = [NSString stringWithCString:propertyName encoding:NSUTF8StringEncoding];
        if (![newProperties containsObject:name]) {
            [propertys addObject:name];
        }
    }
    free(properties);
    
    return [propertys copy];
}

/**
 *  通过类成员变量名称获取其对应的成员变量名称列表
 */
- (NSArray *)attributesWithKey:(NSString *)key
{
    objc_property_t property = class_getProperty([self class], [key UTF8String]);
    if (!property) {
        return @[];
    }
    
    const char *property_type = property_getAttributes(property);
    NSString *typeString = [NSString stringWithUTF8String:property_type];
    
    return [typeString componentsSeparatedByString:@","];
}

/**
 *  通过类成员变量名称获取其对应的类型（int、float、NSString ...）
 */
- (NSString *)typeWithKey:(NSString *)key
{
    NSArray *attributes = [self attributesWithKey:key];
    if (attributes.count) {
        return [attributes[0] substringFromIndex:1];
    }
    
    return @"";
}

/**
 *  通过类成员变量名称获取其是否为readonly修饰
 */
- (BOOL)isReadonlyOfKey:(NSString *)key
{
    return [[self attributesWithKey:key] containsObject:@"R"];
}

/**
 *  获取当前类及其基类的所有成员变量名称的列表
 */
- (NSArray *)properties
{
    return [[self class] propertiesOfClass:[self class] baseClass:[NSObject class]];
}

/**
 *  获取类成员变量和其对应值的字典
 */
- (NSDictionary *)dictionary
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    for (NSString *key in [self properties]) {
        [dic setValue:[self valueForKey:key]?:[NSNull null] forKey:key];
    }
    
    return [dic copy];
}

- (NSString *)description
{
    NSString *des = [NSString stringWithFormat:@"<%@: %p>\n",NSStringFromClass([self class]),self];
    return [des stringByAppendingString:[[self dictionary] description]];
}

- (void)dealloc
{
    if (_hasRegObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

@end
