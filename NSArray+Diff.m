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
#import "ISComparisonTable.h"
#import "ISComparisonItem.h"
#import "ISComparisonSequence.h"
#import "ISComparisonMaskedArray.h"


typedef enum {
  ISComparisonScannerStateSearching,
  ISComparisonScannerStateFound,
} ISComparisonScannerState;


@implementation NSArray (Diff)

- (NSArray *)diff:(NSArray *)other
{
  NSArray *commonSequences = [self commonSequences:other];
  
  ISComparisonMaskedArray *maskedSelf = [[ISComparisonMaskedArray alloc] initWithArray:self];
  ISComparisonMaskedArray *maskedOther = [[ISComparisonMaskedArray alloc] initWithArray:other];
  for (ISComparisonSequence *sequence in commonSequences) {
    [maskedSelf addMask:[ISComparisonMask maskWithLocation:sequence.startX
                                                    length:sequence.lenghtX]];
    [maskedOther addMask:[ISComparisonMask maskWithLocation:sequence.startY
                                                     length:sequence.lenghtY]];
  }

  // TODO We can make this a little more efficient.

  // We ignore moves at the moment - these seem somewhat troublesome as it
  // is difficult to know which index we should be moving them to as it is
  // affected by the other items.
  NSMutableArray *changes = [NSMutableArray arrayWithCapacity:3];
  
  // Remove all uncommon elements from masked self, recording the
  // unadjusted index as we do (additions).
  while (maskedSelf.adjustedCount > 0) {
    id object = [maskedSelf objectAtAdjustedIndex:0];
    NSUInteger index = [maskedSelf indexOfObject:object];
    [maskedSelf removeObjectAtIndex:index];
    [changes addObject:[NSArrayOperation operationWithType:NSArrayOperationRemove index:index object:object]];
  }
  
  // Remove all the uncommon elements from masked other, recording the
  // unadjusted index as we do (removals).
  // We reverse the array of additions to adjust for the affects adding
  // items has to the index.
  NSMutableArray *additions = [NSMutableArray arrayWithCapacity:maskedOther.adjustedCount];
  while (maskedOther.adjustedCount > 0) {
    id object = [maskedOther objectAtAdjustedIndex:0];
    NSUInteger index = [maskedOther indexOfObject:object];
    [maskedOther removeObjectAtIndex:index];
    [additions addObject:[NSArrayOperation operationWithType:NSArrayOperationInsert index:index object:object]];
  }
  
  [changes addObjectsFromArray:[[additions reverseObjectEnumerator] allObjects]];
  
  return changes;
}


- (NSArray *)commonSequences:(NSArray *)other
{
  ISComparisonTable *table = [self comparisonTable:other];
  
  NSMutableArray *results = [NSMutableArray arrayWithCapacity:3];
  ISComparisonScannerState state = ISComparisonScannerStateSearching;
  ISComparisonSequence *sequence = nil;
  
  NSInteger x = self.count-1; NSInteger y = other.count-1;
  while (x >= 0 && y >= 0) {
    ISComparisonItem *item = [table objectForLocation:ISLocationMake(x, y)];
    if (item.direction == ISComparisonDirectionXY) {
      
      // Store the details in a sequence.
      if (state == ISComparisonScannerStateSearching) {
        state = ISComparisonScannerStateFound;
        // Create a new sequence.
        sequence = [ISComparisonSequence new];
        [results addObject:sequence];
        sequence.startX = x;
        sequence.startY = y;
        sequence.endX = x;
        sequence.endY = y;
      } else {
        // Update the existing sequence.
        sequence.startX = x;
        sequence.startY = y;
      }
      
      x--; y--;
    } else if (item.direction == ISComparisonDirectionX) {
      state = ISComparisonScannerStateSearching;
      x--;
    } else if (item.direction == ISComparisonDirectionY) {
      state = ISComparisonScannerStateSearching;
      y--;
    }
  }

  return results;
}


// This implementation generates the complete table to avoid deep recursion.
// It is therefore guaranteed to use NM time.
- (ISComparisonTable *)comparisonTable:(NSArray *)other;
{
  ISComparisonTable *table
  = [[ISComparisonTable alloc] initWithWidth:self.count
                                      height:other.count
                               defaultObject:[ISComparisonItem new]];
  
  for (NSUInteger y = 0; y < other.count; y++) {
    for (NSUInteger x = 0; x < self.count; x++) {
      
      ISComparisonItem *item = [ISComparisonItem new];
      
      if ([self[x] isEqual:other[y]]) {
        item.length = ((ISComparisonItem *)[table objectForLocation:ISLocationMake(x-1, y-1)]).length + 1;
        item.direction = ISComparisonDirectionXY;
      } else {
        NSUInteger lengthX = ((ISComparisonItem *)[table objectForLocation:ISLocationMake(x-1, y)]).length;
        NSUInteger lengthY = ((ISComparisonItem *)[table objectForLocation:ISLocationMake(x, y-1)]).length;
        if (lengthX > lengthY) {
          item.length = lengthX;
          item.direction = ISComparisonDirectionX;
        } else {
          item.length = lengthY;
          item.direction = ISComparisonDirectionY;
        }
      }
    
      [table setObject:item
           forLocation:ISLocationMake(x, y)];
    
    }
  }
  
  return table;
}

@end
