//
//  ISComparisonMaskedArray.m
//  Difference
//
//  Created by Jason Barrie Morley on 27/04/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import "ISComparisonMaskedArray.h"

@interface ISComparisonMaskedArray ()

@property (strong, nonatomic) NSMutableArray *array;
@property (strong, nonatomic) NSMutableArray *masks;
@property (nonatomic) BOOL sorted;

@end

@implementation ISComparisonMaskedArray


- (id)initWithArray:(NSArray *)array
{
  self = [super init];
  if (self) {
    self.array = [NSMutableArray arrayWithArray:array];
    self.masks = [NSMutableArray arrayWithCapacity:3];
    self.sorted = YES;
  }
  return self;
}


- (void)addMask:(ISComparisonMask *)mask
{
  [self.masks addObject:mask];
  self.sorted = NO;
}


- (NSUInteger)adjustedCount
{
  NSUInteger maskLength = 0;
  for (ISComparisonMask *mask in self.masks) {
    maskLength += mask.length;
  }
  return self.array.count - maskLength;
}



- (id)objectAtAdjustedIndex:(NSUInteger)index
{
  NSUInteger actual = [self adjustedIndex:index];
  return [self.array objectAtIndex:actual];
}


- (void)removeObjectAtAdjustedIndex:(NSUInteger)index
{
  NSUInteger actual = [self adjustedIndex:index];
  [self removeObjectAtIndex:actual];
}


- (void)removeObjectAtIndex:(NSUInteger)index
{
  [self sort];
  [self.array removeObjectAtIndex:index];
  
  // Correct the masks.
  for (ISComparisonMask *mask in self.masks) {
    if (mask.location > index) {
      mask.location = mask.location - 1;
    }
  }
}


// Unadjusted.
- (NSUInteger)indexOfObject:(id)object
{
  [self sort];
  // This implementation relies on objects being unique.
  // We search in all the gaps.  This is intended to be an optimization
  // as it is anticipated that in most scenarios very few items will have
  // changed, meaning our search window is small.
  NSUInteger start = 0;
  for (ISComparisonMask *mask in self.masks) {
    NSUInteger index
    = [self.array indexOfObject:object
                        inRange:NSMakeRange(start, mask.location - start)];
    if (index != NSNotFound) {
      return index;
    } else {
      start = (mask.location + mask.length);
    }
  }

  if (start < self.array.count) {
    NSUInteger index
    = [self.array indexOfObject:object
                        inRange:NSMakeRange(start, self.array.count - start)];
    if (index != NSNotFound) {
      return index;
    } else {
      return NSNotFound;
    }
  }
  
  return NSNotFound;
  
}


- (NSUInteger)adjustedIndex:(NSUInteger)index
{
  // Ensure the masks are in the correct order.
  [self sort];
  
  // Calculate the correct index.
  NSUInteger actual = index;
  for (ISComparisonMask *mask in self.masks) {
    if (mask.location <= actual) {
      actual += mask.length;
    } else {
      break;;
    }
  }
  return actual;
  
}


- (void)sort
{
  if (!self.sorted) {
    [self.masks sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
      ISComparisonMask *mask1 = (ISComparisonMask *)obj1;
      ISComparisonMask *mask2 = (ISComparisonMask *)obj2;
      if (mask1.location < mask2.location) {
        return NSOrderedAscending;
      } else if (mask1.location > mask2.location) {
        return NSOrderedDescending;
      } else {
        return NSOrderedSame;
      }
    }];
    self.sorted = YES;
  }
}


@end
