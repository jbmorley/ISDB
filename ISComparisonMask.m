//
//  ISComparisonMask.m
//  Difference
//
//  Created by Jason Barrie Morley on 27/04/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import "ISComparisonMask.h"

@implementation ISComparisonMask


+ (id)maskWithLocation:(NSUInteger)location
                length:(NSUInteger)length
{
  return [[self alloc] initWithLocation:location
                                 length:length];
}


- (id)initWithLocation:(NSUInteger)location
                length:(NSUInteger)length
{
  self = [super init];
  if (self) {
    self.location = location;
    self.length = length;
  }
  return self;
}


- (NSString *)description
{
  return [NSString stringWithFormat:@"(%ld, %ld)", (unsigned long)self.location, (unsigned long)self.length];
}

@end
