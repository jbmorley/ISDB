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
} NSSArrayDiffDirection;

@implementation NSArrayDiff

+ (NSArrayDiff *)diffWithAdditions:(NSArray *)additions
                          removals:(NSArray *)removals
{
  return [[NSArrayDiff alloc] initWithAdditions:additions
                                       removals:removals];
}

- (id)initWithAdditions:(NSArray *)additions
               removals:(NSArray *)removals
{
  self = [super init];
  if (self) {
    _additions = additions;
    _removals = removals;
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
  NSMutableDictionary *dictionary
    = [NSMutableDictionary dictionaryWithCapacity:3];
  [self longestCommonSequenceBetween:self
                              length:self.count
                                 and:array
                              length:array.count
                               cache:dictionary];
  
  NSMutableArray *additions = [NSMutableArray arrayWithCapacity:3];
  NSMutableArray *removals = [NSMutableArray arrayWithCapacity:3];
  
  // Replay the search following the directions stored in the sparse
  // table and recording the results as we go.
  // We allow walks along one array (once we've reached the end of the
  // other array (e.g. index = -1) in order to consume the remainder of
  // the array.
  NSInteger index = self.count-1;
  NSInteger indexOther = array.count-1;
  do {
    if (index < 0) {
      // Consume the remainder of b.
      [additions addObject:[NSNumber numberWithInteger:indexOther]];
      indexOther--;
    } else if (indexOther < 0) {
      // Consume the remainder of a.
      [removals addObject:[NSNumber numberWithInteger:index]];
      index--;
    } else {
      // Along the pre-stored results in the table.
      NSString *identifier
        = [NSString stringWithFormat:@"%d:%d", index, indexOther];
      NSUInteger direction
        = [[dictionary objectForKey:identifier] integerValue];
      if (direction == NSArrayDiffDirectionAB) {
        index--; indexOther--;
      } else if (direction == NSArrayDiffDirectionA) {
        [removals addObject:[NSNumber numberWithInteger:index]];
        index--;
      } else if (direction == NSArrayDiffDirectionB) {
        [additions addObject:[NSNumber numberWithInteger:indexOther]];
        indexOther--;
      }
    }
  } while ((index > -1) || (indexOther > -1));
  
  NSArrayDiff *diff = [NSArrayDiff diffWithAdditions:additions
                                            removals:removals];
  return diff;
}


-(NSUInteger)longestCommonSequenceBetween:(NSArray *)a
                                   length:(NSUInteger)lengthA
                                      and:(NSArray *)b
                                   length:(NSUInteger)lengthB
                                    cache:(NSMutableDictionary *)cache
{
  
  NSUInteger indexA = lengthA - 1;
  NSUInteger indexB = lengthB - 1;
  NSString *identifier
    = [NSString stringWithFormat:@"%d:%d", indexA, indexB];
  
  // TODO Check the cache for a result.
  // TODO We need to store the score in the cache to make it effective.
  
  // There was no previously cached result, so we must calculate one.
  if (lengthA == 0 || lengthB == 0) {
    // Special case incase we find ourselves here.
    // TODO Consider whether this is necessary.
    return 0;
  } else if ([a[indexA] isEqual:b[indexB]]) {
    // If the two items are equal, then we need to determine the next
    // direction. This is done simply by evaluating the directions we
    // can take. Note that we always mark matching entires with
    // kDirectionAB. The actual direction can be inferred.
    if (lengthA == 1 || lengthB == 1) {
      [cache setObject:[NSNumber numberWithInteger:NSArrayDiffDirectionAB]
                forKey:identifier];
      return 1;
    } else {
      [cache setObject:[NSNumber numberWithInteger:NSArrayDiffDirectionAB]
                forKey:identifier];
      return [self longestCommonSequenceBetween:a
                                         length:lengthA-1
                                            and:b
                                         length:lengthB-1
                                          cache:cache];
    }
  } else {
    // Explore the two diagonals.
    NSUInteger longestA = [self longestCommonSequenceBetween:a
                                                      length:lengthA-1
                                                         and:b
                                                      length:lengthB
                                                       cache:cache];
    NSUInteger longestB = [self longestCommonSequenceBetween:a
                                                      length:lengthA
                                                         and:b
                                                      length:lengthB-1
                                                       cache:cache];
    if (longestA > longestB) {
      [cache setObject:[NSNumber numberWithInteger:NSArrayDiffDirectionA]
                forKey:identifier];
      return longestA;
    } else {
      [cache setObject:[NSNumber numberWithInteger:NSArrayDiffDirectionB]
                forKey:identifier];
    }
    
  }
  
  return 0;
  
}

@end
