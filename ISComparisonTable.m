//
//  ISComparisonTable.m
//  Difference
//
//  Created by Jason Barrie Morley on 27/04/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import "ISComparisonTable.h"

@interface ISComparisonTable ()

@property (nonatomic) NSUInteger width;
@property (nonatomic) NSUInteger height;
@property (strong, nonatomic) id defaultObject;
@property (strong, nonatomic) NSMutableDictionary *dictionary;

@end

@implementation ISComparisonTable


- (id)initWithWidth:(NSUInteger)width
             height:(NSUInteger)height
      defaultObject:(id)defaultObject
{
  self = [super init];
  if (self) {
    self.width = width;
    self.height = height;
    self.defaultObject = defaultObject;
    self.dictionary
    = [NSMutableDictionary dictionaryWithCapacity:width * height];
  }
  return self;
}


- (id)objectForLocation:(ISLocation)location
{
  NSString *identifier = [NSString stringWithFormat:@"%ld:%ld", (long)location.x, (long)location.y];
  id object = [self.dictionary objectForKey:identifier];
  if (object) {
    return object;
  } else {
    return self.defaultObject;
  }
}


- (void)setObject:(id)object
      forLocation:(ISLocation)location
{
  NSString *identifier = [NSString stringWithFormat:@"%ld:%ld", (long)location.x, (long)location.y];
  [self.dictionary setObject:object
                      forKey:identifier];
}


- (NSString *)description
{
  NSMutableString *description = [NSMutableString stringWithCapacity:100];
  for (NSInteger y = 0; y < self.height; y++) {
    for (NSInteger x = 0; x < self.width; x++) {
      [description appendFormat:@"[%@] ", [self objectForLocation:ISLocationMake(x, y)]];
    }
    [description appendString:@"\n"];
  }
  return description;
}

@end
