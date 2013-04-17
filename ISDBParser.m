//
//  ISDBParser.m
//  Popcorn
//
//  Created by Jason Barrie Morley on 16/04/2013.
//
//

#import "ISDBParser.h"
#import "ParseKit/ParseKit.h"

@interface ISDBParser ()

@property (strong, nonatomic) NSString *query;
@property (strong, nonatomic) NSMutableArray *tables;
@property (strong, nonatomic) NSMutableArray *fields;

@end

@implementation ISDBParser

- (id)initWithQuery:(NSString *)query
{
  self = [super init];
  if (self) {
    self.query = query;
    
    self.tables = [NSMutableArray arrayWithCapacity:3];
    self.fields = [NSMutableArray arrayWithCapacity:3];
    
    [self tokenize:self.query];
    
    // TODO What does this need to determine?
    // Tables a query depends on (e.g. in the case of a join, etc).
    // Whether the distinct keyword is defined.
    // Which columns are included in the query (and subsequently which column forms the primary identifier
    // which column is used for any order by
    // (if we do not specify an order by, what do we do?
    // whether the table is a compound table or not...
    
    
    
  }
  return self;
}

- (void)tokenize:(NSString *)query
{
  NSString *filePath = [[NSBundle mainBundle] pathForResource:@"sqlite"
                                                       ofType:@"grammar"];
  NSString *g = [NSString stringWithContentsOfFile:filePath
                                          encoding:NSUTF8StringEncoding
                                             error:nil];
  
  PKParser *parser = nil;
  parser = [[PKParserFactory factory] parserFromGrammar:g
                                              assembler:self
                                                  error:nil];
  
  NSError *error = nil;
  [parser parse:query
          error:&error];
}


- (NSString *)description
{
  return [NSString stringWithFormat:@"Query: '%@', Tables: [%@], Fields: [%@]",
          self.query,
          [self.tables componentsJoinedByString:@","],
          [self.fields componentsJoinedByString:@","]];
}


#pragma mark - Assembler callbacks


- (void)parser:(PKParser *)parser
didMatchTable_name:(PKAssembly *)a
{
  NSLog(@"Table Name: %@", [a.stack lastObject]);
}


- (void)parser:(PKParser *)parser
didMatchResult_column:(PKAssembly *)a
{
  [self.fields addObject:[a.stack lastObject]];
}


- (void)parser:(PKParser *)parser
didMatchTable_description:(PKAssembly *)a
{
  [self.tables addObject:[a.stack lastObject]];
}


@end
