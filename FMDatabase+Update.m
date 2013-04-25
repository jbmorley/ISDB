//
//  FMDatabase+Update.m
//  Popcorn
//
//  Created by Jason Barrie Morley on 25/04/2013.
//
//

#import "FMDatabase+Update.h"

@implementation FMDatabase (Update)

void onUpdate(void *context,
              int action,
              char const *database,
              char const *table,
              sqlite3_int64 rowId) {
  NSLog(@"sqlite3_update_hook");
}

- (void)updateHook
{
  sqlite3_update_hook(_db, &onUpdate, NULL);
}

@end
