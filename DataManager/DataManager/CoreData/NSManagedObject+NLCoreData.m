//
//  NSManagedObject+NLCoreData.m
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

#import "NSManagedObject+NLCoreData.h"
#import "NLCoreData.h"

@interface NSManagedObject (NLCoreData_Private)

- (NSString *)descriptionOfAttributesWithIndent:(NSInteger)indent;

@end

#pragma mark -
@implementation NSManagedObject (NLCoreData)

#pragma mark - Lifecycle

+ (NSString *)entityName
{
	return NSStringFromClass([self class]);
}

#pragma mark - Inserting

+ (instancetype)insertInContext:(NSManagedObjectContext *)context
{
	return [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:context];
}

#pragma mark - Deleting

- (void)delete
{
	[[self managedObjectContext] deleteObject:self];
}

+ (void)deleteWithRequest:(void (^)(NSFetchRequest* request))block context:(NSManagedObjectContext *)context
{
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntity:[self class] context:context];
	
	if (block)
		block(request);
	
	[request setIncludesPropertyValues:NO];
	
	NSError* error;
	NSArray* objects = [context executeFetchRequest:request error:&error];

	for (NSManagedObject* object in objects)
		[context deleteObject:object];
}

+ (void)deleteInContext:(NSManagedObjectContext *)context predicate:(id)predicateOrString, ...
{
	SET_PREDICATE_WITH_VARIADIC_ARGS
	[self deleteWithRequest:^(NSFetchRequest *request) {
		
		[request setPredicate:predicate];
		
	} context:context];
}

#pragma mark - Counting

+ (NSUInteger)countInContext:(NSManagedObjectContext *)context predicate:(id)predicateOrString, ...
{
	SET_PREDICATE_WITH_VARIADIC_ARGS
	return [self countWithRequest:^(NSFetchRequest *request) {
		
		[request setPredicate:predicate];
		
	} context:context];
}

+ (NSUInteger)countWithRequest:(void (^)(NSFetchRequest* request))block context:(NSManagedObjectContext *)context
{
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntity:[self class] context:context];
	
	if (block)
		block(request);
	
	NSError* error;
	NSUInteger count = [context countForFetchRequest:request error:&error];
	
#ifdef DEBUG
	if (count == NSNotFound)
		[NSException raise:NLCoreDataExceptions.count format:@"%@", [error localizedDescription]];
#endif
	
	return count;
}

#pragma mark - Fetching

+ (instancetype)fetchWithObjectID:(NSManagedObjectID *)objectID context:(NSManagedObjectContext *)context
{
	id object = [context objectRegisteredForID:objectID];
	
	if (object)
		return object;
	
	object = [context objectWithID:objectID];
	
	if (![object isFault])
		return object;
	
	NSError* error;
	object = [context existingObjectWithID:objectID error:&error];
	
	return object;
}

+ (NSArray *)fetchWithRequest:(void (^)(NSFetchRequest* request))block context:(NSManagedObjectContext *)context
{
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntity:[self class] context:context];
	
    if (block){
        block(request);
    }
		
	NSError* error;
	NSArray* objects = [context executeFetchRequest:request error:&error];
	
    if (error) {
        FLOG(@"fetchWithRequest error: %@",error);
    }
    
	return objects;
}

+ (NSArray *)fetchInContext:(NSManagedObjectContext *)context predicate:(id)predicateOrString, ...
{
	SET_PREDICATE_WITH_VARIADIC_ARGS
	return [self fetchWithRequest:^(NSFetchRequest *request) {
		
		[request setPredicate:predicate];
		
	} context:context];
}

+ (instancetype)fetchSingleInContext:(NSManagedObjectContext *)context predicate:(id)predicateOrString, ...
{
	SET_PREDICATE_WITH_VARIADIC_ARGS
	return [self fetchSingleInContext:context sortByKey:nil ascending:NO predicate:predicate];
}

+ (instancetype)fetchSingleInContext:(NSManagedObjectContext *)context sortByKey:(NSString *)key ascending:(BOOL)ascending predicate:(id)predicateOrString, ...
{
	SET_PREDICATE_WITH_VARIADIC_ARGS
	NSArray* objects = [self fetchWithRequest:^(NSFetchRequest *request) {
		
		[request setFetchLimit:1];
		
		if (predicate)
			[request setPredicate:predicate];
		
		if (key)
			[request sortByKey:key ascending:ascending];
		
	} context:context];
	
	return [objects count] ? objects[0] : nil;
}

+ (instancetype)fetchOrInsertSingleInContext:(NSManagedObjectContext *)context predicate:(id)predicateOrString, ...
{
	SET_PREDICATE_WITH_VARIADIC_ARGS
	id object = [self fetchSingleInContext:context predicate:predicate];
	
	if (object)
		return object;
	
	return [self insertInContext:context];
}

+ (void)fetchAsyncToMainContextWithRequest:(void (^)(NSFetchRequest* request))block completion:(void (^)(NSArray* objects))completion
{
#ifdef DEBUG
	if (!completion)
		[NSException raise:NLCoreDataExceptions.parameter format:@"completion block cannot be nil"];
#endif
	
	NSManagedObjectContext* mainContext	= [NSManagedObjectContext mainContext];
	NSManagedObjectContext* bgContext	= [NSManagedObjectContext backgroundContext];
	
	[bgContext performBlock:^{
		
		NSFetchRequest* bgRequest = [NSFetchRequest fetchRequestWithEntity:[self class] context:bgContext];
		
		[bgRequest setResultType:NSManagedObjectIDResultType];
		[bgRequest setSortDescriptors:nil];
        
        if (block)
            block(bgRequest);
		
		NSError* bgError	= nil;
		NSArray* bgObjects	= [bgContext executeFetchRequest:bgRequest error:&bgError];
		
		[mainContext performBlock:^{
			
			NSError* error			= nil;
			NSPredicate* predicate	= [NSPredicate predicateWithFormat:@"SELF IN %@", bgObjects];
			NSFetchRequest* request	= [NSFetchRequest fetchRequestWithEntity:[self class] context:mainContext];
			
			if (block)
				block(request);
			
			[request setPredicate:predicate];
			
			NSArray* objects = [mainContext executeFetchRequest:request error:&error];
			
			completion(objects);
		}];
	}];
}

- (void)populateWithDictionary:(NSDictionary *)dictionary
{
	[self populateWithDictionary:dictionary matchTypes:YES];
}

- (void)populateWithDictionary:(NSDictionary *)dictionary matchTypes:(BOOL)matchTypes
{
	NSDictionary* attributes	= [[self entity] attributesByName];
	NSArray* keys				= [attributes allKeys];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
	SEL translateSelector		= @selector(translatePopulationDictionary:);
#pragma clang diagnostic pop
	NSDictionary* arguments;
	
	if ([[self class] respondsToSelector:translateSelector])
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		arguments = [[self class] performSelector:translateSelector withObject:[NSMutableDictionary dictionaryWithDictionary:dictionary]];
#pragma clang diagnostic pop
	else
		arguments = dictionary;
	
	for (id key in arguments) {
		
		if (![keys containsObject:key]) {
#ifdef DEBUG
			NSLog(@"Populating %@, key not found: %@", NSStringFromClass([self class]), key);
#endif
			continue;
		}
		
		id object							= [arguments objectForKey:key];
		NSAttributeDescription* description = [attributes objectForKey:key];
		BOOL typeMatch						= !matchTypes;
		
		if (!typeMatch)
			switch ([description attributeType]) {
					
				case NSInteger16AttributeType:
				case NSInteger32AttributeType:
				case NSInteger64AttributeType:
				case NSDecimalAttributeType:
				case NSDoubleAttributeType:
				case NSFloatAttributeType:
				case NSBooleanAttributeType:
					
					typeMatch = [object isKindOfClass:[NSNumber class]];
					break;
					
				case NSStringAttributeType:
					
					typeMatch = [object isKindOfClass:[NSString class]];
					break;
					
				case NSDateAttributeType:
					
					typeMatch = [object isKindOfClass:[NSDate class]];
					break;
					
				case NSBinaryDataAttributeType:
					
					typeMatch = [object isKindOfClass:[NSData class]];
					break;
					
				case NSTransformableAttributeType:
					
					typeMatch = YES;
					break;
					
				case NSObjectIDAttributeType:
				case NSUndefinedAttributeType:
					
					typeMatch = NO;
					break;
			}
		
		if (typeMatch)
			[self setValue:object forKey:key];
	}
}

#pragma mark - Miscellaneous

- (BOOL)isPersisted
{
	return [[self committedValuesForKeys:nil] count] > 0;
}

- (BOOL)obtainPermanentID
{
	NSError* error = nil;
	
	if (![[self managedObjectContext] obtainPermanentIDsForObjects:@[self] error:&error]) {
#ifdef DEBUG
		[NSException raise:NLCoreDataExceptions.permanentID	format:@"For object: %@", self];
#endif
		return NO;
	}
	
	return YES;
}

- (NSString *)usefulDescription
{
	NSString* objectID			= [[[self objectID] URIRepresentation] absoluteString];
	NSMutableString* string		= [NSMutableString stringWithFormat:@"%@ (%p) %@\n", NSStringFromClass([self class]), self, objectID];
	NSDictionary* relationships = [[self entity] relationshipsByName];
	NSString* nullStr			= @"NULL\n";
	
	[string appendString:[self descriptionOfAttributesWithIndent:1]];
	
	for (NSString* key in relationships) {
		
		NSRelationshipDescription* description	= relationships[key];
		id value								= [self valueForKey:key];
		
		if ([description isToMany]) {
			
			if ([value count]) {
				
				NSInteger i = 0;
				
				for (id obj in value) {
					
					NSString* objID = [[[obj objectID] URIRepresentation] absoluteString];
					
					[string appendFormat:@"	%@ (%@: %@):\n%@", key, @(i), objID, [obj descriptionOfAttributesWithIndent:2]];
					i++;
				}
			}
			else
				[string appendFormat:@"	%@: %@", key, nullStr];
		}
		else {
			
			id desc		= [value descriptionOfAttributesWithIndent:2];
			BOOL isNull = !desc;
			
			[string appendFormat:@"	%@:%@%@", key, isNull ? @"" : @"\n", isNull ? nullStr : desc];
		}
	}
	
	return [NSString stringWithString:string];
}

- (NSString *)objectIDString
{
	return [[[self objectID] URIRepresentation] absoluteString];
}

#pragma mark - Helpers

- (NSString *)descriptionOfAttributesWithIndent:(NSInteger)indent
{
	NSMutableString* string		= [NSMutableString string];
	NSDictionary* attributes	= [[self entity] attributesByName];
	
	for (NSString* key in attributes) {
		
		id val					= [self valueForKey:key];
		NSMutableString* tabs	= [NSMutableString string];
		
		if (!val)
			val = @"NULL";
		else if ([val isKindOfClass:[NSData class]])
			val = [NSString stringWithFormat:@"DATA (length %@)", @([val length])];
		
		for (NSInteger i = 0; i < indent; i++)
			[tabs appendString:@"	"];
		
		[string appendFormat:@"%@%@: %@\n", tabs, key, val];
	}
	
	return [NSString stringWithString:string];
}

@end
