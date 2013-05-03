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

@end

// TODO This is not currently thread safe.


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
  }
  return self;
}


#pragma mark - ISDBViewObserver


- (void) viewBeginUpdates:(ISDBView *)view
{
  assert(self.state == ISDBChangeStreamStateIdle);
  self.state = ISDBChangeStreamStateUpdating;
}


- (void)viewEndUpdates:(ISDBView *)view
{
  assert(self.state == ISDBChangeStreamStateUpdating);
  for (NSNumber *index in self.additions) {
    NSLog(@"ADD: %d", [index integerValue]);
  }
  for (NSNumber *index in self.updates) {
    NSLog(@"UPDATE: %d", [index integerValue]);
  }
  
  [self.additions removeAllObjects];
  [self.updates removeAllObjects];
  self.state = ISDBChangeStreamStateIdle;
}


- (void)view:(ISDBView *)view
entryUpdated:(NSNumber *)index
{
  [self.updates addObject:index];
}


- (void)view:(ISDBView *)view
  entryMoved:(NSArray *)indexes
{
}


- (void)view:(ISDBView *)view
entryInserted:(NSNumber *)index
{
  [self.additions addObject:index];
}


- (void)view:(ISDBView *)view
entryDeleted:(NSNumber *)index
{
  // TODO We need to look up removals as we go.
  // [self.deletions addObject:index];
}


@end
