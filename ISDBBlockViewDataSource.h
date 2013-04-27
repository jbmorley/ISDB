//
//  ISBlockViewDataSource.h
//  Popcorn
//
//  Created by Jason Barrie Morley on 27/04/2013.
//
//

#import <Foundation/Foundation.h>
#import "ISDBDataSource.h"

typedef NSArray *(^ISDBEntriesBlock)(FMDatabase *database);
typedef NSDictionary *(^ISDBEntryBlock)(FMDatabase *database, id identifier);

// TODO Rename this.
@interface ISDBBlockViewDataSource : NSObject <ISDBDataSource>

+ (id)dataSourceWithEntriesBlock:(ISDBEntriesBlock)entriesBlock
                      entryBlock:(ISDBEntryBlock)entryBlock;
- (id)initWithEntriesBlock:(ISDBEntriesBlock)entriesBlock
                entryBlock:(ISDBEntryBlock)entryBlock;

@end
