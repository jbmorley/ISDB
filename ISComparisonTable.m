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
