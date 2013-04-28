//
//  NSArrayChange.h
//  Difference
//
//  Created by Jason Barrie Morley on 28/04/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
  NSArrayOperationRemove,
  NSArrayOperationInsert,
} NSArrayOperationType;

@interface NSArrayOperation : NSObject

@property (nonatomic, readonly) NSArrayOperationType type;
@property (nonatomic, readonly) NSUInteger index;
@property (nonatomic, readonly) id object;

+ (id)operationWithType:(NSArrayOperationType)type
                  index:(NSUInteger)index
                 object:(id)object;
- (id)initWithType:(NSArrayOperationType)type
             index:(NSUInteger)index
            object:(id)object;

@end
