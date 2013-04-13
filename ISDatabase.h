//
//  ISDatabase.h
//
//  Created by Jason Barrie Morley on 11/04/2013.
//
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "ISDBProvider.h"
#import "ISDBView.h"

@class ISDatabase;

typedef enum {

  ISDatabaseStateClosed = 0,
  ISDatabaseStateOpen   = 1,
  ISDatabaseStateReady  = 2,
  
} ISDatabaseState;
                        
@interface ISDatabase : NSObject

// TODO Consider passing the provider into the open call to work
// around the slightly weird ownership model of the provider.

- (id)initWithPath:(NSString *)path
          provider:(id<ISDBProvider>)provider;
- (BOOL)open;
- (void)close;

- (ISDBView *)table:(NSString *)table
         identifier:(NSString *)identifier
            orderBy:(NSString *)orderBy
             fields:(NSArray *)fields
         conditions:(NSArray *)conditions;

@end
