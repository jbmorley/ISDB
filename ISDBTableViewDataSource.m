//
//  ISDBTableViewDataSource.m
//  Popcorn
//
//  Created by Jason Barrie Morley on 21/04/2013.
//
//

#import "ISDBTableViewDataSource.h"

@interface ISDBTableViewDataSource ()

@property (strong, nonatomic) NSString *table;
@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSString *orderBy;
@property (strong, nonatomic) NSString *select;
@property (strong, nonatomic) NSString *selectByIdentifier;

@end

@implementation ISDBTableViewDataSource


- (id)initWithTable:(NSString *)table
         identifier:(NSString *)identifier
            orderBy:(NSString *)orderBy
{
  self = [super init];
  if (self) {
    self.table = table;
    self.identifier = identifier;
    self.select = [NSString stringWithFormat:
                   @"SELECT * FROM %@ ORDER BY %@",
                   self.table,
                   self.orderBy];
    self.selectByIdentifier = [NSString stringWithFormat:
                               @"SELECT * FROM %@ WHERE %@ = ?",
                               self.table,
                               self.identifier];
  }
  return self;
}


#pragma mark - ISDBViewDataSource


- (NSArray *)database:(FMDatabase *)database
     entriesForOffset:(NSUInteger)offset
                limit:(NSInteger)limit
{
  assert((offset == 0) && (limit == -1));
  NSMutableArray *entries = [NSMutableArray arrayWithCapacity:3];
  FMResultSet *result = [database executeQuery:self.select];
  while ([result next]) {
    [entries addObject:[result resultDict]];
  }
  return entries;
}


- (NSDictionary *)database:(FMDatabase *)database
        entryForIdentifier:(NSString *)identifier
{
  FMResultSet *result = [database executeQuery:self.selectByIdentifier
                          withArgumentsInArray:@[identifier]];
  if ([result next]) {
    return [result resultDict];
  }
  return nil;
}


@end
