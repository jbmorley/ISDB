//
//  ISComparisonSequence.h
//  Difference
//
//  Created by Jason Barrie Morley on 27/04/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ISComparisonSequence : NSObject

// Inclusive of start and end.

@property (nonatomic) NSUInteger startX;
@property (nonatomic) NSUInteger startY;
@property (nonatomic) NSUInteger endX;
@property (nonatomic) NSUInteger endY;
@property (nonatomic, readonly) NSUInteger lenghtX;
@property (nonatomic, readonly) NSUInteger lenghtY;

@end
