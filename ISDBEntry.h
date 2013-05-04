//
//  ISDBEntry.h
//  Popcorn
//
//  Created by Jason Barrie Morley on 03/05/2013.
//
//

#import <Foundation/Foundation.h>
#import "ISDBView.h"
#import "ISDBViewObserver.h"

@interface ISDBEntry : NSObject <ISDBViewObserver>

+ (id)entryWithView:(ISDBView *)view
              index:(NSUInteger)index;
- (id)initWithView:(ISDBView *)view
             index:(NSUInteger)index;
- (void)fetch:(void (^)(NSDictionary *dict))completionBlock;
- (void)update:(NSDictionary *)entry
    completion:(void (^)(BOOL success))completionBlock;

@end
