//
//  ISComparisonItem.h
//  Difference
//
//  Created by Jason Barrie Morley on 27/04/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
  ISComparisonDirectionX,
  ISComparisonDirectionY,
  ISComparisonDirectionXY,
  ISComparisonDirectionInvalid,
} ISComparisonDirection;

@interface ISComparisonItem : NSObject

@property (nonatomic) ISComparisonDirection direction;
@property (nonatomic) NSUInteger length;

@end
