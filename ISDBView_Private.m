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

@end
