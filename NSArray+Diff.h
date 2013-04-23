//
//  NSArray+Diff.h
//  Popcorn
//
//  Created by Jason Barrie Morley on 23/04/2013.
//
//

#import <Foundation/Foundation.h>

@interface NSArrayDiff : NSObject

@property (strong, nonatomic, readonly) NSArray *additions;
@property (strong, nonatomic, readonly) NSArray *removals;

+ (NSArrayDiff *)diffWithAdditions:(NSArray *)additions
                          removals:(NSArray *)removals;

- (id)initWithAdditions:(NSArray *)additions
               removals:(NSArray *)removals;

@end


@interface NSArray (Diff)

- (NSArrayDiff *)diff:(NSArray *)array;

@end
