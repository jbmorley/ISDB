//
//  ISWeakReferenceArray.h
//  Popcorn
//
//  Created by Jason Barrie Morley on 24/04/2013.
//
//

#import <Foundation/Foundation.h>

@interface ISWeakReferenceArray : NSObject <NSFastEnumeration>

@property (nonatomic, readonly) NSUInteger count;

+ (id)arrayWithCapacity:(NSUInteger)numItems;
- (id)initWithCapacity:(NSUInteger)numItems;

- (void)addObject:(id)anObject;
- (void)removeObject:(id)anObject;

@end
