//
//  DBObject.h
//  MCFriends
//
//  Created by marujun on 15/7/18.
//  Copyright (c) 2015年 marujun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface DBObject : NSObject

- (NSArray *)properties;

- (NSDictionary *)dictionary;

- (instancetype)initWithObject:(id)object;

+ (instancetype)modelWithObject:(id)object;

+ (NSMutableArray *)modelListWithArray:(NSArray *)array;

- (void)populateValue:(id)value forKey:(NSString *)key;

- (void)populateWithObject:(id)object;

/**
 Custom property mapper.
 
 @discussion If the key in JSON/Dictionary does not match to the model's property name,
 implements this method and returns the additional mapper.
 
 Example:
 
     json:
     {
         "n":"Harry Pottery",
         "p": 256,
         "ext" : {
             "desc" : "A book written by J.K.Rowling."
         },
         "ID" : 100010
     }
 
     model:
         @interface DBBook : NSObject
         @property NSString *name;
         @property NSInteger page;
         @property NSString *desc;
         @property NSString *bookID;
         @end
 
         @implementation DBBook
         + (NSDictionary *)propertyMapper {
             return @{@"name"  : @"n",
                      @"page"  : @"p",
                      @"desc"  : @"ext.desc",
                      @"bookID": @[@"id", @"ID", @"book_id"]};
         }
         @end
 
 @return A custom mapper for properties.
 */
+ (NSDictionary *)propertyMapper;

/**
 The generic class mapper for container properties.
 
 @discussion If the property is a container object, such as NSArray/NSSet/NSDictionary,
 implements this method and returns a property->class mapper, tells which kind of 
 object will be add to the array/set/dictionary.
 
  Example:
        @class DBShadow, DBBorder, DBAttachment;
 
        @interface DBAttributes
        @property NSString *name;
        @property NSArray *shadows;
        @property NSSet *borders;
        @property NSDictionary *attachments;
        @end
 
        @implementation DBAttributes
        + (NSDictionary *) propertyGenericClass {
            return @{@"shadows" : [DBShadow class],
                     @"borders" : DBBorder.class,
                     @"attachments" : @"DBAttachment" };
        }
        @end
 
 @return A class mapper.
 */
+ (NSDictionary *)propertyGenericClass;

@end

@interface DMObject : DBObject
{
    NSManagedObjectID *_objectID;
}

@property (nonatomic, readonly, strong) NSManagedObjectID *objectID;

@end
