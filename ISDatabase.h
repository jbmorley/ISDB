//
//  ISDatabase.h
//
//  Created by Jason Barrie Morley on 11/04/2013.
//
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "ISDBProvider.h"

@class ISDatabase;

typedef enum {

  ISDBManagerStateClosed = 0,
  ISDBManagerStateOpen   = 1,
  ISDBManagerStateReady  = 2,
  
} ISDatabaseState;
                        
@interface ISDatabase : NSObject

- (id)initWithPath:(NSString *)path
          provider:(id<ISDBProvider>)provider;
- (BOOL)open;
- (void)close;

@end
