//
//  BaseObject.h
//  CoreDataUtil
//
//  Created by marujun on 14-1-16.
//  Copyright (c) 2014年 马汝军. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface BaseObject : NSManagedObject

@property (nonatomic, retain) NSNumber * userid;
@property (nonatomic, retain) NSNumber * index;

@end
