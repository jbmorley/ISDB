//
//  ISNotifier.h
//  Learn
//
//  Created by Jason Barrie Morley on 11/01/2013.
//
//

#import <Foundation/Foundation.h>

@interface ISNotifier : NSObject

- (void) addObserver:(id)observer;
- (void) removeObserver:(id)observer;

- (void) notify:(SEL)selector;
- (void) notify:(SEL)selector
     withObject:(id)anObject;
- (void) notify:(SEL)selector
     withObject:(id)anObject
     withObject:(id)anotherObject;

@end
