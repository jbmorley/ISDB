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

#import "ISNotifier.h"
#import "ISWeakReference.h"

@interface ISNotifier ()
@property (strong, nonatomic) NSMutableArray *observers;
@end

@implementation ISNotifier


// TODO Purge null entries.
// N.B. They will become nil when the references disappear.

- (id) init
{
  self = [super init];
  if (self) {
    self.observers = [NSMutableArray arrayWithCapacity:3];
  }
  return self;
}


- (NSUInteger)count
{
  return self.observers.count;
}


- (void) addObserver:(id)observer
{
  [self.observers addObject:[[ISWeakReference alloc] initWithObject:observer]];
}


- (void) removeObserver:(id)observer
{
  // Clean up any nil references and the current reference.
  NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
  for (NSUInteger i = 0; i < self.observers.count; i++) {
    ISWeakReference *reference = self.observers[i];
    if (reference.object == nil) {
      [indexes addIndex:i];
    } else if (reference.object == observer) {
      [indexes addIndex:i];
    }
  }
  [self.observers removeObjectsAtIndexes:indexes];
}


- (void) notify:(SEL)selector
{
  for (ISWeakReference *reference in self.observers) {
    if ([reference.object respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      [reference.object performSelector:selector];
#pragma clang diagnostic pop
    }
  }
}


- (void) notify:(SEL)selector
     withObject:(id)anObject
{
  for (ISWeakReference *reference in self.observers) {
    if ([reference.object respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      [reference.object performSelector:selector
                             withObject:anObject];
#pragma clang diagnostic pop
    }
  }
}


- (void) notify:(SEL)selector
     withObject:(id)anObject
     withObject:(id)anotherObject
{
  for (ISWeakReference *reference in self.observers) {
    if ([reference.object respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      [reference.object performSelector:selector
                             withObject:anObject
                             withObject:anotherObject];
#pragma clang diagnostic pop
    }
  }
}


@end
