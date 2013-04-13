//
//  ISDBProvider.h
//
//  Created by Jason Barrie Morley on 13/04/2013.
//
//

#import <Foundation/Foundation.h>

@protocol ISDBProvider <NSObject>
- (BOOL)databaseCreate:(FMDatabase *)database;
- (BOOL)databaseUpdate:(FMDatabase *)database
            oldVersion:(NSUInteger)oldVersion
            newVersion:(NSUInteger)newVersion;
@optional
- (NSUInteger)databaseVersion:(FMDatabase *)database;
- (NSString *)databaseVersionTable:(FMDatabase *)database;
@end
