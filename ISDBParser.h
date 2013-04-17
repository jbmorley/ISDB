//
//  ISDBParser.h
//  Popcorn
//
//  Created by Jason Barrie Morley on 16/04/2013.
//
//

#import <Foundation/Foundation.h>

@interface ISDBParser : NSObject

- (id)initWithQuery:(NSString *)query;
- (void)tokenize:(NSString *)query;

@end
