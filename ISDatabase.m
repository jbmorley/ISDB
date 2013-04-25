//
// Copyright (c) 2013 InSeven Limited.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// 

#import "ISDatabase.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "ISWeakReferenceArray.h"
#import "FMDatabase+Update.h"

// TODO Add a trigger to the FMDatabase to notify the views when they have changed.


@interface ISDatabase ()

@property (strong, nonatomic) NSString *path;
@property (strong, nonatomic) FMDatabase *database;
@property (weak, nonatomic) id<ISDBProvider> provider;
@property (nonatomic) ISDatabaseState state;
@property (nonatomic, readonly) NSString *versionTable;
@property (nonatomic, readonly) NSUInteger version;
@property (nonatomic, readonly) NSUInteger currentVersion;
@property (strong, nonatomic) ISWeakReferenceArray *views;

@end

@implementation ISDatabase

static NSString *ColumnNameVersion = @"version";

// TODO ISDatabase owns the views, stores them by query and tracks
// interdependence between views (somehow).
// It will make a point of returning the same view by ID.
// We should be able to guard against people incorrectly creating
// ISDBView directly by using categories.


// TODO Store weak references to the views so we know when they're no
// longer in use.  This also avoids reference cycles.


- (id)initWithPath:(NSString *)path
            provider:(id<ISDBProvider>)provider
{
  // Restrict to the main thread.
  // Future implementations may wish to implement a dispatch queue for
  // each database instance and cross post all operations to this to
  // avoid loading the main thread.  Events would likely still need to
  // be cross-posted back to the main thread though so the benefits are
  // limited.
  assert([[NSThread currentThread] isMainThread]);
  self = [super init];
  if (self) {
    self.path = path;
    self.state = ISDatabaseStateClosed;
    self.provider = provider;
    self.views = [ISWeakReferenceArray arrayWithCapacity:3];
  }
  return self;
}


#pragma mark - Properties


- (NSString *)versionTable
{
  assert(self.state != ISDatabaseStateClosed);
  if ([self.provider respondsToSelector:@selector(versionTable)]) {
    return [self.provider databaseVersionTable:self.database];
  } else {
    return @"version";
  }
}


- (NSUInteger)version
{
  assert(self.state != ISDatabaseStateClosed);
  if ([self.provider respondsToSelector:@selector(databaseVersion:)]) {
    return [self.provider databaseVersion:self.database];
  } else {
    return 1;
  }
}


- (void)setVersion:(NSUInteger)version
{
  assert(self.state != ISDatabaseStateClosed);
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
  assert(self.state != ISDatabaseStateClosed);
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
  assert(self.state != ISDatabaseStateClosed);
  NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@", table];
  if (![self.database executeUpdate:sql]) {
    @throw [NSException exceptionWithName:@"DatabaseCreateFailure"
                                   reason:[self.database lastErrorMessage]
                                 userInfo:nil];
  }
}


- (void)createVersionTable
{
  assert(self.state != ISDatabaseStateClosed);
  NSString *table = [NSString stringWithFormat:
                     @"%@ (id integer primary key, %@ integer)",
                     self.versionTable,
                     ColumnNameVersion];
  [self createTable:table];
}


- (BOOL)open
{
  assert(self.state == ISDatabaseStateClosed);
  NSFileManager *fileManager = [NSFileManager defaultManager];
  BOOL databaseExists = [fileManager fileExistsAtPath:self.path];
  self.database = [FMDatabase databaseWithPath:self.path];
  if ([self.database open]) {
    self.state = ISDatabaseStateOpen;
    @try {

      // If the database did not exist, then we can assume a successful
      // open has created the database.
      if (!databaseExists) {

        [self createVersionTable];
        [self create];
        self.state = ISDatabaseStateReady;
        
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
        self.state = ISDatabaseStateReady;
        
      }
      
      // Register for updates.
      [self.database update:self
                   selector:@selector(databaseDidUpdate)];
      
      return YES;

      
    }
    @catch (NSException *exception) {
      
      // Clean up from a failed create or update.
      [self.database close];
      self.database = nil;
      self.state = ISDatabaseStateClosed;
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


- (void)databaseDidUpdate
{
  NSLog(@"databaseDidUpdate");
  for (ISDBView *view in self.views) {
    [view reload];
  }
}


- (void)close
{
  assert(self.state != ISDatabaseStateClosed);
  [self.database close];
  self.state = ISDatabaseStateClosed;
}


- (void)create
{
  assert(self.state != ISDatabaseStateClosed);
  NSLog(@"Creating database '%@'.", self.path);
  @try {
    [self.database beginTransaction];
    if (![self.provider databaseCreate:self.database]) {
      @throw [NSException exceptionWithName:@"DatabaseCreateFailure"
                                     reason:@"Provider create failed."
                                   userInfo:nil];
    }
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
  assert(self.state != ISDatabaseStateClosed);
  NSLog(@"Updating database '%@' from version %d to version %d.",
        self.path, oldVersion, newVersion);
  @try {
    [self.database beginTransaction];
    if (![self.provider databaseUpdate:self.database
                            oldVersion:oldVersion
                            newVersion:newVersion]) {
      @throw [NSException exceptionWithName:@"DatabaseUpdateFailure"
                                     reason:@"Provider update failed."
                                   userInfo:nil];
    }
    [self createVersionTable];
    [self setVersion:newVersion];
    [self.database commit];
  }
  @catch (NSException *exception) {
    [self.database rollback];
    @throw exception;
  }
}


#pragma mark - Accessors


- (ISDBView *)viewWithDataSource:(id<ISDBViewDataSource>)dataSource
{
  assert(self.state == ISDatabaseStateReady);
  ISDBView *view = [[ISDBView alloc] initWithDatabase:self.database
                                           dataSource:dataSource];
  [self.views addObject:view];
  return view;
}


@end
