//
//  ISComparisonSequence.m
//  Difference
//
//  Created by Jason Barrie Morley on 27/04/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import "ISComparisonSequence.h"

@implementation ISComparisonSequence


- (NSUInteger)lenghtX
{
  return self.endX - self.startX + 1;
}


- (NSUInteger)lenghtY
{
  return self.endY - self.startY + 1;
}


- (NSString *)description
{
  NSMutableString *description = [NSMutableString stringWithCapacity:3];
  [description appendFormat:@"[%ld-%ld] => [%ld-%ld]", (unsigned long)self.startX, (unsigned long)self.endX, (unsigned long)self.startY, (unsigned long)self.endY];
  return description;
}

@end
