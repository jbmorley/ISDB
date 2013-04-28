//
//  ISComparisonMaskedArray.h
//  Difference
//
//  Created by Jason Barrie Morley on 27/04/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISComparisonMask.h"


@interface ISComparisonMaskedArray : NSObject

@property (nonatomic, readonly) NSUInteger adjustedCount;

- (id)initWithArray:(NSArray *)array;
- (void)addMask:(ISComparisonMask *)mask;
- (id)objectAtAdjustedIndex:(NSUInteger)index;
- (void)removeObjectAtAdjustedIndex:(NSUInteger)index;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (NSUInteger)indexOfObject:(id)object;

@end
