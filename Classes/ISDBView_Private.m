//
//  ISDBView_Private.m
//  Popcorn
//
//  Created by Jason Barrie Morley on 03/05/2013.
//
//

#import "ISDBView_Private.h"

@implementation ISDBView (Private)

- (id)identifierForIndex:(NSUInteger)index
{
  @synchronized (self) {
    ISDBEntryDescription *description = [_entries objectAtIndex:index];
    return description.identifier;
  }
}


- (void)entryForIdentifier:(id)identifier
                completion:(void (^)(NSDictionary *entry))completionBlock
{
  dispatch_queue_t callingQueue = dispatch_get_current_queue();
  dispatch_async(_dispatchQueue, ^{
    NSDictionary *entry = [_dataSource database:_database
                                 entryForIdentifier:identifier];
    dispatch_async(callingQueue, ^{
      completionBlock(entry);
    });
  });
}


@end
