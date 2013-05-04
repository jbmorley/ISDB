//
//  ISDBChangeStream.m
//  Popcorn
//
//  Created by Jason Barrie Morley on 03/05/2013.
//
//

#import "ISDBChangeStream.h"

typedef enum {
  
  ISDBChangeStreamStateIdle,
  ISDBChangeStreamStateUpdating
  
} ISDBChangeStreamState;

@interface ISDBChangeStream ()

@property (nonatomic) ISDBChangeStreamState state;
@property (strong, nonatomic) ISDBView *view;
@property (strong, nonatomic) NSMutableArray *additions;
@property (strong, nonatomic) NSMutableArray *updates;
@property (strong, nonatomic) NSMutableArray *deletions;
// TODO Consider using an NSOperationQueue here so it can be cancelled?
@property (nonatomic) dispatch_queue_t dispatchQueue;

@end

// TODO This is not currently thread safe.
// But probably doesn't need to be.


@implementation ISDBChangeStream

- (id)initWithView:(ISDBView *)view
{
  self = [super init];
  if (self) {
    self.state = ISDBChangeStreamStateIdle;
    self.view = view;
    [self.view addObserver:self];
    self.additions = [NSMutableArray arrayWithCapacity:3];
    self.updates = [NSMutableArray arrayWithCapacity:3];
    self.dispatchQueue
    = dispatch_queue_create("uk.co.inseven.database.changestream",
                            NULL);
    // TODO Clean up the dispatch queue.
  }
  return self;
}


- (void)setDelegate:(id<ISDBChangeStreamDelegate>)delegate
{
  // TODO We are using the setting of the delegate to trigger the initial
  // read of the database. This would seem to be a strange side-effect,
  // though I'm not sure I prefer an explicit API either?
  _delegate = delegate;
  for (NSUInteger i=0; i<self.view.count; i++) {
    [self.view entryForIndex:i
                  completion:^(NSDictionary *entry) {
                    dispatch_async(self.dispatchQueue, ^{
                      ISDBEntry *entry = [ISDBEntry entryWithView:self.view
                                                            index:i];
                      dispatch_async(self.dispatchQueue, ^{
                        [self.delegate changeStream:self
                                              entry:entry
                                          didChange:ISDBOperationUpdate];
                      });

                    });
                  }];
  }
}


#pragma mark - ISDBViewObserver


- (void) beginUpdates:(ISDBView *)view
{
  assert(self.state == ISDBChangeStreamStateIdle);
  self.state = ISDBChangeStreamStateUpdating;
}


- (void)endUpdates:(ISDBView *)view
{
  assert(self.state == ISDBChangeStreamStateUpdating);
  for (NSNumber *index in self.additions) {
    // Insertion.
    ISDBEntry *entry = [ISDBEntry entryWithView:self.view
                                          index:[index integerValue]];
    dispatch_async(self.dispatchQueue, ^{
      [self.delegate changeStream:self
                            entry:entry
                        didChange:ISDBOperationInsert];
    });
  }
  for (NSNumber *index in self.updates) {
    // Update.
    ISDBEntry *entry = [ISDBEntry entryWithView:self.view
                                          index:[index integerValue]];
    dispatch_async(self.dispatchQueue, ^{
      [self.delegate changeStream:self
                            entry:entry
                        didChange:ISDBOperationUpdate];
    });
  }
  for (ISDBEntry *entry in self.deletions) {
    // Deletion.
    dispatch_async(self.dispatchQueue, ^{
      [self.delegate changeStream:self
                            entry:entry
                        didChange:ISDBOperationUpdate];
    });
  }
  
  [self.additions removeAllObjects];
  [self.updates removeAllObjects];
  [self.deletions removeAllObjects];
  self.state = ISDBChangeStreamStateIdle;
}


- (void)view:(ISDBView *)view
entryUpdated:(NSNumber *)index
{
  NSLog(@"entry updated...");
  [self.updates addObject:index];
}


- (void)view:(ISDBView *)view
  entryMoved:(NSArray *)indexes
{
}


- (void)view:(ISDBView *)view
entryInserted:(NSNumber *)index
{
  NSLog(@"entry inserted...");
  [self.additions addObject:index];
}


- (void)view:(ISDBView *)view
entryDeleted:(NSNumber *)index
{
  [self.deletions addObject:[ISDBEntry entryWithView:self.view
                                               index:[index integerValue]]];
}


@end
