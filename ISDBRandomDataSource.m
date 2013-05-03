//
//  ISRandomDataSource.m
//  Popcorn
//
//  Created by Jason Barrie Morley on 01/05/2013.
//
//

#import "ISDBRandomDataSource.h"


@interface ISDBRandomDataSource ()

@property (strong, nonatomic) NSArray *candidates;
@property (strong, nonatomic) ISDBViewReloader *reloader;
@property (strong, nonatomic) NSMutableArray *entries;
@property (strong, nonatomic) NSTimer *timer;

@end


@implementation ISDBRandomDataSource


- (id)init
{
  self = [super init];
  if (self) {
    self.candidates = @[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K"];
  }
  return self;
}


- (void)initialize:(ISDBViewReloader *)reloader
{
  self.reloader = reloader;
  self.timer = [NSTimer scheduledTimerWithTimeInterval:2
                                                target:self
                                              selector:@selector(reload)
                                              userInfo:nil
                                               repeats:YES];
}


- (NSArray *)database:(FMDatabase *)database
     entriesForOffset:(NSUInteger)offset
                limit:(NSInteger)limit
{
  // Generate an array of random length with random content.
  
  // Create a new array containing the candidates so we can remove one
  // each time we select it to avoid duplicate entries.
  NSMutableArray *candidates
  = [NSMutableArray arrayWithArray:self.candidates];
  
  // Determine the length of the new version.
  NSUInteger length = 8 + (arc4random() % 3);
  self.entries = [NSMutableArray arrayWithCapacity:length];
  
  for (NSUInteger i = 0; i < length; i++) {
    NSUInteger index = arc4random() % candidates.count;
    NSString *identifier = candidates[index];
    NSString *summary = ((arc4random() % 2) == 0) ? @"A" : @"B";
    [self.entries addObject:[ISDBEntryDescription descriptionWithIdentifier:identifier
                                                   summary:summary]];
    [candidates removeObjectAtIndex:index];
  }
  
  return self.entries;
}


- (NSDictionary *)database:(FMDatabase *)database
        entryForIdentifier:(id)identifier
{
  ISDBEntryDescription *keyEntry = [ISDBEntryDescription descriptionWithIdentifier:identifier
                                               summary:nil];
  NSUInteger index = [self.entries indexOfObject:keyEntry];
  ISDBEntryDescription *entry = [self.entries objectAtIndex:index];
  NSString *details = [NSString stringWithFormat:@"%@: %@", entry.identifier, entry.summary];
  
  return @{@"show": details};
}


- (void)reload
{
  [self.reloader reload];
}


@end
