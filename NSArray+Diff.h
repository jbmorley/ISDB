//
//  NSArray+Diff.h
//  Popcorn
//
//  Created by Jason Barrie Morley on 23/04/2013.
//
//

#import <Foundation/Foundation.h>

@interface NSArrayDifference : NSObject

@end


@interface NSArray (Diff)

- (NSArrayDifference *)diff:(NSArray *)array;

@end
