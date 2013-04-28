//
//  ISComparisonItem.m
//  Difference
//
//  Created by Jason Barrie Morley on 27/04/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import "ISComparisonItem.h"

@implementation ISComparisonItem

- (id)init
{
  self = [super init];
  if (self) {
    self.direction = ISComparisonDirectionInvalid;
    self.length = 0;
  }
  return self;
}


- (NSString *)description
{
  NSMutableString *description = [NSMutableString stringWithCapacity:3];
  if (self.direction == ISComparisonDirectionInvalid) {
    [description appendString:@"o"];
  } else if (self.direction == ISComparisonDirectionX) {
    [description appendString:@"-"];
  } else if (self.direction == ISComparisonDirectionY) {
    [description appendString:@"|"];
  } else if (self.direction == ISComparisonDirectionXY) {
    [description appendString:@"\\"];
  }
  [description appendFormat:@"%02ld", (unsigned long)self.length];
  return description;
}

@end
