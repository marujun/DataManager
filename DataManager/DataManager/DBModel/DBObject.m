//
//  DBObject.m
//  MCFriends
//
//  Created by marujun on 15/7/18.
//  Copyright (c) 2015年 marujun. All rights reserved.
//

#import "DBObject.h"
#import <objc/runtime.h>
#import "NSDate+Common.h"

//http://nshipster.cn/type-encodings/
//https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
// 32-bit下，BOOL被定义为signed char，@encode(BOOL)的结果是'c'
// 64-bit下，BOOL被定义为bool，@encode(BOOL)结果是'B'


@interface DBObject ()

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

+ (instancetype)modelWithObject:(id)object
{
    DBObject *model = [[self alloc] init];
    [model populateWithObject:object];
    
    return model;
}

+ (NSMutableArray *)modelListWithArray:(NSArray *)array
{
    NSMutableArray *result = [NSMutableArray new];
    for (NSDictionary *item in array) {
        NSObject *obj = [self modelWithObject:item];
        if (obj) [result addObject:obj];
    }
    return result;
}

+ (NSDictionary *)propertyMapper
{
    return nil;
}

+ (NSDictionary *)propertyGenericClass
{
    return nil;
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
 *  通过其他对象为当前对象填充对应成员变量的值
 */
- (void)populateWithObject:(id)object
{
    if (!object) {
        return;
    }
    
    NSArray *properties = nil;
    NSDictionary *mapper = nil;
    
    if ([object isKindOfClass:[NSDictionary class]]){
        properties = [object allKeys];
        
        mapper = [[self class] propertyMapper];
    }
    else if ([object isKindOfClass:[NSManagedObject class]]) {
        properties = [[self class] propertiesOfClass:[object class] baseClass:[NSManagedObject class]];
    }
    else {
        properties = [[self class] propertiesOfClass:[object class] baseClass:[NSObject class]];
    }
    
    [properties enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL * _Nonnull stop) {
        @try {
            [self populateValue:[object valueForKey:key] forKey:key];
        }@catch (NSException *exception) { }
    }];
    
    if (!mapper) return;
    
    [mapper enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        @try {
            id value;
            if ([obj isKindOfClass:[NSString class]] && [obj length]) {
                NSArray *keyPath = [obj componentsSeparatedByString:@"."];
                if (keyPath.count > 1) value = [object valueForKeyPath:obj];
                else value = [object valueForKey:obj];
            }
            else if ([obj isKindOfClass:[NSArray class]]) {
                for (NSString *oneKey in ((NSArray *)obj)) {
                    if (![oneKey isKindOfClass:[NSString class]]) continue;
                    if (!oneKey.length || value) continue;
                    
                    NSArray *keyPath = [oneKey componentsSeparatedByString:@"."];
                    if (keyPath.count > 1) value = [object valueForKeyPath:oneKey];
                    else value = [object valueForKey:oneKey];
                }
            }
            
            if (value) {
                [self populateValue:value forKey:key];
            }
        }
        @catch (NSException *exception) { }
    }];
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
            if([value respondsToSelector:@selector(longValue)]) value = [NSNumber numberWithLong:[value longValue]];
            else value = [NSNumber numberWithLong:[value intValue]];
        } else if (strcmp(raw_type, @encode(long long)) == 0) {
            value = [NSNumber numberWithLongLong:[value longLongValue]];
        } else if (strcmp(raw_type, @encode(unsigned char)) == 0) {
            value = [NSNumber numberWithUnsignedChar:[value unsignedCharValue]];
        } else if (strcmp(raw_type, @encode(unsigned int)) == 0) {
            value = [NSNumber numberWithUnsignedInt:[value unsignedIntValue]];
        } else if (strcmp(raw_type, @encode(unsigned short)) == 0) {
            value = [NSNumber numberWithUnsignedShort:[value unsignedShortValue]];
        } else if (strcmp(raw_type, @encode(unsigned long)) == 0) {
            if([value respondsToSelector:@selector(unsignedLongValue)]) value = [NSNumber numberWithLong:[value unsignedLongValue]];
            else value = [NSNumber numberWithLong:[value unsignedIntValue]];
        } else if (strcmp(raw_type, @encode(unsigned long long)) == 0) {
            value = [NSNumber numberWithUnsignedLongLong:[value unsignedLongLongValue]];
        } else if (type_string.length>3 && [type_string hasPrefix:@"@\""] && [type_string hasSuffix:@"\""]) {
            NSRange range = NSMakeRange(2, type_string.length-3);
            Class class = NSClassFromString([type_string substringWithRange:range]);
            value = [self objectWithKey:key value:value class:class];
        } else if ([type_string hasPrefix:@"{"]) {
            value = [self structWithType:type_string value:value];
        }
        
        [self setValue:value forKey:key];
    }
    @catch (NSException *exception) {
        NSLog(@"populate key:%@ value:%@ exception: %@", key, value, exception);
    }
}

- (id)structWithType:(NSString *)type value:(id)value
{
    if (!value || ![value isKindOfClass:[NSString class]]) return value;
    
    // 32 bit || 64 bit
    if ([type isEqualToString:@"{CGSize=ff}"] || [type isEqualToString:@"{CGSize=dd}"]) {
        return [NSValue valueWithCGSize:CGSizeFromString(value)];
    }
    else if ([type isEqualToString:@"{CGPoint=ff}"] || [type isEqualToString:@"{CGPoint=dd}"]) {
        return [NSValue valueWithCGPoint:CGPointFromString(value)];
    }
    else if ([type isEqualToString:@"{CGRect={CGPoint=ff}{CGSize=ff}}"] || [type isEqualToString:@"{CGRect={CGPoint=dd}{CGSize=dd}}"]) {
        return [NSValue valueWithCGRect:CGRectFromString(value)];
    }
    else if ([type isEqualToString:@"{CGAffineTransform=ffffff}"] || [type isEqualToString:@"{CGAffineTransform=dddddd}"]) {
        return [NSValue valueWithCGAffineTransform:CGAffineTransformFromString(value)];
    }
    else if ([type isEqualToString:@"{UIEdgeInsets=ffff}"] || [type isEqualToString:@"{UIEdgeInsets=dddd}"]) {
        return [NSValue valueWithUIEdgeInsets:UIEdgeInsetsFromString(value)];
    }
    else if ([type isEqualToString:@"{UIOffset=ff}"] || [type isEqualToString:@"{UIOffset=dd}"]) {
        return [NSValue valueWithUIOffset:UIOffsetFromString(value)];
    }
    return value;
}

- (NSDate *)dateWithValue:(id)value
{
    NSDate *date = nil;
    if ([value isKindOfClass:[NSDate class]]) {
        date = value;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        date = [NSDate dateWithTimeStamp:[value doubleValue]];
    }
    else if ([value isKindOfClass:[NSString class]]) {
        if ([value length] == 10 || [value length] == 13 ) {
            date = [NSDate dateWithTimeStamp:[value doubleValue]];
        }
        else if ([value length] == 19) {
            date = [value dateWithDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        }
        else if ([value length] == 16) {
            date = [value dateWithDateFormat:@"yyyy-MM-dd HH:mm"];
        }
    }
    
    return date;
}

#define ConvertValueToObject  if (value && [value isKindOfClass:[NSString class]]) {\
@try {  NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];\
value = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];\
} @catch (NSException *exception) { }}

- (id)objectWithKey:(NSString *)key value:(id)value class:(Class)class
{
    id toClass = [[[self class] propertyGenericClass] objectForKey:key];
    
    if (class==[NSMutableDictionary class]) {
        ConvertValueToObject
        if (value && [value isKindOfClass:[NSDictionary class]]) {
            value = [NSMutableDictionary dictionaryWithDictionary:value];
        } else {
            value = [NSMutableDictionary dictionary];
        }
    } else if (class==[NSMutableArray class]) {
        ConvertValueToObject
        if (value && [value isKindOfClass:[NSArray class]]) {
            if (toClass) {
                NSMutableArray *array = [NSMutableArray array];
                for (id item in value) {
                    [array addObject:[self objectWithValue:item toClass:toClass]];
                }
                value = array;
            } else {
                value = [NSMutableArray arrayWithArray:value];
            }
        } else {
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
        } else if (toClass) {
            NSMutableArray *array = [NSMutableArray array];
            for (id item in value) {
                [array addObject:[self objectWithValue:item toClass:toClass]];
            }
            value = [NSArray arrayWithArray:array];
        }
    } else if (class == [NSDate class]) {
        value = [self dateWithValue:value];
    }
    else if (class == [NSString class]) {
        value = [value stringValue];
    }
    else if(toClass) {
        value = [self objectWithValue:value toClass:toClass];
    }
    
    return value;
}

- (id)objectWithValue:(id)value toClass:(id)toClass
{
    if (toClass && [toClass isKindOfClass:[NSString class]]) {
        toClass = NSClassFromString(toClass);
    }
    
    if (!toClass) return value;
    
    if (toClass) {
        id obj = [[toClass alloc] init];
        if ([obj isKindOfClass:[DBObject class]]) {
            [(DBObject *)obj populateWithObject:value];
            return obj;
        }
    }
    return value;
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
 *  获取类成员变量和其对应值的字典，不包含值为空的属性
 */
- (NSDictionary *)dictionary
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    for (NSString *key in [self properties]) {
        [dic setValue:[self valueForKey:key] forKey:key];
    }
    
    return [dic copy];
}

- (NSDictionary *)dictionaryContainNull
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
    return [des stringByAppendingString:[[self dictionaryContainNull] description]];
}

@end

@implementation DMObject

- (void)populateWithObject:(id)object
{
    if (object && [object isKindOfClass:[NSManagedObject class]]) {
        _objectID = [(NSManagedObject *)object objectID];
        
        if ([_objectID isTemporaryID]) [object obtainPermanentID];
        
    }
    [super populateWithObject:object];
}

@end
