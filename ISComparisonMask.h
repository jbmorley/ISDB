//
//  ISComparisonMask.h
//  Difference
//
//  Created by Jason Barrie Morley on 27/04/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ISComparisonMask : NSObject

@property (nonatomic) NSUInteger location;
@property (nonatomic) NSUInteger length;

+ (id)maskWithLocation:(NSUInteger)location
                length:(NSUInteger)length;
- (id)initWithLocation:(NSUInteger)location
                length:(NSUInteger)length;

@end
