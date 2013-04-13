//
//  ISDBView.m
//  Learn
//
//  Created by Jason Barrie Morley on 11/01/2013.
//
//

#import "ISDBView.h"
#import "ISNotifier.h"

typedef enum {
  ISDBViewStateInvalid,
  ISDBViewStateCount,
  ISDBViewStateValid
} ISDBViewState;

typedef enum {
  ISDBViewTypeString,
  ISDBViewTypeNumber
} ISDBViewType;

@interface ISDBView ()

@property (nonatomic) ISDBViewState state;
@property (strong, nonatomic) FMDatabase *database;
@property (strong, nonatomic) NSString *table;
@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSString *orderBy;
@property (strong, nonatomic) NSArray *fields;
@property (strong, nonatomic) NSArray *conditions;
@property (strong, nonatomic) NSMutableDictionary *types;
@property (strong, nonatomic) NSMutableString *queryList;
@property (strong, nonatomic) NSMutableArray *queryListParameters;
@property (strong, nonatomic) NSMutableString *queryCount;
@property (strong, nonatomic) NSMutableArray *queryCountParameters;
@property (strong, nonatomic) NSMutableArray *entries;
@property (strong, nonatomic) NSMutableDictionary *entriesByIdentifier;
@property (strong, nonatomic) ISNotifier *notifier;
@property (nonatomic) NSUInteger cachedCount;

- (void) generateQueries;
- (void) update;
- (void) sort;
- (ISDBViewType)typeForField:(NSString *)field
                 defaultType:(ISDBViewType)defaultType;
- (void)copyField:(NSString *)field
    fromResultSet:(FMResultSet *)result
          toEntry:(NSMutableDictionary *)entry
      defaultType:(ISDBViewType)defaultType;

@end

NSInteger ISDBViewIndexUndefined = -1;

@implementation ISDBView

// TODO Consider whether we should support auto incrmenting to be set here.

// @param identifier Field must be of type auto-incrementing integer.
// @param orderBy Field must be of type string.
- (id) initWithDatabase:(FMDatabase *)database
                  table:(NSString *)table
             identifier:(NSString *)identifier
                orderBy:(NSString *)orderBy
                 fields:(NSArray *)fields
             conditions:(NSArray *)conditions
{
  self = [super init];
  if (self) {
    self.state = ISDBViewStateInvalid;
    self.database = database;
    self.table = table;
    self.identifier = identifier;
    self.orderBy = orderBy;
    self.fields = fields;
    self.conditions = conditions;
    self.types = [NSMutableDictionary dictionaryWithCapacity:3];
    self.notifier = [ISNotifier new];
    self.autoIncrementIdentifier = YES;
    
    [self generateQueries];
  }
  return self;
}

- (void) generateQueries
{
  // List.
  self.queryList
    = [NSMutableString stringWithFormat:@"select * from %@", self.table];
  self.queryListParameters = [NSMutableArray arrayWithCapacity:3];

  NSInteger count = 0;
  for (ISDBCondition *condition in self.conditions) {
    if (count == 0) {
      [self.queryList appendString:@" where "];
    } else {
      [self.queryList appendString:@" and "];
    }
    [self.queryList appendString:condition.string];
    [self.queryListParameters addObject:condition.value];
    count++;
  }
  
  // Count.
  self.queryCount = [NSMutableString stringWithFormat:@"select count(*) as \"count\" from %@", self.table];
  
  self.queryCountParameters = [NSMutableArray arrayWithCapacity:3];
  count = 0;
  for (ISDBCondition *condition in self.conditions) {
    if (count == 0) {
      [self.queryCount appendString:@" where "];
    } else {
      [self.queryCount appendString:@" and "];
    }
    [self.queryCount appendString:condition.string];
    [self.queryCountParameters addObject:condition.value];
    count++;
  }
  
}


- (void)copyField:(NSString *)field
    fromResultSet:(FMResultSet *)result
          toEntry:(NSMutableDictionary *)entry
      defaultType:(ISDBViewType)defaultType
{
  ISDBViewType type = [self typeForField:field
                             defaultType:defaultType];
  if (type == ISDBViewTypeString) {
    [entry setObject:[result stringForColumn:field]
              forKey:field];
  } else if (type == ISDBViewTypeNumber) {
    [entry setObject:[NSNumber numberWithInt:[result intForColumn:field]]
              forKey:field];
  }
}


- (void) update
{
  if (self.state != ISDBViewStateValid) {
    self.state = ISDBViewStateValid;
    
    self.entries
      = [NSMutableArray arrayWithCapacity:3];
    self.entriesByIdentifier
      = [NSMutableDictionary dictionaryWithCapacity:3];
    FMResultSet *result
      = [self.database executeQuery:self.queryList
               withArgumentsInArray:self.queryListParameters];
    while ([result next]) {
      NSMutableDictionary *entry
        = [NSMutableDictionary dictionaryWithCapacity:3];
      
      // Identifier.
      [self copyField:self.identifier
        fromResultSet:result
              toEntry:entry
          defaultType:ISDBViewTypeNumber];
      
      // Order By.
      if (self.orderBy != nil) {
        [self copyField:self.orderBy
          fromResultSet:result
                toEntry:entry
            defaultType:ISDBViewTypeString];
      }
      
      // Fields.
      for (NSString *field in self.fields) {
        [self copyField:field
          fromResultSet:result
                toEntry:entry
            defaultType:ISDBViewTypeString];
      }
      
      [self.entries addObject:entry];
      [self.entriesByIdentifier setObject:entry
                                   forKey:[entry objectForKey:self.identifier]];
    }
    [self sort];
  }
}


- (void) sort
{
  if (self.orderBy != nil) {
    [self.entries sortUsingComparator:^NSComparisonResult(id a, id b) {
      NSDictionary *entryA = a;
      NSDictionary *entryB = b;
      return [[entryA objectForKey:self.orderBy] caseInsensitiveCompare:[entryB objectForKey:self.orderBy]];
    }];
  }
}


- (void) setClass:(Class)cls
         forField:(NSString *)field
{
  if (cls == [NSNumber class]) {
    [self.types setObject:[NSNumber numberWithInt:ISDBViewTypeNumber]
                   forKey:field];
  } else if (cls == [NSString class]) {
    [self.types setObject:[NSNumber numberWithInt:ISDBViewTypeString]
                   forKey:field];
  } else {
    NSAssert(false, @"Unsupported class");
  }
}


- (ISDBViewType)typeForField:(NSString *)field
                defaultType:(ISDBViewType)defaultType
{
  NSNumber *type = [self.types objectForKey:field];
  if (type != nil) {
    return [type integerValue];
  } else {
    return defaultType;
  }
}


- (NSUInteger) count
{
  // If we're not yet loaded, go straight down to the database for the
  // count.  This avoids loading in every entry when we may just be after
  // a summary.
  if (self.state == ISDBViewStateInvalid) {
    
    FMResultSet *result
      = [self.database executeQuery:self.queryCount
               withArgumentsInArray:self.queryCountParameters];
    if ([result next]) {
      self.cachedCount = [result intForColumn:@"count"];
    }
    self.state = ISDBViewStateCount;
    return self.cachedCount;
    
  } else if (self.state == ISDBViewStateCount) {
    
    return self.cachedCount;
    
  } else {
    
    return self.entries.count;
    
  }
}


- (NSInteger) indexForIdentifier:(id)identifier
{
  [self update];
  NSDictionary *entry = [self.entriesByIdentifier objectForKey:identifier];
  if (entry != nil) {
    return [self.entries indexOfObject:entry];
  }
  return ISDBViewIndexUndefined;
}


- (NSDictionary *) entryForIdentifier:(id)identifier
{
  [self update];
  return [self.entriesByIdentifier objectForKey:identifier];
}


- (NSDictionary *) entryForIndex:(NSInteger)index
{
  [self update];
  if (index < self.entries.count) {
    return [self.entries objectAtIndex:index];
  }
  return nil;
}


- (NSDictionary *) insert:(NSDictionary *)entry
{
  __block NSDictionary *result = nil;
  [self insert:entry
    completion:^(NSDictionary *cachedEntry) {
      result = cachedEntry;
    }];
  return result;
}


- (void) insert:(NSDictionary *)entry
     completion:(void (^)(NSDictionary *))completionBlock
{
  [self update];
  
  // Steps.
  // 1) Insert the entry into the database.
  // 2) If the insertion succeeds, insert the entry into the local copy.
  // 3) Notify any observers of the insertion.
  
  NSMutableString *query = [NSMutableString stringWithFormat:@"insert into %@ (", self.table];
  
  NSMutableArray *parameters = [NSMutableArray arrayWithCapacity:3];
  NSInteger count = 0;
  for (NSString *field in entry) {
    // Ignore the identifier.
    if (![field isEqualToString:self.identifier]) {
      if (count > 0) {
        [query appendString:@", "];
      }
      [query appendString:field];
      [parameters addObject:[entry objectForKey:field]];
      count++;
    }
  }
  [query appendString:@") values ("];
  
  count = 0;
  for (NSString *parameter in parameters) {
    if (count > 0) {
      [query appendString:@", "];
    }
    [query appendString:@"?"];
    count++;
  }
  [query appendString:@")"];
  
  BOOL success = [self.database executeUpdate:query
                         withArgumentsInArray:parameters];
  
  if (success) {
    // Update the local copy.
    NSMutableDictionary *cachedEntry
      = [NSMutableDictionary dictionaryWithDictionary:entry];
    
    // Determine the identifier so we know where we've been inserted.
    id identifier;
    if (self.autoIncrementIdentifier &&
        [self typeForField:self.identifier
               defaultType:ISDBViewTypeNumber]) {
      identifier = [NSNumber numberWithInt:[self.database lastInsertRowId]];
    } else {
      identifier = [entry objectForKey:self.identifier];
    }
    
    // Cache the entry.
    [cachedEntry setObject:identifier
                    forKey:self.identifier];
    [self.entries addObject:cachedEntry];
    [self.entriesByIdentifier setObject:cachedEntry
                                 forKey:identifier];
    
    // Call the completion block once we've correctly inserted the new
    // dictionary to allow external binding APIs to ensure they're
    // up-to-date.
    if (completionBlock != NULL) {
      completionBlock(cachedEntry);
    }
    
    // Determine the new location.
    [self sort];
    NSInteger index = [self.entries indexOfObject:cachedEntry];

    [self.notifier notify:@selector(view:entryInserted:)
                       withObject:self
                       withObject:[NSNumber numberWithInt:index]];
  } else {
    
    NSLog(@"Unable to insert row: %@", [self.database lastErrorMessage]);
    if (completionBlock != NULL) {
      completionBlock(nil);
    }
    
  }
}


- (BOOL) update:(NSDictionary *)entry
{
  [self update];
  
  // Steps:
  // 1) Update the database.
  // 2) If the udpate succeeds, update the local copy.
  // 3) Notify any observers of any location changes.
  
  NSMutableString *query = [NSMutableString stringWithFormat:@"update %@ set ", self.table];
  
  NSMutableArray *parameters = [NSMutableArray arrayWithCapacity:3];
  NSInteger count = 0;
  for (NSString *field in entry) {
    // Ignore the identifier.
    if (![field isEqualToString:self.identifier]) {
      if (count > 0) {
        [query appendString:@", "];
      }
      [query appendFormat:@"%@ = ?", field];
      [parameters addObject:[entry objectForKey:field]];
      count++;
    }
  }
  [query appendFormat:@" where %@ = ?", self.identifier];
  [parameters addObject:[entry objectForKey:self.identifier]];
  
  BOOL success = [self.database executeUpdate:query
                         withArgumentsInArray:parameters];
  
  if (success) {
    // Update the local copy.
    NSMutableDictionary *cachedEntry = [self.entriesByIdentifier objectForKey:[entry objectForKey:self.identifier]];
    
    for (NSString *field in entry) {
      [cachedEntry setObject:[entry objectForKey:field]
                      forKey:field];
    }
    
    // Determine the new location.
    NSInteger oldIndex = [self.entries indexOfObject:cachedEntry];
    [self sort];
    NSInteger newIndex = [self.entries indexOfObject:cachedEntry];
    
    if (oldIndex != newIndex) {
      [self.notifier notify:@selector(view:entryMoved:)
                         withObject:self
                         withObject:@[[NSNumber numberWithInt:oldIndex],
                                      [NSNumber numberWithInt:newIndex]]];
    } else {
      [self.notifier notify:@selector(view:entryUpdated:)
                         withObject:self
                         withObject:[NSNumber numberWithInt:oldIndex]];
    }
    
  }
  
  return success;
}


- (BOOL) delete:(NSDictionary *)entry
{
  [self update];
  
  // Steps:
  // 1) Update the database.
  // 2) Rmeove the entry from the local copy.
  // 3) Notify any observers of location changes.
  
  NSMutableString *query = [NSMutableString stringWithFormat:@"delete from %@ where %@ = ?", self.table, self.identifier];
  
  NSNumber *identifier = [entry objectForKey:self.identifier];
  
  BOOL success = [self.database executeUpdate:query
                         withArgumentsInArray:@[identifier]];
  if (success) {
    NSMutableDictionary *cachedEntry = [self.entriesByIdentifier objectForKey:identifier];
    NSInteger index = [self.entries indexOfObject:cachedEntry];
    
    [self.entries removeObject:cachedEntry];
    [self.entriesByIdentifier removeObjectForKey:identifier];
    
    [self.notifier notify:@selector(view:entryDeleted:)
                       withObject:self
                       withObject:[NSNumber numberWithInt:index]];
  }
  return success;
}


#pragma mark - Observers


- (void) addObserver:(id<ISDBViewObserver>)observer
{
  [self.notifier addObserver:observer];
}


- (void) removeObserver:(id<ISDBViewObserver>)observer
{
  [self.notifier removeObserver:observer];
}


@end
