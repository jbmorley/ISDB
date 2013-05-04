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
#import "FMDatabaseQueue+Current.h"

typedef enum {
  ISDBViewStateInvalid,
  ISDBViewSateUpdating,
  ISDBViewStateValid
} ISDBViewState;


@interface ISDBViewOperation : NSObject

@property (nonatomic) ISDBOperation type;
@property (strong, nonatomic) id payload;

+ (id)operationWithType:(ISDBOperation)type
                payload:(id)payload;
- (id)initWithType:(ISDBOperation)type
           payload:(id)payload;

@end

@implementation ISDBViewOperation

+ (id)operationWithType:(ISDBOperation)type
                payload:(id)payload
{
  return [[self alloc] initWithType:type
                            payload:payload];
}

- (id)initWithType:(ISDBOperation)type
           payload:(id)payload
{
  self = [super init];
  if (self) {
    self.type = type;
    self.payload = payload;
  }
  return self;
}

@end

@interface ISDBView ()

@property (nonatomic) ISDBViewState state;
@property (strong, nonatomic) id<ISDBDataSource> dataSource;
@property (strong, nonatomic) NSArray *entries;
@property (strong, nonatomic) NSMutableDictionary *entriesByIdentifier;
@property (strong, nonatomic) ISNotifier *notifier;
@property (nonatomic) FMDatabaseQueue *queue;
@property (nonatomic) dispatch_queue_t comparisonQueue;
@property (nonatomic) BOOL batchUpdate;

@end

NSInteger ISDBViewIndexUndefined = -1;

static NSString *const kSQLiteTypeText = @"text";
static NSString *const kSQLiteTypeInteger = @"integer";

@implementation ISDBView

- (id) initWithQueue:(FMDatabaseQueue *)queue
          dataSource:(id<ISDBDataSource>)dataSource
{
  self = [super init];
  if (self) {
    self.queue = queue;
    self.dataSource = dataSource;
    self.state = ISDBViewStateInvalid;
    self.notifier = [ISNotifier new];
    self.batchUpdate = NO;
    
    if ([self.dataSource respondsToSelector:@selector(initialize:)]) {
      [self.dataSource initialize:[[ISDBViewReloader alloc] initWithView:self]];
    }
    
    NSString *queueIdentifier = [NSString stringWithFormat:@"%@%p",
                                 @"uk.co.inseven.view.",
                                 self];
    self.comparisonQueue
    = dispatch_queue_create([queueIdentifier UTF8String], NULL);
    
    [self.queue inDatabase:^(FMDatabase *db) {
      [self loadEntries:db];
    }];
    
    
  }
  return self;
}


- (void)invalidate:(BOOL)reload
{
  @synchronized (self) {
    self.state = ISDBViewStateInvalid;
    if (self.notifier.count > 0) {
      [self scheduleUpdate];
    }
  }
}


- (void)loadEntries:(FMDatabase *)database;
{
  @synchronized (self) {
    assert(self.entries == nil);
    assert(self.state == ISDBViewStateInvalid);
    self.entries = [self.dataSource database:database
                            entriesForOffset:0
                                       limit:-1];
    self.state = ISDBViewStateValid;
  }
}


- (void)scheduleUpdate
{
  @synchronized (self) {
    
    // Don't attempt any udpates when we're in a batch update mode.
    if (self.batchUpdate) {
      return;
    }
    
    if (self.state == ISDBViewStateInvalid) {
      dispatch_async(self.comparisonQueue, ^{
        [self.queue inDatabase:^(FMDatabase *db) {
          [self updateEntries:db];
        }];
      });
    }
    
  }
}


- (void)updateEntries:(FMDatabase *)database
{
  assert(self.entries != nil);
  // TODO Consider counting the no-ops.
  
  // Only run if we're not currently updating the entries.
  @synchronized (self) {
    if (self.state == ISDBViewStateInvalid) {
      self.state = ISDBViewSateUpdating;
    } else {
      return;
    }
  }
  
  NSLog(@"+ updatedEntries:");
  
  // Fetch the updated entries.
  NSArray *updatedEntries = [self.dataSource database:database
                                     entriesForOffset:0
                                                limit:-1];
  
  // Cross-post the comparison onto a separate serial dispatch queue.
  // This ensures all updates are ordered.
  dispatch_async(self.comparisonQueue, ^{
    
    @synchronized (self) {
      self.state = ISDBViewStateValid;
    }

    // Perform the comparison on a different thread to ensure we do
    // not block the UI thread.  Since we are always dispatching updates
    // onto a common queue we can guarantee that updates are performed in
    // order (though they may be delayed).
    // Updates are cross-posted back to the main thread.
    // We are using an ordered dispatch queue here, so it is guaranteed
    // that the current entries will not be being edited a this point.
    // As we are only performing a read, we can safely do so without
    // entering a synchronized block.
    NSMutableArray *actions = [NSMutableArray arrayWithCapacity:3];
    NSMutableArray *updates = [NSMutableArray arrayWithCapacity:3];
    NSInteger countBefore = self.entries.count;
    NSInteger countAfter = updatedEntries.count;
    
    // Removes and moves.
    for (NSInteger i = self.entries.count-1; i >= 0; i--) {
      ISDBEntryDescription *entry = [self.entries objectAtIndex:i];
      NSUInteger newIndex = [updatedEntries indexOfObject:entry];
      if (newIndex == NSNotFound) {
        // Remove.
        ISDBViewOperation *operation
        = [ISDBViewOperation operationWithType:ISDBOperationDelete
                                       payload:[NSNumber numberWithInteger:i]];
        [actions addObject:operation];
        countBefore--;
      } else {
        if (i != newIndex) {
          // Move.
          ISDBViewOperation *operation
          = [ISDBViewOperation operationWithType:ISDBOperationMove
                                         payload:@[[NSNumber numberWithInteger:i],
             [NSNumber numberWithInteger:newIndex]]];
          [actions addObject:operation];
        }
      }
    }
    
    // Additions and updates.
    for (NSUInteger i = 0; i < updatedEntries.count; i++) {
      ISDBEntryDescription *entry = [updatedEntries objectAtIndex:i];
      NSUInteger oldIndex = [self.entries indexOfObject:entry];
      if (oldIndex == NSNotFound) {
        // Add.
        ISDBViewOperation *operation
        = [ISDBViewOperation operationWithType:ISDBOperationInsert
                                       payload:[NSNumber numberWithInteger:i]];
        [actions addObject:operation];
        countBefore++;
      } else {
        ISDBEntryDescription *oldEntry = [self.entries objectAtIndex:oldIndex];
        if (![oldEntry isSummaryEqual:entry]) {
          [updates addObject:[NSNumber numberWithInteger:i]];
        }
      }
    }
    
    assert(countBefore == countAfter);
    
    // This will catch any invalidations which occured while we were
    // busy updating the database view.
    [self scheduleUpdate];
    
    // Notify our observers.
    dispatch_sync(dispatch_get_main_queue(), ^{
      @synchronized (self) {
        
        [self.notifier notify:@selector(viewBeginUpdates:)
                   withObject:self];
        
        for (ISDBViewOperation *operation in actions) {
          if (operation.type == ISDBOperationDelete) {
            [self.notifier notify:@selector(view:entryDeleted:)
                       withObject:self
                       withObject:operation.payload];
          } else if (operation.type == ISDBOperationMove) {
            [self.notifier notify:@selector(view:entryMoved:)
                       withObject:self
                       withObject:operation.payload];
          } else if (operation.type == ISDBOperationInsert) {
            [self.notifier notify:@selector(view:entryInserted:)
                       withObject:self
                       withObject:operation.payload];
          }
          
        }
        self.entries = updatedEntries;
        [self.notifier notify:@selector(viewEndUpdates:)
                   withObject:self];
        
        // We perform updates in a separate beginUpdates block to avoid
        // performing multiple operations when used as a data source for
        // UITableView.
        [self.notifier notify:@selector(viewBeginUpdates:)
                   withObject:self];
        for (NSNumber *index in updates) {
          [self.notifier notify:@selector(view:entryUpdated:)
                     withObject:self
                     withObject:index];
        }
        [self.notifier notify:@selector(viewEndUpdates:)
                   withObject:self];
        
        
      }
    });
    
  });
  NSLog(@"- updatedEntries:");
}


- (NSUInteger)count
{
  @synchronized (self) {
    // We may return an out-of-date result for the count, but we fire an
    // asynchronous update which will ensure we return the latest version
    // as-and-when it is available.
    [self scheduleUpdate];
    return self.entries.count;
  }
}


- (void)entryForIdentifier:(id)identifier
                completion:(void (^)(NSDictionary *entry))completionBlock
{
//  dispatch_queue_t callingQueue = dispatch_get_current_queue();
  [self.queue inDatabaseReentrant:^(FMDatabase *db) {
    NSDictionary *entry = [self.dataSource database:db
                                 entryForIdentifier:identifier];
//    dispatch_async(callingQueue, ^{
      completionBlock(entry);
//    });
  }];
}


- (void)entryForIndex:(NSInteger)index
           completion:(void (^)(NSDictionary *entry))completionBlock
{
  [self scheduleUpdate];
//  dispatch_queue_t callingQueue = dispatch_get_current_queue();
  [self.queue inDatabaseReentrant:^(FMDatabase *db) {
    if (index < self.entries.count) {
      ISDBEntryDescription *dbEntry = [self.entries objectAtIndex:index];
      id identifier = dbEntry.identifier;
      NSDictionary *entry = [self.dataSource database:db
                                   entryForIdentifier:identifier];
//      dispatch_async(callingQueue, ^{
        completionBlock(entry);
//      });
    } else {
//      dispatch_async(callingQueue, ^{
        completionBlock(nil);
//      });
    }
  }];
}


- (void)insert:(NSDictionary *)entry
    completion:(void (^)(id identifier))completionBlock
{
//  dispatch_queue_t callingQueue = dispatch_get_current_queue();
  [self.queue inDatabaseReentrant:^(FMDatabase *db) {
    if ([self.dataSource respondsToSelector:@selector(database:insert:)]) {
      NSString *identifier = [self.dataSource database:db
                                                insert:entry];
      if (identifier) {
        [self invalidate:NO];
      }
      if (completionBlock != NULL) {
//        dispatch_async(callingQueue, ^{
          completionBlock(identifier);
//        });
      }
    } else {
      @throw [NSException exceptionWithName:@"DataSourceInsertUnsupported"
                                     reason:@"The data source does not implement the database:insert: selector."
                                   userInfo:nil];
    }
  }];
}


- (void) update:(NSDictionary *)entry
     completion:(void (^)(id identifier))completionBlock
{
//  dispatch_queue_t callingQueue = dispatch_get_current_queue();
  [self.queue inDatabaseReentrant:^(FMDatabase *db) {
    NSLog(@"Database Update");
    if ([self.dataSource respondsToSelector:@selector(database:update:)]) {
      NSString *identifier = [self.dataSource database:db
                                                update:entry];
      if (identifier) {
        [self invalidate:NO];
      }
      if (completionBlock != NULL) {
//        dispatch_async(callingQueue, ^{
          completionBlock(identifier);
//        });
      }
    } else {
      @throw [NSException exceptionWithName:@"DataSourceUpdateUnsupported"
                                     reason:@"The data source does not implement the database:update: selector."
                                   userInfo:nil];
    }
  }];
}


- (void)delete:(NSDictionary *)entry
    completion:(void (^)(id identifier))completionBlock
{
  [self scheduleUpdate];
//  dispatch_queue_t callingQueue = dispatch_get_current_queue();
  [self.queue inDatabase:^(FMDatabase *db) {
    if ([self.dataSource respondsToSelector:@selector(database:delete:)]) {
      NSString *identifier = [self.dataSource database:db
                                                delete:entry];
      if (identifier) {
        [self invalidate:NO];
      }
      if (completionBlock != NULL) {
//        dispatch_sync(callingQueue, ^{
          completionBlock(identifier);
//        });
      }
    } else {
      @throw [NSException exceptionWithName:@"DataSourceDeleteUnsupported"
                                     reason:@"The data source does not implement the database:delete: selector."
                                   userInfo:nil];
    }
  }];
}


#pragma mark - Observers


- (void) addObserver:(id<ISDBViewObserver>)observer
{
  @synchronized (self) {
    [self.notifier addObserver:observer];
  }
}


- (void) removeObserver:(id<ISDBViewObserver>)observer
{
  @synchronized (self) {
    [self.notifier removeObserver:observer];
  }
}


- (void)beginUpdate
{
  @synchronized (self) {
    NSLog(@"BEGIN BATCH UPDATE");
    self.batchUpdate = YES;
  }
}

- (void)endUpdate
{
  @synchronized (self) {
    NSLog(@"END BATCH UPDATE");
    self.batchUpdate = NO;
    [self scheduleUpdate];
  }
}


@end
