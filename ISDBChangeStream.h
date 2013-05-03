//
//  ISDBChangeStream.h
//  Popcorn
//
//  Created by Jason Barrie Morley on 03/05/2013.
//
//

#import <Foundation/Foundation.h>
#import "ISDBView.h"

@interface ISDBChangeStream : NSObject <ISDBViewObserver>

- (id)initWithView:(ISDBView *)view;

@end
