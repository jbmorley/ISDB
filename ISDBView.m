//
// Copyright (c) 2013 InSeven Limited.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// 

#import "ISDBView.h"
#import "ISNotifier.h"
#import "ISDBParser.h"

typedef enum {
  ISDBViewStateInvalid,
  ISDBViewStateCount,
  ISDBViewStateValid
} ISDBViewState;

@interface ISDBView ()

@property (nonatomic) ISDBViewState state;
@property (strong, nonatomic) FMDatabase *database;
@property (strong, nonatomic) NSString *table;
@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSString *orderBy;
@property (strong, nonatomic) NSArray *conditions;
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
@end

NSInteger ISDBViewIndexUndefined = -1;

static NSString *const kSQLiteTypeText = @"text";
static NSString *const kSQLiteTypeInteger = @"integer";


@implementation ISDBView

// TODO Consider whether we should support auto incrmenting to be set here.
// Can we infer this from SQLite database?

// TODO Database change feed that all views submit to on changes.

// @param identifier Field must be of type auto-incrementing integer.
// @param orderBy Field must be of type string.
- (id) initWithDatabase:(FMDatabase *)database
                  table:(NSString *)table
             identifier:(NSString *)identifier
                orderBy:(NSString *)orderBy
             conditions:(NSArray *)conditions
{
  self = [super init];
  if (self) {
    self.state = ISDBViewStateInvalid;
    self.database = database;
    self.table = table;
    self.identifier = identifier;
    self.orderBy = orderBy;
    self.conditions = conditions;
    self.notifier = [ISNotifier new];
    self.autoIncrementIdentifier = YES;

    // TODO Write some unit tests for this!
    // TODO Order By
    
    [self testQuery:@"select * from the_table"
             tables:@[@"the_table"]
             fields:@[]];
    [self testQuery:@"select * from random"
             tables:@[@"random"]
             fields:@[]];
    [self testQuery:@"select a from table_two"
             tables:@[@"table_two"]
             fields:@[@"a"]];
    [self testQuery:@"select b, c from table_three"
             tables:@[@"table_three"]
             fields:@[@"b", @"c"]];
    [self testQuery:@"select b, c, d from a"
             tables:@[@"a"]
             fields:@[@"b", @"c", @"d"]];
    [self testQuery:@"select a, c, d from one join two"
             tables:@[@"one", @"two"]
             fields:@[@"a", @"c", @"d"]];
    [self testQuery:@"select a from sets join cards on sets.id = cards.set_id"
             tables:@[@"sets", @"cards"]
             fields:@[@"a"]];
    [self testQuery:@"select a.field from sets join cards on sets.id = cards.set_id"
             tables:@[@"sets", @"cards"]
             fields:@[@"a.field"]];
    [self testQuery:@"SELECT * FROM items WHERE a = b ORDER BY id"
             tables:@[@"sets", @"cards"]
             fields:@[@"a.field"]];
    [self testQuery:@"SELECT (a, b, c) FROM items WHERE a = b ORDER BY id"
             tables:@[@"items", @"cards"]
             fields:@[@"a", @"b", @"c"]];
    [self testQuery:@"SELECT (a, b, c) FROM items ORDER BY id"
             tables:@[@"items"]
             fields:@[@"a", @"b", @"c"]];
    [self testQuery:@"SELECT * FROM sets join cards on sets.id = cards.set_id WHERE a = b ORDER BY id"
             tables:@[@"sets", @"cards"]
             fields:@[]];
    
    
    [self generateQueries];
  }
  return self;
}

- (void)testQuery:(NSString *)query
           tables:(NSArray *)tables
           fields:(NSArray *)fields
{
  ISDBParser *parser = [[ISDBParser alloc] initWithQuery:query];
  
  NSSet *tablesSet = [NSSet setWithArray:tables];
  NSSet *fieldsSet = [NSSet setWithArray:fields];
  
  BOOL equal = YES;
  equal &= [tablesSet isEqualToSet:parser.tables];
  equal &= [fieldsSet isEqualToSet:parser.fields];
  
  NSLog(@"%@ - %@", query, equal ? @"PASS" : @"FAIL");
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


- (void)update
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
      NSMutableDictionary *entry = [NSMutableDictionary dictionaryWithDictionary:[result resultDict]];
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
  
  // @"SELECT * FROM foo WHERE a = ?"
  
  // Steps.
  // 1) Insert the entry into the database.
  // 2) If the insertion succeeds, insert the entry into the local copy.
  // 3) Notify any observers of the insertion.
  
  NSMutableString *query = [NSMutableString stringWithFormat:@"insert into %@ (", self.table];
  
  NSMutableArray *parameters = [NSMutableArray arrayWithCapacity:3];
  NSInteger count = 0;
  for (NSString *field in entry) {
    if (count > 0) {
      [query appendString:@", "];
    }
    [query appendString:field];
    [parameters addObject:[entry objectForKey:field]];
    count++;
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
    // TODO Work out how we correctly determine the identifier.
    id identifier;
    if (self.autoIncrementIdentifier) {
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
    
    NSLog(@"Unable to insert entry %@.  Failed with error '%@'",
          entry,
          [self.database lastErrorMessage]);
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
  // 2) If the update succeeds, update the local copy.
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
