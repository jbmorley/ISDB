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

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "ISDBProvider.h"
#import "ISDBView.h"
#import "ISDBDataSource.h"

@class ISDatabase;

typedef enum {

  ISDatabaseStateClosed = 0,
  ISDatabaseStateOpen   = 1,
  ISDatabaseStateReady  = 2,
  
} ISDatabaseState;
                        
@interface ISDatabase : NSObject

// TODO Consider passing the provider into the open call to work
// around the slightly weird ownership model of the provider.

- (id)initWithPath:(NSString *)path
          provider:(id<ISDBProvider>)provider;
- (BOOL)open;
- (void)close;

- (ISDBView *)viewWithDataSource:(id<ISDBDataSource>)dataSource;

@end
