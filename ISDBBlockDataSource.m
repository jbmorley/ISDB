//
//  ISBlockViewDataSource.m
//  Popcorn
//
//  Created by Jason Barrie Morley on 27/04/2013.
//
//

#import "ISDBBlockDataSource.h"

@interface ISDBBlockDataSource ()

@property (strong, nonatomic) ISDBEntriesBlock entriesBlock;
@property (strong, nonatomic) ISDBEntryBlock entryBlock;

@end

@implementation ISDBBlockDataSource

+ (id)dataSourceWithEntriesBlock:(ISDBEntriesBlock)entriesBlock
                      entryBlock:(ISDBEntryBlock)entryBlock
{
  return [[self alloc] initWithEntriesBlock:entriesBlock
                                 entryBlock:entryBlock];
}

- (id)initWithEntriesBlock:(ISDBEntriesBlock)entriesBlock
                entryBlock:(ISDBEntryBlock)entryBlock
{
  self = [super init];
  if (self) {
    self.entriesBlock = entriesBlock;
    self.entryBlock = entryBlock;
  }
  return self;
}

#pragma mark - ISDBViewDataSource


- (NSArray *)database:(FMDatabase *)database
     entriesForOffset:(NSUInteger)offset
                limit:(NSInteger)limit
{
  assert(offset == 0 && limit == -1);
  return self.entriesBlock(database);
}


- (NSDictionary *)database:(FMDatabase *)database
        entryForIdentifier:(NSString *)identifier
{
  return self.entryBlock(database, identifier);
}

@end
