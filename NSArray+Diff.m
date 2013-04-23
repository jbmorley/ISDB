//
//  NSArray+Diff.m
//  Popcorn
//
//  Created by Jason Barrie Morley on 23/04/2013.
//
//

#import "NSArray+Diff.h"

@implementation NSArrayDifference

@end

@implementation NSArray (Diff)

// TODO Make this an enum
static NSUInteger const kDirectionA = 0;
static NSUInteger const kDirectionB = 1;
static NSUInteger const kDirectionAB = 2;


- (NSArrayDifference *)diff:(NSArray *)array
{
  NSArray *a = self;
  NSArray *b = array;
  
  NSMutableDictionary *dictionary
  = [NSMutableDictionary dictionaryWithCapacity:3];
  [self longestCommonSequenceBetween:a
                              length:a.count
                                 and:b
                              length:b.count
                               cache:dictionary];
  
  NSMutableArray *additionsA = [NSMutableArray arrayWithCapacity:3];
  NSMutableArray *additionsB = [NSMutableArray arrayWithCapacity:3];
  
  // Replay the search following the directions stored in the sparse
  // table and recording the results as we go.
  // We allow walks along one array (once we've reached the end of the
  // other array (e.g. index = -1) in order to consume the remainder of
  // the array.
  NSInteger indexA = a.count-1;
  NSInteger indexB = b.count-1;
  do {
    if (indexA < 0) {
      // Consume the remainder of b.
      NSLog(@"B: %@", b[indexB]);
      indexB--;
    } else if (indexB < 0) {
      // Consume the remainder of a.
      NSLog(@"A: %@", a[indexA]);
      indexA--;
    } else {
      // Along the pre-stored results in the table.
      NSString *identifier
      = [NSString stringWithFormat:@"%d:%d", indexA, indexB];
      NSLog(@"Reading: %@", identifier);
      NSUInteger direction
      = [[dictionary objectForKey:identifier] integerValue];
      if (direction == kDirectionAB) {
        NSLog(@"Common: %@", a[indexA]);
        indexA--;
        indexB--;
      } else if (direction == kDirectionA) {
        NSLog(@"A: %@", a[indexA]);
        indexA--;
      } else if (direction == kDirectionB) {
        NSLog(@"B: %@", b[indexB]);
        indexB--;
      }
      
    }
  } while ((indexA > -1) || (indexB > -1));
  
  
  NSLog(@"Cache: %@", dictionary);
  
  NSArrayDifference *diff = [[NSArrayDifference alloc] init];
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
      [cache setObject:[NSNumber numberWithInteger:kDirectionAB]
                forKey:identifier];
      return 1;
    } else {
      [cache setObject:[NSNumber numberWithInteger:kDirectionAB]
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
      [cache setObject:[NSNumber numberWithInteger:kDirectionA]
                forKey:identifier];
      return longestA;
    } else {
      [cache setObject:[NSNumber numberWithInteger:kDirectionB]
                forKey:identifier];
    }
    
  }
  
  return 0;
  
}

@end
