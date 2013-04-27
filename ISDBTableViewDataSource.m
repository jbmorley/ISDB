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
    self.orderBy = orderBy;
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
    [entries addObject:[result objectForColumnName:self.identifier]];
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
  NSMutableString *query = [NSMutableString stringWithCapacity:100];
  [query appendString:@"INSERT INTO "];
  [query appendString:self.table];
  [query appendString:@" ("];
  for (int i=0; i<entry.allKeys.count; i++) {
    if (i > 0) {
      [query appendString:@", "];
    }
    [query appendString:entry.allKeys[i]];
  }
  [query appendString:@") VALUES ("];
  for (int i=0; i<entry.allKeys.count; i++) {
    if (i > 0) {
      [query appendString:@", "];
    }
    [query appendString:@":"];
    [query appendString:entry.allKeys[i]];
  }
  [query appendString:@")"];
  
  if ([database executeUpdate:query
      withParameterDictionary:entry]) {
    return entry[self.identifier];
  } else {
    NSLog(@"%@", [database lastErrorMessage]);
  }
  
  // TODO What about auto-incrementing identifiers.
  
  return nil;
}


- (NSString *)database:(FMDatabase *)database
                update:(NSDictionary *)entry
{
  // Check that the identifier has been specified.
  if ([entry objectForKey:self.identifier] == nil) {
    return nil;
  }
  
  NSMutableString *query = [NSMutableString stringWithCapacity:100];
  [query appendString:@"UPDATE "];
  [query appendString:self.table];
  [query appendString:@" SET "];
  NSUInteger count = 0;
  for (int i=0; i<entry.allKeys.count; i++) {
    if (count > 0) {
      [query appendString:@", "];
    }
    NSString *key = entry.allKeys[i];
    if (![key isEqualToString:self.identifier]) {
      [query appendString:entry.allKeys[i]];
      [query appendString:@" = :"];
      [query appendString:entry.allKeys[i]];
      count++;
    }
  }
  [query appendString:@" WHERE "];
  [query appendString:self.identifier];
  [query appendString:@" = :"];
  [query appendString:self.identifier];
  
  if ([database executeUpdate:query
      withParameterDictionary:entry]) {
    return entry[self.identifier];
  } else {
    NSLog(@"%@", [database lastErrorMessage]);
  }
  return nil;
}


- (NSString *)database:(FMDatabase *)database
                delete:(NSDictionary *)entry
{
  // Check that the identifier has been specified.
  if ([entry objectForKey:self.identifier] == nil) {
    return nil;
  }
  
  NSMutableString *query = [NSMutableString stringWithCapacity:50];
  [query appendString:@"DELETE FROM "];
  [query appendString:self.table];
  [query appendString:@" WHERE "];
  [query appendString:self.identifier];
  [query appendString:@" = :"];
  [query appendString:self.identifier];
  
  if ([database executeUpdate:query
      withParameterDictionary:entry]) {
    return entry[self.identifier];
  } else {
    NSLog(@"%@", [database lastErrorMessage]);
  }
  return nil;
}


@end
