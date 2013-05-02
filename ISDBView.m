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
#import "NSArray+Diff.h"


#define BEGIN_TIME \
  NSDate *start = [NSDate date];
#define END_TIME(a) \
  NSTimeInterval seconds = [start timeIntervalSinceNow] * -1; \
  NSLog(@"%@ (%02f)", a, seconds);

typedef enum {
  ISDBViewStateInvalid,
  ISDBViewStateCount,
  ISDBViewStateValid
} ISDBViewState;

@interface ISDBView ()

@property (nonatomic) ISDBViewState state;
@property (strong, nonatomic) FMDatabase *database;
@property (strong, nonatomic) id<ISDBDataSource> dataSource;
@property (strong, nonatomic) NSArray *entries;
@property (strong, nonatomic) NSMutableDictionary *entriesByIdentifier;
@property (strong, nonatomic) ISNotifier *notifier;
@property (nonatomic) dispatch_queue_t dispatchQueue;

@end

NSInteger ISDBViewIndexUndefined = -1;

static NSString *const kSQLiteTypeText = @"text";
static NSString *const kSQLiteTypeInteger = @"integer";

@implementation ISDBView

- (id) initWithDispatchQueue:(dispatch_queue_t)dispatchQueue
                    database:(FMDatabase *)database
                  dataSource:(id<ISDBDataSource>)dataSource
{
  self = [super init];
  if (self) {
    self.dispatchQueue = dispatchQueue;
    self.database = database;
    self.dataSource = dataSource;
    self.state = ISDBViewStateInvalid;
    self.notifier = [ISNotifier new];
    
    if ([self.dataSource respondsToSelector:@selector(initialize:)]) {
      [self.dataSource initialize:[[ISDBViewReloader alloc] initWithView:self]];
    }
    
    dispatch_sync(self.dispatchQueue, ^{
      [self loadEntries];
    });
    
  }
  return self;
}


- (void)invalidate:(BOOL)reload
{
  @synchronized (self) {
    self.state = ISDBViewStateInvalid;

    // Only attempt to reload if we have no observers.
    if (self.notifier.count > 0) {
      dispatch_async(self.dispatchQueue, ^{
        [self updateEntries];
      });
    }
  }
}


- (void)loadEntries
{
  @synchronized (self) {
    assert(dispatch_get_current_queue() == self.dispatchQueue);
    assert(self.entries == nil);
    assert(self.state == ISDBViewStateInvalid);
    self.entries = [self.dataSource database:self.database
                            entriesForOffset:0
                                       limit:-1];
    self.state = ISDBViewStateValid;
  }
}


- (void)updateEntries
{
  assert(dispatch_get_current_queue() == self.dispatchQueue);
  assert(self.entries != nil);
  
  // Only run if we're not currently updating the entries.
  @synchronized (self) {
    if (self.state == ISDBViewStateValid) {
      return;
    } else {
      self.state = ISDBViewStateValid;
    }
  }
  
  // Fetch the updated entries.
  NSArray *updatedEntries = [self.dataSource database:self.database
                                     entriesForOffset:0
                                                limit:-1];
  
  // Perform the comparison on a different thread to ensure we do
  // not block the UI thread.  Since we are always dispatching updates
  // onto a common queue we can guarantee that updates are performed in
  // order (though they may be delayed).
  // Updates are cross-posted back to the main thread.
//  dispatch_queue_t global_queue
//  = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//  dispatch_async(global_queue, ^{
  
    // We are using an ordered dispatch queue here, so it is guaranteed
    // that the current entries will not be being edited a this point.
    // As we are only performing a read, we can safely do so without
    // entering a synchronized block.
    
    // Determine the changes.
    // This is done in an incredibly rudimentary way at the moment and needs
    // to be improved in the future.
//    NSMutableArray *diff
//    = [NSMutableArray arrayWithCapacity:
//       self.entries.count + updatedEntries.count];
//    for (NSInteger i = self.entries.count-1; i >= 0; i--) {
//      [diff addObject:[NSArrayOperation operationWithType:NSArrayOperationRemove index:i object:self.entries[i]]];
//    }
//    for (NSInteger i = 0; i < updatedEntries.count; i++) {
//      [diff addObject:[NSArrayOperation operationWithType:NSArrayOperationInsert index:i object:updatedEntries[i]]];
//    }
    
    

    
    
    
    // Notify our observers.
    // TODO Consider whether we might be safe to dispatch async here?
    dispatch_sync(dispatch_get_main_queue(), ^{
      @synchronized (self) {
        
        NSInteger countBefore = self.entries.count;
        NSInteger countAfter = updatedEntries.count;
        
        [self.notifier notify:@selector(viewBeginUpdates:)
                   withObject:self];
        
        for (NSInteger i = self.entries.count-1; i >= 0; i--) {
          ISDBEntry *entry = [self.entries objectAtIndex:i];
          NSUInteger newIndex = [updatedEntries indexOfObject:entry];
          if (newIndex == NSNotFound) {
            // Remove.
            [self.notifier notify:@selector(view:entryDeleted:)
                       withObject:self
                       withObject:[NSNumber numberWithInteger:i]];
            countBefore--;
          } else {
            [self.notifier notify:@selector(view:entryMoved:)
                       withObject:self
                       withObject:@[[NSNumber numberWithInteger:i],
             [NSNumber numberWithInteger:newIndex]]];
          }
        }
        
        for (NSUInteger i = 0; i < updatedEntries.count; i++) {
          ISDBEntry *entry = [updatedEntries objectAtIndex:i];
          NSUInteger oldIndex = [self.entries indexOfObject:entry];
          if (oldIndex == NSNotFound) {
            // Add.
            [self.notifier notify:@selector(view:entryInserted:)
                       withObject:self
                       withObject:[NSNumber numberWithInteger:i]];
            countBefore++;
          }
        }
        
        // TODO If the deletes are resolved before anything happens, is this correct?
        for (NSUInteger i = 0; i < self.entries.count; i++) {
//          ISDBEntry *entry = [self.entries objectAtIndex:i];
//          NSUInteger newIndex = [updatedEntries indexOfObject:entry];
//          if (newIndex != NSNotFound) {
//            // Move.
//            if (newIndex != i) {
//              [self.notifier notify:@selector(view:entryMoved:)
//                         withObject:self
//                         withObject:@[[NSNumber numberWithInteger:i],
//               [NSNumber numberWithInteger:newIndex]]];
//            }
//          }
          
        }

        
        assert(countBefore == countAfter);
        
        self.entries = updatedEntries;

        [self.notifier notify:@selector(viewEndUpdates:)
                   withObject:self];
        
      }
      
        
        
        
        
      
//        [self.notifier notify:@selector(viewBeginUpdates:)
//                   withObject:self];
//        
//        self.entries = updatedEntries;
//        
//        for (NSArrayOperation *operation in diff) {
//
//          if (operation.type == NSArrayOperationRemove) {
//            [self.notifier notify:@selector(view:entryDeleted:)
//                       withObject:self
//                       withObject:[NSNumber numberWithInteger:operation.index]];
//          } else if (operation.type == NSArrayOperationInsert) {
//            [self.notifier notify:@selector(view:entryInserted:)
//                       withObject:self
//                       withObject:[NSNumber numberWithInteger:operation.index]];
//          }
//
//        }
//        
//        [self.notifier notify:@selector(viewEndUpdates:)
//                   withObject:self];
//        
//      }

    });
//  });

}


- (NSUInteger)count
{
  @synchronized (self) {
    // We may return an out-of-date result for the count, but we fire an
    // asynchronous update which will ensure we return the latest version
    // as-and-when it is available.
    dispatch_async(self.dispatchQueue, ^{
      [self updateEntries];
    });
    return self.entries.count;
  }
}


- (void)entryForIdentifier:(id)identifier
                completion:(void (^)(NSDictionary *entry))completionBlock
{
  dispatch_queue_t callingQueue = dispatch_get_current_queue();
  dispatch_async(self.dispatchQueue, ^{
    NSDictionary *entry = [self.dataSource database:self.database
                                 entryForIdentifier:identifier];
    dispatch_async(callingQueue, ^{
      completionBlock(entry);
    });
  });
}


- (void)entryForIndex:(NSInteger)index
           completion:(void (^)(NSDictionary *entry))completionBlock
{
  dispatch_queue_t callingQueue = dispatch_get_current_queue();
  dispatch_async(self.dispatchQueue, ^{
    [self updateEntries];
    if (index < self.entries.count) {
      ISDBEntry *dbEntry = [self.entries objectAtIndex:index];
      NSString *identifier = dbEntry.identifier;
      NSDictionary *entry = [self.dataSource database:self.database
                                   entryForIdentifier:identifier];
      dispatch_async(callingQueue, ^{
        completionBlock(entry);
      });
    } else {
      dispatch_async(callingQueue, ^{
        completionBlock(nil);
      });
    }
  });
}


- (void)insert:(NSDictionary *)entry
    completion:(void (^)(id identifier))completionBlock
{
  dispatch_queue_t callingQueue = dispatch_get_current_queue();
  dispatch_async(self.dispatchQueue, ^{
    if ([self.dataSource respondsToSelector:@selector(database:insert:)]) {
      NSString *identifier = [self.dataSource database:self.database
                                                insert:entry];
      if (identifier) {
        [self invalidate:NO];
      }
      if (completionBlock != NULL) {
        dispatch_async(callingQueue, ^{
          completionBlock(identifier);
        });
      }
    } else {
      // TODO Throw an exception.
    }
  });
}


- (void) update:(NSDictionary *)entry
     completion:(void (^)(id identifier))completionBlock
{
  dispatch_queue_t callingQueue = dispatch_get_current_queue();
  dispatch_async(self.dispatchQueue, ^{
    if ([self.dataSource respondsToSelector:@selector(database:update:)]) {
      NSString *identifier = [self.dataSource database:self.database
                                                update:entry];
      if (identifier) {
        [self invalidate:NO];
      }
      if (completionBlock != NULL) {
        dispatch_async(callingQueue, ^{
          completionBlock(identifier);
        });
      }
    } else {
      // TODO Throw an exception.
    }
  });
}


- (void)delete:(NSDictionary *)entry
    completion:(void (^)(id identifier))completionBlock
{
  dispatch_queue_t callingQueue = dispatch_get_current_queue();
  dispatch_async(self.dispatchQueue, ^{
    if ([self.database respondsToSelector:@selector(database:delete:)]) {
      [self updateEntries];
      NSString *identifier = [self.dataSource database:self.database
                                                delete:entry];
      if (identifier) {
        [self invalidate:NO];
      }
      if (completionBlock != NULL) {
        dispatch_sync(callingQueue, ^{
          completionBlock(identifier);
        });
      }
    } else {
      // TODO Throw an exception.
    }
  });
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


@end
