//
// Copyright (c) 2013 InSeven Limited.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

#import "FMDatabase+Update.h"
#import <objc/runtime.h>

@interface FMDatabaseUpdateCallback : NSObject

@property (weak, nonatomic) id target;
@property (nonatomic) SEL selector;
@property (nonatomic) BOOL pending;

- (id)initWithTarget:(id)target
            selector:(SEL)selector;
- (void)fireOnce;

@end


@implementation FMDatabaseUpdateCallback

- (id)initWithTarget:(id)target
            selector:(SEL)selector
{
  self = [super init];
  if (self) {
    self.target = target;
    self.selector = selector;
    self.pending = NO;
  }
  return self;
}

- (void)fireOnce
{
  @synchronized(self) {
    if (!self.pending) {
      self.pending = YES;
      dispatch_async(dispatch_get_main_queue(), ^{
        [self didFire];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.target performSelector:self.selector];
#pragma clang diagnostic pop
      });
    }
  }
}

- (void)didFire
{
  @synchronized(self) {
    self.pending = NO;
  }
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
  [callback fireOnce];
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
