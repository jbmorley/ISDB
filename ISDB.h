//
//  ISDB.h
//  Popcorn
//
//  Created by Jason Barrie Morley on 11/04/2013.
//
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

@class ISDB;

typedef enum {

  ISDBManagerStateClosed = 0,
  ISDBManagerStateOpen   = 1,
  ISDBManagerStateReady  = 2,
  
} ISDBManagerState;

// TODO Rename everything.

@protocol ISDBManagerDelegate <NSObject>

- (void)databaseCreate:(FMDatabase *)databse;

// TODO Make the udpate optional.
- (void)databaseUpdate:(FMDatabase *)database
            oldVersion:(NSUInteger)oldVersion
            newVersion:(NSUInteger)newVersion;

@optional

- (NSUInteger)databaseVersion:(FMDatabase *)database;
- (NSString *)databaseVersionTable:(FMDatabase *)database;

@end

// TODO Rename this to ISDBManager
                        
@interface ISDB : NSObject

- (void)initWithPath:(NSString *)path
            provider:(id<ISDBManagerDelegate>)provider;
- (BOOL)open;
- (void)close;

@end
