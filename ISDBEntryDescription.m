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

#import "ISDBEntryDescription.h"

@interface ISDBEntryDescription ()

@end


@implementation ISDBEntryDescription


+ (id)descriptionWithIdentifier:(id)identifier
                  summary:(id)summary
{
  return [[self alloc] initWithIdentifier:identifier
                                  summary:summary];
}


- (id)initWithIdentifier:(id)identifier
                 summary:(id)summary
{
  self = [super init];
  if (self) {
    _identifier = identifier;
    _summary = summary;
  }
  return self;
}


- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  } else if ([self class] == [object class]) {
    ISDBEntryDescription *identifier = (ISDBEntryDescription *)object;
    return [self.identifier isEqual:identifier.identifier];
  }
  return NO;
}


- (BOOL)isSummaryEqual:(ISDBEntryDescription *)object
{
  return [self.summary isEqual:object.summary];
}


@end