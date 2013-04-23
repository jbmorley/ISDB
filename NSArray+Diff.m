//
//  NSArray+Diff.m
//  Popcorn
//
//  Created by Jason Barrie Morley on 23/04/2013.
//
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
  NSArray *b = array;
  
  NSMutableDictionary *dictionary
    = [NSMutableDictionary dictionaryWithCapacity:3];
  [self longestCommonSequenceBetween:self
                              length:self.count
                                 and:b
                              length:b.count
                               cache:dictionary];
  
  NSMutableArray *additions = [NSMutableArray arrayWithCapacity:3];
  NSMutableArray *removals = [NSMutableArray arrayWithCapacity:3];
  
  // Replay the search following the directions stored in the sparse
  // table and recording the results as we go.
  // We allow walks along one array (once we've reached the end of the
  // other array (e.g. index = -1) in order to consume the remainder of
  // the array.
  NSInteger indexA = self.count-1;
  NSInteger indexB = self.count-1;
  do {
    if (indexA < 0) {
      // Consume the remainder of b.
      [additions addObject:b[indexB]];
      indexB--;
    } else if (indexB < 0) {
      // Consume the remainder of a.
      [removals addObject:self[indexA]];
      indexA--;
    } else {
      // Along the pre-stored results in the table.
      NSString *identifier
      = [NSString stringWithFormat:@"%d:%d", indexA, indexB];
      NSUInteger direction
        = [[dictionary objectForKey:identifier] integerValue];
      if (direction == NSArrayDiffDirectionAB) {
        indexA--; indexB--;
      } else if (direction == NSArrayDiffDirectionA) {
        [removals addObject:self[indexA]];
        indexA--;
      } else if (direction == NSArrayDiffDirectionB) {
        [additions addObject:b[indexB]];
        indexB--;
      }
    }
  } while ((indexA > -1) || (indexB > -1));
  
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
