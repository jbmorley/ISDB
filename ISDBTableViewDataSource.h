//
//  ISDBTableViewDataSource.h
//  Popcorn
//
//  Created by Jason Barrie Morley on 21/04/2013.
//
//

#import <UIKit/UIKit.h>
#import "ISDBViewDataSource.h"

@interface ISDBTableViewDataSource : NSObject <ISDBViewDataSource>

- (id)initWithTable:(NSString *)table
         identifier:(NSString *)identifier
            orderBy:(NSString *)orderBy;

@end
