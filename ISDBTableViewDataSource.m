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


- (NSString *)database:(FMDatabase *)database
                insert:(NSDictionary *)entry
{
  NSString *keys = [entry.allKeys componentsJoinedByString:@", "];
  NSString *values = [NSString stringWithFormat:@":%@", [entry.allKeys componentsJoinedByString:@", :"]];
  NSString *query = [NSString stringWithFormat:
                     @"INSERT INTO %@ (%@) VALUES (%@)",
                     self.table,
                     keys,
                     values];
  if ([database executeUpdate:query
      withParameterDictionary:entry]) {
    return entry[self.identifier];
  }
  return nil;
}


- (NSString *)database:(FMDatabase *)database
                update:(NSDictionary *)entry
{
  // TODO
  NSLog(@"Update: %@", entry);
  return nil;
}


- (NSString *)database:(FMDatabase *)database
                delete:(NSDictionary *)entry
{
  // TODO
  NSLog(@"Delete: %@", entry);
  return nil;
}


@end
