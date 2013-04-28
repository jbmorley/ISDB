//
//  NSArrayChange.m
//  Difference
//
//  Created by Jason Barrie Morley on 28/04/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import "NSArrayOperation.h"

@implementation NSArrayOperation


+ (id)operationWithType:(NSArrayOperationType)type
                  index:(NSUInteger)index
                 object:(id)object
{
  return [[self alloc] initWithType:type
                              index:index
                             object:object];
}


- (id)initWithType:(NSArrayOperationType)type
             index:(NSUInteger)index
            object:(id)object
{
  self = [super init];
  if (self) {
    _type = type;
    _index = index;
    _object = object;
  }
  return self;
}


- (NSString *)description
{
  NSMutableString *description = [NSMutableString stringWithCapacity:3];
  if (self.type == NSArrayOperationRemove) {
    [description appendString:@"- "];
  } else if (self.type == NSArrayOperationInsert) {
    [description appendString:@"+ "];
  }
  [description appendFormat:@"%02ld", (unsigned long)self.index];
  return description;
}


- (BOOL)isEqual:(id)object
{
  if (object == self) {
    return YES;
  } else if ([object class] == [self class]) {
    NSArrayOperation *change = (NSArrayOperation *)object;
    return ((change.type == self.type) && (change.index == self.index));
  }
  return NO;
}


@end
