//
//  ISNotifierReference.m
//  Learn
//
//  Created by Jason Barrie Morley on 19/02/2013.
//
//

#import "ISNotifierReference.h"

@implementation ISNotifierReference

- (id) initWithObject:(NSObject *)object
{
  self = [super init];
  if (self) {
    self.object = object;
  }
  return self;
}

@end
