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

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "ISDBDataSource.h"
#import "ISDBViewObserver.h"

@class ISDBEntry;

typedef void(^ISDBTask)();

extern NSInteger ISDBViewIndexUndefined;


typedef enum {
  ISDBOperationInsert,
  ISDBOperationDelete,
  ISDBOperationUpdate,
  ISDBOperationMove
} ISDBOperation;


@interface ISDBView : NSObject {
  
  NSMutableArray *_entries;
  
}

@property (nonatomic, readonly) NSUInteger count;

- (id) initWithDispatchQueue:(dispatch_queue_t)queue
                    database:(FMDatabase *)database
                  dataSource:(id<ISDBDataSource>)dataSource;

- (void)invalidate:(BOOL)reload;

- (ISDBEntry *)entryForIndex:(NSInteger)index;
- (void)entryForIdentifier:(id)identifier
                completion:(void (^)(NSDictionary *entry))completionBlock;

// TODO Do these need to return anything?
// It might be cleaner if they didn't, though it's possible we'd loose
// the details of the entry as it's not necessarily bound to a view at this
// point in time.
- (void)insert:(NSDictionary *)entry
    completion:(void (^)(id identifier))completionBlock;
- (void)update:(NSDictionary *)entry
    completion:(void (^)(id identifier))completionBlock;
- (void)delete:(NSDictionary *)entry
    completion:(void (^)(id identifier))completionBlock;

- (void) addObserver:(id<ISDBViewObserver>)observer;
- (void) removeObserver:(id<ISDBViewObserver>)observer;

@end
