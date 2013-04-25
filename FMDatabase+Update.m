//
//  FMDatabase+Update.m
//  Popcorn
//
//  Created by Jason Barrie Morley on 25/04/2013.
//
//

#import "FMDatabase+Update.h"
#import <objc/runtime.h>

@interface FMDatabaseUpdateCallback : NSObject

@property (weak, nonatomic) id target;
@property (nonatomic) SEL selector;

- (id)initWithTarget:(id)target
            selector:(SEL)selector;

@end


@implementation FMDatabaseUpdateCallback

- (id)initWithTarget:(id)target
            selector:(SEL)selector
{
  self = [super init];
  if (self) {
    self.target = target;
    self.selector = selector;
  }
  return self;
}

@end

static char *const kUpdateCallback = "update_callback";


@implementation FMDatabase (Update)

void onUpdate(void *context,
              int action,
              char const *database,
              char const *table,
              sqlite3_int64 rowId) {
  FMDatabase *self = (__bridge FMDatabase *)context;
  FMDatabaseUpdateCallback *callback
    = objc_getAssociatedObject(self, kUpdateCallback);
  // This callback method is from within a database update.
  // It is therefore necessary to ensure that we do not attempt to perform
  // any further modifications to the database at this point, so we
  // schedule the callback selector on the main thread, rather than
  // attempting to act on it directly.
  [callback.target performSelectorOnMainThread:callback.selector
                                    withObject:nil
                                 waitUntilDone:NO];
}

- (void)update:(id)target
      selector:(SEL)selector
{
  FMDatabaseUpdateCallback *callback
    = [[FMDatabaseUpdateCallback alloc] initWithTarget:target
                                              selector:selector];
  objc_setAssociatedObject(self,
                           kUpdateCallback,
                           callback,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  
  // It is safe to simply bridge cast and not retain here as we can
  // can guarantee that _db will not live beyond the lifetime of self.
  sqlite3_update_hook(_db, &onUpdate, (__bridge void *)(self));
}

@end
