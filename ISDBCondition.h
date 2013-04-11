//
//  ISDBCondition.h
//  Learn
//
//  Created by Jason Barrie Morley on 18/01/2013.
//
//

#import <Foundation/Foundation.h>

typedef enum {
  ISDBConditionTypeEqual,
  ISDBConditionTypeLessThan,
  ISDBConditionTypeGreaterThan
} ISDBConditionType;

@interface ISDBCondition : NSObject

@property (nonatomic) ISDBConditionType type;
@property (strong, nonatomic) NSString *key;
@property (strong, nonatomic) id value;

+ (ISDBCondition *) condition:(NSString *)key
                      equalTo:(id)value;
+ (ISDBCondition *) condition:(NSString *)key
                     lessThan:(id)value;
+ (ISDBCondition *) condition:(NSString *)key
                  greaterThan:(id)value;

- (id) initWithType:(ISDBConditionType)type
                key:(NSString *)key
              value:(id)value;
- (NSString *) string;

@end
