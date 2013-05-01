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
