//
//  ISDBEntry.m
//  Popcorn
//
//  Created by Jason Barrie Morley on 03/05/2013.
//
//

#import "ISDBEntry.h"
#import "ISDBView_Private.h"

@interface ISDBEntry ()

@property (strong, nonatomic) ISDBView *view;
@property (nonatomic) NSUInteger index;
@property (strong, nonatomic) id identifier;

@end

@implementation ISDBEntry


+ (id)entryWithView:(ISDBView *)view
              index:(NSUInteger)index
{
  return [[self alloc] initWithView:view
                              index:index];
}


- (id)initWithView:(ISDBView *)view
             index:(NSUInteger)index
{
  self = [super init];
  if (self) {
    self.view = view;
    self.index = index;
    self.identifier = [self.view identifierForIndex:self.index];
    [self.view addObserver:self];
  }
  return self;
}


- (void)dealloc
{
  [self.view removeObserver:self];
}


- (void)fetch:(void (^)(NSDictionary *dict))completionBlock
{
  [self.view entryForIdentifier:self.identifier
                     completion:completionBlock];
}


- (void)update:(NSDictionary *)entry
    completion:(void (^)(BOOL success))completionBlock
{
  [self.view update:entry
         completion:^(NSDictionary *entry) {
           if (completionBlock != NULL) {
             completionBlock(entry != nil);
           }
        }];
}


#pragma mark - ISDBViewObserver


- (void) beginUpdates:(ISDBView *)view {}


- (void) endUpdates:(ISDBView *)view {}


- (void) view:(ISDBView *)view
 entryUpdated:(NSNumber *)index
{
  if (self.index == [index integerValue]) {
    self.index = [index integerValue];
    NSLog(@"Entry Changed");
  }
}


- (void) view:(ISDBView *)view
   entryMoved:(NSArray *)indexes {}


- (void) view:(ISDBView *)view
entryInserted:(NSNumber *)index {}


- (void) view:(ISDBView *)view
 entryDeleted:(NSNumber *)index
{
  if (self.index == [index integerValue]) {
    NSLog(@"Entry Deleted");
  }
}


@end
