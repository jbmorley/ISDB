//
//  ISDBEntryIdentifier.m
//  Popcorn
//
//  Created by Jason Barrie Morley on 01/05/2013.
//
//

#import "ISDBEntry.h"

@interface ISDBEntry ()

@property (strong, nonatomic, readonly) id summary;

@end


@implementation ISDBEntry


+ (id)entryWithIdentifier:(id)identifier
                  summary:(id)summary
{
  return [[self alloc] initWithIdentifier:identifier
                                  summary:summary];
}


- (id)initWithIdentifier:(id)identifier
                 summary:(id)summary
{
  self = [super init];
  if (self) {
    _identifier = identifier;
    _summary = summary;
  }
  return self;
}


- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  } else if ([self class] == [object class]) {
    ISDBEntry *identifier = (ISDBEntry *)object;
    return [self.identifier isEqual:identifier.identifier];
  }
  return NO;
}


- (BOOL)isSummaryEqual:(ISDBEntry *)object
{
  return [self.summary isEqual:object.summary];
}


@end
