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
  BEGIN_TIME
  NSArray *updatedEntries = [self.dataSource database:self.database
                                     entriesForOffset:0
                                                limit:-1];
  END_TIME(@"Update")
  
  // Perform the comparison on a different thread to ensure we do
  // not block the UI thread.  Since we are always dispatching updates
  // onto a common queue we can guarantee that updates are performed in
  // order (though they may be delayed).
  // Updates are cross-posted back to the main thread.
  dispatch_queue_t global_queue
  = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_async(global_queue, ^{
    
    BEGIN_TIME;
    NSArray *diff = [self.entries diff:updatedEntries];
    END_TIME(@"Compare");
    
    // Notify our observers.
    dispatch_sync(dispatch_get_main_queue(), ^{
      [self.notifier notify:@selector(viewBeginUpdates:)
                 withObject:self];
      
      self.entries = updatedEntries;
      
      for (NSArrayOperation *operation in diff) {

        if (operation.type == NSArrayOperationRemove) {
          [self.notifier notify:@selector(view:entryDeleted:)
                     withObject:self
                     withObject:[NSNumber numberWithInteger:operation.index]];
        } else if (operation.type == NSArrayOperationInsert) {
          [self.notifier notify:@selector(view:entryInserted:)
                     withObject:self
                     withObject:[NSNumber numberWithInteger:operation.index]];
        }

        //[self.notifier notify:@selector(view:entryMoved:)
        //           withObject:self
        //           withObject:move];
      }
      
      [self.notifier notify:@selector(viewEndUpdates:)
                 withObject:self];

    });
  });

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


- (void)countCompletion:(void (^)(NSUInteger))completionBlock
{
  dispatch_async(self.dispatchQueue, ^{
    [self updateEntries];
    completionBlock(self.entries.count);
  });
}


- (void)entryForIdentifier:(id)identifier
                completion:(void (^)(NSDictionary *entry))completionBlock
{
  dispatch_async(self.dispatchQueue, ^{
    NSDictionary *entry = [self.dataSource database:self.database
                                 entryForIdentifier:identifier];
    dispatch_async(dispatch_get_main_queue(), ^{
      completionBlock(entry);
    });
  });
}


- (void)entryForIndex:(NSInteger)index
           completion:(void (^)(NSDictionary *entry))completionBlock
{
  dispatch_async(self.dispatchQueue, ^{
    [self updateEntries];
    if (index < self.entries.count) {
      NSString *identifier = [self.entries objectAtIndex:index];
      NSDictionary *entry = [self.dataSource database:self.database
                                   entryForIdentifier:identifier];
      dispatch_async(dispatch_get_main_queue(), ^{
        completionBlock(entry);
      });
    } else {
      dispatch_async(dispatch_get_main_queue(), ^{
        completionBlock(nil);
      });
    }
  });
}


- (void)insert:(NSDictionary *)entry
    completion:(void (^)(id identifier))completionBlock
{
  dispatch_async(self.dispatchQueue, ^{
    if ([self.dataSource respondsToSelector:@selector(database:insert:)]) {
      NSString *identifier = [self.dataSource database:self.database
                                                insert:entry];
      if (identifier) {
        [self invalidate:NO];
      }
      if (completionBlock != NULL) {
        dispatch_async(dispatch_get_main_queue(), ^{
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
  dispatch_async(self.dispatchQueue, ^{
    if ([self.dataSource respondsToSelector:@selector(database:update:)]) {
      NSString *identifier = [self.dataSource database:self.database
                                                update:entry];
      if (identifier) {
        [self invalidate:NO];
      }
      if (completionBlock != NULL) {
        dispatch_async(dispatch_get_main_queue(), ^{
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
  dispatch_async(self.dispatchQueue, ^{
    if ([self.database respondsToSelector:@selector(database:delete:)]) {
      [self updateEntries];
      NSString *identifier = [self.dataSource database:self.database
                                                delete:entry];
      if (identifier) {
        [self invalidate:NO];
      }
      if (completionBlock != NULL) {
        dispatch_sync(dispatch_get_main_queue(), ^{
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
