//
//  CoreDataUtil.h
//  CoreDataUtil
//
//  Created by marujun on 14-1-13.
//  Copyright (c) 2014年 jizhi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSManagedObject+Explain.h"
#import "NSManagedObject+Magic.h"

@interface CoreDataUtil : NSObject

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (void)launch;

@end
