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

#import "ISDBQueryDataSource.h"

@interface ISDBQueryDataSource ()

@property (strong, nonatomic) NSString *entriesQuery;
@property (strong, nonatomic) NSString *entryQuery;
@property (strong, nonatomic) NSString *identifier;

@end

@implementation ISDBQueryDataSource


- (id)initWithEntriesQuery:(NSString *)entriesQuery
                entryQuery:(NSString *)entryQuery
                identifier:(NSString *)identifier
{
  self = [super init];
  if (self) {
    self.entriesQuery = entriesQuery;
    self.entryQuery = entryQuery;
    self.identifier = identifier;
  }
  return self;
}


- (NSArray *)database:(FMDatabase *)database
     entriesForOffset:(NSUInteger)offset
                limit:(NSInteger)limit
{
  assert((offset == 0) && (limit == -1));
  NSMutableArray *entries = [NSMutableArray arrayWithCapacity:3];
  FMResultSet *result = [database executeQuery:self.entriesQuery];
  while ([result next]) {
    [entries addObject:[result objectForColumnName:self.identifier]];
  }
  return entries;
}


- (NSDictionary *)database:(FMDatabase *)database
        entryForIdentifier:(id)identifier
{
  FMResultSet *result = [database executeQuery:self.entryQuery
                          withArgumentsInArray:@[identifier]];
  if ([result next]) {
    return [result resultDict];
  }
  return nil;
}


@end
