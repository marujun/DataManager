//
//  NLCoreData.m
//  
//  Created by Jesper Skrufve <jesper@neolo.gy>
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//  

#import <CoreData/CoreData.h>
#import "NLCoreData.h"

const struct NLCoreDataExceptionsStruct NLCoreDataExceptions = {
    .predicate			= @"Predicate Exception",
    .count				= @"Count Exception",
    .parameter			= @"Parameter Exception",
    .merge				= @"Merge Exception",
    .fileExist			= @"File does not exist",
    .fileCopy			= @"Could not copy file",
    .encryption			= @"Encryption Exception",
    .persistentStore	= @"Persistent Store Exception",
    .permanentID		= @"Obtain Permanent ID Exception"
};

@interface NLCoreData ()

- (void)addPersistentStore;

@end

@implementation NLCoreData

#pragma mark - Lifecycle

+ (NLCoreData *)shared
{
	static dispatch_once_t onceToken;
	__strong static id instance = nil;
	
	dispatch_once(&onceToken, ^{
		
		instance = [[self alloc] init];
	});
	
	return instance;
}

- (void)useDatabaseFile:(NSString *)filePath
{
	if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
#ifdef DEBUG
		[NSException raise:NLCoreDataExceptions.fileExist format:@"%@", filePath];
#endif
		return;
	}
	
	NSError* error = nil;
	
	if (![[NSFileManager defaultManager] copyItemAtPath:filePath toPath:[self storePath] error:&error]) {
#ifdef DEBUG
		[NSException raise:NLCoreDataExceptions.fileCopy format:@"%@", [error localizedDescription]];
#endif
	}
}

- (BOOL)resetDatabase
{
	NSArray* stores = [[self storeCoordinator] persistentStores];
	
	if (![stores count])
		return YES;
	
	NSError* storeError = nil;
	
	if (![[self storeCoordinator] removePersistentStore:stores[0] error:&storeError]) {
#ifdef DEBUG
		[NSException raise:NLCoreDataExceptions.persistentStore format:@"%@", [storeError localizedDescription]];
#endif
		return NO;
	}
	
	NSFileManager* fm	= [NSFileManager defaultManager];
	NSString* storePath	= [self storePath];
	NSError* fileError	= nil;
	
	if (![fm fileExistsAtPath:storePath])
		return YES;
	
	if (![fm removeItemAtPath:storePath error:&fileError]) {
#ifdef DEBUG
		[NSException raise:@"" format:@"%@", fileError];
#endif
		[self addPersistentStore];
		return NO;
	}
	
	[self setManagedObjectModel:nil];
	[self setStoreCoordinator:nil];
	[NSManagedObjectContext rebuildAllContexts];
	
	return YES;
}

#pragma mark - Helpers

- (void)addPersistentStore
{
	NSError* error = nil;
	
	if (![[self storeCoordinator] addPersistentStoreWithType:[self persistentStoreType] configuration:nil URL:[self storeURL] options:[self persistentStoreOptions] error:&error]) {
#ifdef DEBUG
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		NSLog(@"metaData: %@", [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:nil URL:[self storeURL] error:nil]);
		NSLog(@"source and dest equivalent? %i", [[[error userInfo] valueForKeyPath:@"sourceModel"] isEqual:[[error userInfo] valueForKeyPath:@"destinationModel"]]);
		NSLog(@"failreason: %@", [[error userInfo] valueForKeyPath:@"reason"]);
		
        // reset models data when core data change
        [userDefaults removeObjectForKey:@"AllAuthData"];
        [userDefaults synchronize];
        [[NSFileManager defaultManager] removeItemAtURL:[self storeURL] error:nil];
        
        [self addPersistentStore];
#endif
	}
}

#pragma mark - Properties

- (NSString *)modelName
{
	if (_modelName)
		return _modelName;

    _modelName = @"models";
	
	return _modelName;
}

- (NSString *)storePath
{
	NSArray* paths			= NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* pathComponent = [[self modelName] stringByAppendingString:@".sqlite"];
	
	return [[paths lastObject] stringByAppendingPathComponent:pathComponent];
}

- (NSURL *)storeURL
{
	return [NSURL fileURLWithPath:[self storePath]];
}

- (void)setStoreEncrypted:(BOOL)storeEncrypted
{
	NSString* encryption		= storeEncrypted ? NSFileProtectionComplete : NSFileProtectionNone;
	NSDictionary* attributes	= @{NSFileProtectionKey: encryption};
	NSError* error;
	
	if (![[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:[self storePath] error:&error]) {
#ifdef DEBUG		
		[NSException raise:NLCoreDataExceptions.encryption format:@"%@", [error localizedDescription]];
#endif
	}
}

- (BOOL)storeExists
{
	return [[NSFileManager defaultManager] fileExistsAtPath:[self storePath]];
}

- (BOOL)isStoreEncrypted
{
	NSError* error				= nil;
	NSDictionary* attributes	= [[NSFileManager defaultManager] attributesOfItemAtPath:[self storePath] error:&error];
	
	if (!attributes) {
#ifdef DEBUG
		[NSException raise:NLCoreDataExceptions.encryption format:@"%@", [error localizedDescription]];
#endif
		return NO;
	}
	
	return [attributes[NSFileProtectionKey] isEqualToString:NSFileProtectionComplete];
}

- (NSDictionary *)persistentStoreOptions
{
	if (_persistentStoreOptions)
		return _persistentStoreOptions;
	
	_persistentStoreOptions = @{NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES};
	
	return _persistentStoreOptions;
}

- (NSString *)persistentStoreType
{
	if (_persistentStoreType)
		return _persistentStoreType;
	
	_persistentStoreType = NSSQLiteStoreType;
	
	return _persistentStoreType;
}

- (NSPersistentStoreCoordinator *)storeCoordinator
{
	if (_storeCoordinator)
		return _storeCoordinator;
	
	_storeCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
	
	[self addPersistentStore];
	
	return _storeCoordinator;
}

- (NSManagedObjectModel *)managedObjectModel
{
	if (_managedObjectModel)
		return _managedObjectModel;
	
	NSURL* url			= [[NSBundle mainBundle] URLForResource:[self modelName] withExtension:@"momd"];
	_managedObjectModel	= [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
	
	return _managedObjectModel;
}

@end
