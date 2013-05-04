//
//  FMDatabaseQueue+Current.m
//  Popcorn
//
//  Created by Jason Barrie Morley on 04/05/2013.
//
//

#import "FMDatabaseQueue+Current.h"

@implementation FMDatabaseQueue (Reentrant)

- (void)inDatabaseReentrant:(void (^)(FMDatabase *db))block
{
  if (dispatch_get_current_queue() == _queue) {
    block(_db);
  } else {
    [self inDatabase:block];
  }
}

@end
