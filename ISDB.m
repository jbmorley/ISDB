//
//  ISDB.m
//  Popcorn
//
//  Created by Jason Barrie Morley on 11/04/2013.
//
//

#import "ISDB.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"


@interface ISDB ()

@property (strong, nonatomic) NSString *path;
@property (strong, nonatomic) FMDatabase *database;
@property (strong, nonatomic) id<ISDBManagerDelegate> delegate;
@property (nonatomic) ISDBManagerState state;

@property (nonatomic, readonly) NSString *versionTable;
@property (nonatomic, readonly) NSUInteger version;
@property (nonatomic, readonly) NSUInteger currentVersion;

// TODO Support multi-threaded environments by cross posting an addition
// when accessed from a different thread.

@end

@implementation ISDB

static NSString *ColumnNameVersion = @"version";


- (id)initWithPath:(NSString *)path
            provider:(id<ISDBManagerDelegate>)provider
{
  self = [super init];
  if (self) {
    self.path = path;
    self.state = ISDBManagerStateClosed;
    // TODO There is a retain cycle here.
    self.delegate = provider;
  }
  return self;
}


#pragma mark - Properties


- (NSString *)versionTable
{
  assert(self.state != ISDBManagerStateClosed);
  if ([self.delegate respondsToSelector:@selector(versionTable)]) {
    return [self.delegate databaseVersionTable:self.database];
  } else {
    return @"version";
  }
}


- (NSUInteger)version
{
  assert(self.state != ISDBManagerStateClosed);
  if ([self.delegate respondsToSelector:@selector(databaseVersion:)]) {
    return [self.delegate databaseVersion:self.database];
  } else {
    return 1;
  }
}


- (void)setVersion:(NSUInteger)version
{
  assert(self.state != ISDBManagerStateClosed);
  NSString *query = [NSString stringWithFormat:
                     @"REPLACE INTO %@ (id, %@) VALUES (?, ?)",
                     self.versionTable,
                     ColumnNameVersion];
  BOOL success
    = [self.database executeUpdate:query
              withArgumentsInArray:@[@0,
                                     [NSNumber numberWithInteger:version]]];
  if (!success) {
    @throw [NSException exceptionWithName:@"DatabaseVersionUpdateFailure"
                                   reason:[self.database lastErrorMessage]
                                 userInfo:nil];
  }
}

- (NSUInteger)currentVersion
{
  assert(self.state != ISDBManagerStateClosed);
  // Check to see if the version table exists.
  if (![self.database tableExists:self.versionTable]) {
    // If no table exists, we create one and treat this from an upgrade
    // from version 0 to version 1 (grandfathering in existing databases).
    return 0;
  } else {
    // If the table exists, we query it for the current version.
    NSString *query = [NSString stringWithFormat:
                       @"SELECT * FROM %@ WHERE id=?",
                       self.versionTable];
    FMResultSet *result = [self.database executeQuery:query
                                 withArgumentsInArray:@[@0]];
    assert([result next]);
    return [result intForColumn:ColumnNameVersion];
  }
}


#pragma mark - Utilities


- (void)createTable:(NSString *)table
{
  assert(self.state != ISDBManagerStateClosed);
  NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@", table];
  if (![self.database executeUpdate:sql]) {
    @throw [NSException exceptionWithName:@"DatabaseCreateFailure"
                                   reason:[self.database lastErrorMessage]
                                 userInfo:nil];
  }
}


- (void)createVersionTable
{
  assert(self.state != ISDBManagerStateClosed);
  NSString *table = [NSString stringWithFormat:
                     @"%@ (id integer primary key, %@ integer)",
                     self.versionTable,
                     ColumnNameVersion];
  [self createTable:table];
}


- (BOOL)open
{
  assert(self.state == ISDBManagerStateClosed);
  NSFileManager *fileManager = [NSFileManager defaultManager];
  BOOL databaseExists = [fileManager fileExistsAtPath:self.path];
  self.database = [FMDatabase databaseWithPath:self.path];
  if ([self.database open]) {
    self.state = ISDBManagerStateOpen;
    @try {

      // If the database did not exist, then we can assume a successful
      // open has created the database.
      if (!databaseExists) {

        [self createVersionTable];
        [self create];
        
      } else {
        
        NSUInteger currentVersion = self.currentVersion;
        NSUInteger version = self.version;
        if (currentVersion < version) {
          [self updateOldVersion:currentVersion
                      newVersion:version];
        } else if (currentVersion > version) {
          @throw [NSException exceptionWithName:@"DatabaseVersionTooRecent"
                                         reason:@"The database version is higher than that supported by the provider."
                                       userInfo:nil];
        } else {
          NSLog(@"Successfully openend database '%@' with version %d",
                self.path, version);
        }
        self.state = ISDBManagerStateReady;
        
      }
      
      return YES;

      
    }
    @catch (NSException *exception) {
      
      // Clean up from a failed create or update.
      [self.database close];
      self.database = nil;
      self.state = ISDBManagerStateClosed;
      if (!databaseExists) {
        [fileManager removeItemAtPath:self.path
                                error:nil];
      }
      return NO;
      
    }
    
  }
  
  self.database = nil;
  return NO;
}


- (void)close
{
  assert(self.state != ISDBManagerStateClosed);
  [self.database close];
  self.state = ISDBManagerStateClosed;
}


- (void)create
{
  assert(self.state != ISDBManagerStateClosed);
  NSLog(@"Creating database '%@'.", self.path);
  @try {
    [self.database beginTransaction];
    [self.delegate databaseCreate:self.database];
    [self setVersion:self.version];
    [self.database commit];
  }
  @catch (NSException *exception) {
    [self.database rollback];
    @throw exception;
  }
}


- (void)updateOldVersion:(NSUInteger)oldVersion
              newVersion:(NSUInteger)newVersion
{
  assert(self.state != ISDBManagerStateClosed);
  NSLog(@"Updating database '%@' from version %d to version %d.",
        self.path, oldVersion, newVersion);
  @try {
    [self.database beginTransaction];
    [self.delegate databaseUpdate:self.database
                       oldVersion:oldVersion
                       newVersion:newVersion];
    [self createVersionTable];
    [self setVersion:newVersion];
    [self.database commit];
  }
  @catch (NSException *exception) {
    [self.database rollback];
    @throw exception;
  }
}


@end
