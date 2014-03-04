//
//  CoreDataUtil.m
//  CoreDataUtil
//
//  Created by marujun on 14-1-13.
//  Copyright (c) 2014年 jizhi. All rights reserved.
//

#import "CoreDataUtil.h"

NSManagedObjectContext *globalManagedObjectContext_util;
NSManagedObjectModel *globalManagedObjectModel_util;

@implementation CoreDataUtil
@synthesize managedObjectContext_util = _managedObjectContext_util;
@synthesize managedObjectModel_util = _managedObjectModel_util;
@synthesize persistentStoreCoordinator_util = _persistentStoreCoordinator_util;

+ (void)launch
{
    static dispatch_once_t pred = 0;
	__strong static id coreDataUtil = nil;
	dispatch_once(&pred, ^{
	    coreDataUtil = [[self alloc] init];
	});
}

- (id)init
{
    self = [super init];
    if (self) {
        //初始化模型
        [NSManagedObject asyncQueue:false actions:^{
            globalManagedObjectContext_util = [self managedObjectContext];
            globalManagedObjectModel_util = [self managedObjectModel];
        }];
    }
    return self;
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext_util != nil) {
        return _managedObjectContext_util;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext_util = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext_util setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext_util;
}

// Returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel_util != nil) {
        return _managedObjectModel_util;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"models" withExtension:@"momd"];
    _managedObjectModel_util = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel_util;
}

// Returns the persistent store coordinator for the application.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	if (_persistentStoreCoordinator_util != nil) {
		return _persistentStoreCoordinator_util;
	}
    
	NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"models.sqlite"];
	NSError *error = nil;
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
	                         [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
	                         [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
	                         //[NSNumber numberWithBool:YES], NSIgnorePersistentStoreVersioningOption,
	                         nil];
	_persistentStoreCoordinator_util = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
	if (![_persistentStoreCoordinator_util addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        
		// reset models data when core data change
        [userDefaults removeObjectForKey:@"AllAuthData"];
        [userDefaults synchronize];
		[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
		_persistentStoreCoordinator_util = nil;
		return [self persistentStoreCoordinator];
	}
    
	return _persistentStoreCoordinator_util;
}


#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
