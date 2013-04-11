//
//  ISNotifierReference.h
//  Learn
//
//  Created by Jason Barrie Morley on 19/02/2013.
//
//

#import <Foundation/Foundation.h>

@interface ISNotifierReference : NSObject

@property (weak, nonatomic) NSObject *object;

- (id) initWithObject:(NSObject *)object;

@end
