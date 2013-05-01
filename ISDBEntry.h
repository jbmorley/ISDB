//
//  ISDBEntryIdentifier.h
//  Popcorn
//
//  Created by Jason Barrie Morley on 01/05/2013.
//
//

#import <Foundation/Foundation.h>

@interface ISDBEntry : NSObject

@property (strong, nonatomic, readonly) id identifier;

+ (id)entryWithIdentifier:(id)identifier
                  summary:(id)summary;
- (id)initWithIdentifier:(id)identifier
                 summary:(id)summary;

@end
