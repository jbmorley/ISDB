//
//  FMDatabaseQueue+Current.h
//  Popcorn
//
//  Created by Jason Barrie Morley on 04/05/2013.
//
//

#import <Foundation/Foundation.h>
#import "FMDatabaseQueue.h"

@interface FMDatabaseQueue (Reentrant)

- (void)inDatabaseReentrant:(void (^)(FMDatabase *db))block;

@end
