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

#import "NSArray+Diff.h"

typedef enum {
  NSArrayDiffDirectionA,
  NSArrayDiffDirectionB,
  NSArrayDiffDirectionAB,
} NSArrayDiffDirection;

@implementation NSArrayDiff

+ (id)diffWithAdditions:(NSArray *)additions
               removals:(NSArray *)removals
                  moves:(NSArray *)moves
{
  return [[self alloc] initWithAdditions:additions
                                removals:removals
                                   moves:moves];
}

- (id)initWithAdditions:(NSArray *)additions
               removals:(NSArray *)removals
                  moves:(NSArray *)moves
{
  self = [super init];
  if (self) {
    _additions = additions;
    _removals = removals;
    _moves = moves;
  }
  return self;
}


- (NSString *)description
{
  return [NSString stringWithFormat:
          @"Additions: [%@], Removals: [%@]",
          [self.additions componentsJoinedByString:@", "],
          [self.removals componentsJoinedByString:@", "]];
}


@end


@implementation NSArray (Diff)


- (NSArrayDiff *)diff:(NSArray *)array
{
  NSMutableArray *additions = [NSMutableArray arrayWithCapacity:3];
  NSMutableArray *removals = [NSMutableArray arrayWithCapacity:3];
  NSMutableArray *moves = [NSMutableArray arrayWithCapacity:3];
  
  // Removals and moves.
  NSMutableIndexSet *found = [[NSMutableIndexSet alloc] init];
  for (NSUInteger i = 0; i < self.count; i++) {
    NSUInteger j = [array indexOfObject:self[i]];
    if (j == NSNotFound) {
      [removals addObject:[NSNumber numberWithInteger:i]];
    } else if (j != i) {
      [moves addObject:@[[NSNumber numberWithInteger:i], [NSNumber numberWithInteger:j]]];
      [found addIndex:i];
    } else {
      [found addIndex:i];
    }
  }
  
  // Additions.
  NSMutableArray *other = [NSMutableArray arrayWithArray:array];
  [other removeObjectsAtIndexes:found];
  for (id object in other) {
    NSUInteger i = [array indexOfObject:object];
    [additions addObject:[NSNumber numberWithInteger:i]];
  }
  
  return [NSArrayDiff diffWithAdditions:additions
                               removals:removals
                                  moves:moves];
}


@end
