//
//  CoreDataUtil.m
//  CoreDataUtil
//
//  Created by marujun on 14-1-13.
//  Copyright (c) 2014年 jizhi. All rights reserved.
//

#import "CoreDataUtil.h"

NSManagedObjectContext *globalManagedObjectContext;
NSManagedObjectModel *globalManagedObjectModel;

@implementation CoreDataUtil
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

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
        globalManagedObjectContext = [self managedObjectContext];
        globalManagedObjectModel = [self managedObjectModel];
    }
    return self;
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"models" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	if (_persistentStoreCoordinator != nil) {
		return _persistentStoreCoordinator;
	}
    
	NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"models.sqlite"];
	NSError *error = nil;
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
	                         [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
	                         [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
	                         //[NSNumber numberWithBool:YES], NSIgnorePersistentStoreVersioningOption,
	                         nil];
	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
	if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        
		// reset models data when core data change
		[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
		_persistentStoreCoordinator = nil;
		return [self persistentStoreCoordinator];
	}

	return _persistentStoreCoordinator;
}


#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
