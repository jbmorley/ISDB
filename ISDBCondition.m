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
