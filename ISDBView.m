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
#import "NSArray+Diff.h"

typedef enum {
  ISDBViewStateInvalid,
  ISDBViewStateCount,
  ISDBViewStateValid
} ISDBViewState;

@interface ISDBView ()

@property (nonatomic) ISDBViewState state;
@property (strong, nonatomic) FMDatabase *database;
@property (strong, nonatomic) id<ISDBViewDataSource> dataSource;
@property (strong, nonatomic) NSArray *entries;
@property (strong, nonatomic) NSMutableDictionary *entriesByIdentifier;
@property (strong, nonatomic) ISNotifier *notifier;

- (void) update;
@end

NSInteger ISDBViewIndexUndefined = -1;

static NSString *const kSQLiteTypeText = @"text";
static NSString *const kSQLiteTypeInteger = @"integer";

@implementation ISDBView

// TODO Consider whether we should support auto incrmenting to be set here.
// Can we infer this from SQLite database?

// TODO Database change feed that all views submit to on changes.

// TODO Consider an editable view.

// TODO Consider whether we wish to cache the row height on behalf of the client.

// TODO Would a pure diff solution work?
// Can I do the diff with a stored procedure?
// Index of order by :).
// Only pull the IDs
// TODO Time the select order by.  If this is quick, then we're home and dry :).
// TODO Consider 'transactional' updates to avoid noisy updates.
// We should version all rows / timestamp rows?

// For variable row height, is it worth storing a CRC or similar for the rowheight row?  You could generate this on an update trigger.

// E.g. Always have row_height_hint view in your column?

// TODO Remember we need to use views more.

// Row height is actually a content change indicator.
// N.B. This obviates the need for content change.

// Helpers for calculating a hash?  Triggers for hash?  Boolean for use hash.


// Returns the identifiers and rows.
//- (NSArray *)rows; // IDs and hints
//- (NSArray *)rowsForOffset:(NSUInteger)offset
//                     limit:(NSUInteger)limit; // -1 for all rows.
// N.B. If a view has no active observer, we can simply ignore updates
// and perform them lazily.
// All updates go via ISDatabase which simply pokes the views.

// Some helper methods for simple table views.
// Potentially a simple adapter for a single view.




// @param identifier Field must be of type auto-incrementing integer.
// @param orderBy Field must be of type string.
- (id) initWithDatabase:(FMDatabase *)database
             dataSource:(id<ISDBViewDataSource>)dataSource
{
  self = [super init];
  if (self) {
    self.database = database;
    self.dataSource = dataSource;
    self.state = ISDBViewStateInvalid;
    self.notifier = [ISNotifier new];
    
//    NSArrayDiff *diff = nil;
//    diff = [@[@"C", @"A", @"B", @"B", @"A"] diff:@[@"C", @"A", @"B", @"B", @"A"]];
//    NSLog(@"%@", diff);
//    diff = [@[@"B", @"A", @"N", @"A", @"N", @"A"] diff:@[@"A", @"T", @"A", @"N", @"A"]];
//    NSLog(@"%@", diff);
//    diff = [@[@"T", @"A", @"N"] diff:@[@"F", @"A", @"N"]];
//    NSLog(@"%@", diff);
    
  }
  return self;
}


- (void)invalidate
{
  assert([[NSThread currentThread] isMainThread]);
  self.state = ISDBViewStateInvalid;
}


- (void)update
{
  assert([[NSThread currentThread] isMainThread]);
  if (self.state != ISDBViewStateValid) {
    self.state = ISDBViewStateValid;
    
    NSArray *updatedEntries = [self.dataSource database:self.database
                                       entriesForOffset:0
                                                  limit:-1];
    
    // Compare the two arrays making the changes...
    if (self.entries != nil) {
      
      NSArrayDiff *diff = [self.entries diff:updatedEntries];
      
      [self.notifier notify:@selector(viewBeginUpdate:)
                 withObject:self];
      for (NSNumber *index in diff.removals) {
        [self.notifier notify:@selector(view:entryDeleted:)
                   withObject:self
                   withObject:index];
      }
      for (NSNumber *index in diff.additions) {
        [self.notifier notify:@selector(view:entryInserted:)
                   withObject:self
                   withObject:index];
      }
      [self.notifier notify:@selector(viewEndUpdate:)
                 withObject:self];
      
      // Then assign the new array.
      self.entries = updatedEntries;
      
    } else {
      
      // Then assign the new array.
      self.entries = updatedEntries;
      
    }
  }
}


- (NSUInteger)count
{
  __block NSUInteger result;
  [self countCompletion:^(NSUInteger count) {
    result = count;
  }];
  return result;
}


- (void)countCompletion:(void (^)(NSUInteger))completionBlock
{
  [self executeSynchronouslyOnMainThread:^{
    [self update];
    completionBlock(self.entries.count);
  }];
}


- (NSDictionary *)entryForIdentifier:(id)identifier
{
  __block NSDictionary *result = nil;
  [self entryForIdentifier:identifier
                completion:^(NSDictionary *entry) {
                  result = entry;
                }];
  return result;
}


- (void)entryForIdentifier:(id)identifier
                completion:(void (^)(NSDictionary *))completionBlock
{
  [self executeSynchronouslyOnMainThread:^{
    NSDictionary *entry = [self.dataSource database:self.database
                                 entryForIdentifier:identifier];
    completionBlock(entry);
  }];
}


- (NSDictionary *)entryForIndex:(NSInteger)index
{
  __block NSDictionary *result = nil;
  [self entryForIndex:index
           completion:^(NSDictionary *entry) {
             result = entry;
           }];
  return result;
}


- (void)entryForIndex:(NSInteger)index
           completion:(void (^)(NSDictionary *))completionBlock
{
  [self executeSynchronouslyOnMainThread:^{
    [self update];
    if (index < self.entries.count) {
      NSDictionary *entry = [self.entries objectAtIndex:index];
      completionBlock(entry);
    } else {
      completionBlock(nil);
    }
  }];
}


- (NSString *)insert:(NSDictionary *)entry
{
  __block NSString *result = nil;
  [self insert:entry
    completion:^(NSString *identifier) {
      result = identifier;
    }];
  return result;
}


- (void)executeSynchronouslyOnMainThread:(ISDBTask)task
{
  if ([[NSThread currentThread] isMainThread]) {
    task();
  } else {
    dispatch_sync(dispatch_get_main_queue(), task);
  }
}


- (void)insert:(NSDictionary *)entry
    completion:(void (^)(NSString *))completionBlock
{
  [self executeSynchronouslyOnMainThread:^{
    if ([self.dataSource respondsToSelector:@selector(database:insert:)]) {
      NSString *identifier = [self.dataSource database:self.database
                                                insert:entry];
      if (identifier) {
        [self invalidate];
      }
      completionBlock(identifier);
    } else {
      // TODO Throw an exception.
    }
  }];
}


- (NSString *)update:(NSDictionary *)entry
{
  __block NSString *result = nil;
  [self update:entry
    completion:^(NSString *identifier) {
      result = identifier;
    }];
  return result;
}


- (void) update:(NSDictionary *)entry
     completion:(void (^)(NSString *))completionBlock
{
  [self executeSynchronouslyOnMainThread:^{
    if ([self.dataSource respondsToSelector:@selector(database:update:)]) {
      NSString *identifier = [self.dataSource database:self.database
                                                update:entry];
      if (identifier) {
        [self invalidate];
      }
      completionBlock(identifier);
    } else {
      // TODO Throw an exception.
    }
  }];
}


- (NSString *)delete:(NSDictionary *)entry
{
  __block NSString *result = nil;
  [self delete:entry
    completion:^(NSString *identifier) {
      result = identifier;
    }];
  return result;
}


- (void)delete:(NSDictionary *)entry
    completion:(void (^)(NSString *))completionBlock
{
  [self executeSynchronouslyOnMainThread:^{
    if ([self.database respondsToSelector:@selector(database:delete:)]) {
      [self update];
      NSString *identifier = [self.dataSource database:self.database
                                                delete:entry];
      if (identifier) {
        [self invalidate];
      }
      completionBlock(identifier);
    } else {
      // TODO Throw an exception.
    }
  }];
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
