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


#define DISPATCH_QUEUE

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
@property (nonatomic) dispatch_queue_t dispatchQueue;

- (void) update;
@end

NSInteger ISDBViewIndexUndefined = -1;

static NSString *const kSQLiteTypeText = @"text";
static NSString *const kSQLiteTypeInteger = @"integer";

@implementation ISDBView

- (id) initWithDispatchQueue:(dispatch_queue_t)dispatchQueue
                    database:(FMDatabase *)database
                  dataSource:(id<ISDBViewDataSource>)dataSource
{
  self = [super init];
  if (self) {
    self.dispatchQueue = dispatchQueue;
    self.database = database;
    self.dataSource = dataSource;
    self.state = ISDBViewStateInvalid;
    self.notifier = [ISNotifier new];
  }
  return self;
}


- (void)invalidate
{
  assert([[NSThread currentThread] isMainThread]);
  self.state = ISDBViewStateInvalid;
}


- (void)reload
{
  [self invalidate];
  // Force an update through if we have active observers.
  if (self.notifier.count > 0) {
    [self update];
  }
}


- (void)update
{
  assert([[NSThread currentThread] isMainThread]);
  if (self.state != ISDBViewStateValid) {
    self.state = ISDBViewStateValid;
    
    // Fetch the updated entries.
    NSArray *updatedEntries = [self.dataSource database:self.database
                                       entriesForOffset:0
                                                  limit:-1];
    
    if (self.entries == nil) {
    
      // When initially updating the view it is not necessary to
      // perform a comparison.  We therefore update the entries
      // immediately.
      self.entries = updatedEntries;
      
    } else {
      
      // Perform the comparison on a different thread to ensure we do
      // not block the UI thread.  Since we are always dispatching updates
      // onto a common queue we can guarantee that updates are performed in
      // order (though they may be delayed).
      // Updates are cross-posted back to the main thread.
#ifdef DISPATCH_QUEUE
      dispatch_async(self.dispatchQueue, ^{
#endif
      
        BEGIN_TIME;
        NSArrayDiff *diff = [self.entries diff:updatedEntries];
        END_TIME(@"Update");
        
        // Notify our observers.
#ifdef DISPATCH_QUEUE
        dispatch_sync(dispatch_get_main_queue(), ^{
#endif
          [self.notifier notify:@selector(viewBeginUpdates:)
                     withObject:self];
          
          self.entries = updatedEntries;
          
          for (NSArray *move in diff.moves) {
            [self.notifier notify:@selector(view:entryMoved:)
                       withObject:self
                       withObject:move];
          }
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
          [self.notifier notify:@selector(viewEndUpdates:)
                     withObject:self];

#ifdef DISPATCH_QUEUE
        });
      });
#endif
    
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
