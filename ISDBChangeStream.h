//
//  ISDBChangeStream.h
//  Popcorn
//
//  Created by Jason Barrie Morley on 03/05/2013.
//
//

#import <Foundation/Foundation.h>
#import "ISDBView.h"
#import "ISDBEntry.h"

@class ISDBChangeStream;

@protocol ISDBChangeStreamDelegate <NSObject>

- (void)changeStream:(id)changeStream
               entry:(ISDBEntry *)entry
           didChange:(ISDBOperation)operation;

@end

@interface ISDBChangeStream : NSObject <ISDBViewObserver>

@property (weak, nonatomic) id<ISDBChangeStreamDelegate> delegate;

- (id)initWithView:(ISDBView *)view;

@end
