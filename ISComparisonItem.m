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
