//
//  ISDBCondition.m
//  Learn
//
//  Created by Jason Barrie Morley on 18/01/2013.
//
//

#import "ISDBCondition.h"

@implementation ISDBCondition


+ (ISDBCondition *) condition:(NSString *)key
                      equalTo:(id)value
{
  return [[self alloc] initWithType:ISDBConditionTypeEqual
                                key:key
                              value:value];
}


+ (ISDBCondition *) condition:(NSString *)key
                     lessThan:(id)value
{
  return [[self alloc] initWithType:ISDBConditionTypeLessThan
                                key:key
                              value:value];
}


+ (ISDBCondition *) condition:(NSString *)key
                  greaterThan:(id)value
{
  return [[self alloc] initWithType:ISDBConditionTypeGreaterThan
                                key:key
                              value:value];
}


- (id) initWithType:(ISDBConditionType)type
                key:(NSString *)key
              value:(id)value
{
  self = [super init];
  if (self) {
    self.type = type;
    self.key = key;
    self.value = value;
  }
  return self;
}


- (NSString *) string
{
  NSMutableString *string = [NSMutableString stringWithString:self.key];
  if (self.type == ISDBConditionTypeEqual) {
    [string appendString:@" = ?"];
  } else if (self.type == ISDBConditionTypeLessThan) {
    [string appendString:@" < ?"];
  } else if (self.type == ISDBConditionTypeGreaterThan) {
    [string appendString:@" > ?"];
  }
  return string;
}


@end
