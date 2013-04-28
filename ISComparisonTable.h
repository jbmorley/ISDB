//
//  ISComparisonTable.h
//  Difference
//
//  Created by Jason Barrie Morley on 27/04/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

struct ISLocation {
  NSInteger x;
  NSInteger y;
};
typedef struct ISLocation ISLocation;

static inline ISLocation ISLocationMake(NSInteger x, NSInteger y)
{
  ISLocation l; l.x = x; l.y = y; return l;
}

@interface ISComparisonTable : NSObject

- (id)initWithWidth:(NSUInteger)width
             height:(NSUInteger)height
      defaultObject:(id)object;
- (id)objectForLocation:(ISLocation)location;
- (void)setObject:(id)object
      forLocation:(ISLocation)location;

@end
