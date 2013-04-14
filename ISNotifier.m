//
//  ISNotifier.m
//  Learn
//
//  Created by Jason Barrie Morley on 11/01/2013.
//
//

#import "ISNotifier.h"
#import "ISNotifierReference.h"

@interface ISNotifier ()
@property (strong, nonatomic) NSMutableArray *observers;
@end

@implementation ISNotifier


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
  [self.observers addObject:[[ISNotifierReference alloc] initWithObject:observer]];
}


- (void) removeObserver:(id)observer
{
  // Clean up any nil references and the current reference.
  NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
  for (NSUInteger i = 0; i < self.observers.count; i++) {
    ISNotifierReference *reference = self.observers[i];
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
  for (ISNotifierReference *reference in self.observers) {
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
  for (ISNotifierReference *reference in self.observers) {
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
  for (ISNotifierReference *reference in self.observers) {
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
