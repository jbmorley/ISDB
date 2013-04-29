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
    = [NSMutableDictionary dictionaryWithCapacity:3];
  }
  return self;
}


- (id)objectForLocation:(ISLocation)location
{
  id identifier = [self identifierForLocation:location];
  if (location.x >= 0 && location.x < self.width &&
      location.y >= 0 && location.y < self.height) {
    id object = [self.dictionary objectForKey:identifier];
    return object;
  }
  return self.defaultObject;
}


- (void)setObject:(id)object
      forLocation:(ISLocation)location
{
  id identifier = [self identifierForLocation:location];
  [self.dictionary setObject:object
                      forKey:identifier];
}


- (id)identifierForLocation:(ISLocation)location
{
  NSUInteger identifier = location.x;
  identifier <<= 16;
  identifier |= location.y;
  return [NSNumber numberWithInteger:identifier];
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
