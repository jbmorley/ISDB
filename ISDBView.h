//
//  ISDBView.h
//  Learn
//
//  Created by Jason Barrie Morley on 11/01/2013.
//
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "ISDBCondition.h"

extern NSInteger ISDBViewIndexUndefined;

@class ISDBView;

@protocol ISDBViewObserver <NSObject>
@optional

- (void) view:(ISDBView *)view
 entryUpdated:(NSNumber *)index;
- (void) view:(ISDBView *)view
   entryMoved:(NSArray *)indexes;
- (void) view:(ISDBView *)view
entryInserted:(NSNumber *)index;
- (void) view:(ISDBView *)view
 entryDeleted:(NSNumber *)index;

@end

@interface ISDBView : NSObject

@property (nonatomic) BOOL autoIncrementIdentifier;
@property (nonatomic, readonly) NSUInteger count;

- (id) initWithDatabase:(FMDatabase *)database
                  table:(NSString *)table
             identifier:(NSString *)identifier
                orderBy:(NSString *)orderBy
                 fields:(NSArray *)fields
             conditions:(NSArray *)conditions;

- (void) setClass:(Class)cls
         forField:(NSString *)field;

- (NSInteger) indexForIdentifier:(id)identifier;

- (NSDictionary *) entryForIndex:(NSInteger)index;
- (NSDictionary *) entryForIdentifier:(id)identifier;

- (NSDictionary *) insert:(NSDictionary *)entry;
- (void) insert:(NSDictionary *)entry
     completion:(void (^)(NSDictionary *))completionBlock;
- (BOOL) update:(NSDictionary *)entry;
- (BOOL) delete:(NSDictionary *)entry;

- (void) addObserver:(id<ISDBViewObserver>)observer;
- (void) removeObserver:(id<ISDBViewObserver>)observer;

@end
