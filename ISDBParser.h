//
//  ISDBParser.h
//  Popcorn
//
//  Created by Jason Barrie Morley on 16/04/2013.
//
//

#import <Foundation/Foundation.h>

@interface ISDBParser : NSObject

// TODO Make these read only
@property (strong, nonatomic) NSMutableSet *tables;
@property (strong, nonatomic) NSMutableSet *fields;
@property (strong, nonatomic) NSString *order;

- (id)initWithQuery:(NSString *)query;
- (void)tokenize:(NSString *)query;

@end
