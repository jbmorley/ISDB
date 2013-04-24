//
//  ISWeakReferenceArray.m
//  Popcorn
//
//  Created by Jason Barrie Morley on 24/04/2013.
//
//

#import "ISWeakReferenceArray.h"
#import "ISWeakReference.h"

@interface ISWeakReferenceArray ()

@property (strong, nonatomic) NSMutableArray *items;

@end

@implementation ISWeakReferenceArray


+ (id)arrayWithCapacity:(NSUInteger)numItems
{
  return [[self alloc] initWithCapacity:numItems];
}


- (id)initWithCapacity:(NSUInteger)numItems
{
  self = [super init];
  if (self) {
    self.items = [NSMutableArray arrayWithCapacity:numItems];
  }
  return self;
}


- (void)addObject:(id)anObject
{
  [self.items addObject:[ISWeakReference referenceWithObject:anObject]];
  [self removeMissingObjects];
}


- (void)removeObject:(id)anObject
{
  NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
  for (NSUInteger i = 0; i < self.items.count; i++) {
    ISWeakReference *reference = self.items[i];
    if (reference.object == anObject) {
      [indexes addIndex:i];
    }
  }
  [self.items removeObjectsAtIndexes:indexes];
  [self removeMissingObjects];
}


- (NSUInteger)count
{
  [self removeMissingObjects];
  return self.items.count;
}


- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])buffer
                                    count:(NSUInteger)len
{
  NSUInteger count = 0;
  // Initialization.
  if (state->state == 0) {
    // Ignoring mutations.
    state->mutationsPtr = &state->extra[0];
    // Only remove nil objects in the initialization state to avoid the
    // risk of mutations from releases on other threads.
    [self removeMissingObjects];
  }
  // Provide items in bocks matching buffer size (len).
  if (state->state < self.items.count) {
    // Use the provided buffer.
    state->itemsPtr = buffer;
    // Fill in the stack array, either until we've provided all items from the list
    // or until we've provided as many items as the stack based buffer will hold.
    while((state->state < self.items.count) && (count < len))
    {
      // Read the next set of items into the buffer.
      ISWeakReference *item = [self.items objectAtIndex:(state->state)];
      buffer[count] = item.object;
      state->state++;
      count++;
    }
  }
  else {
    // Indicate that we're done.
    count = 0;
  }
  return count;
}


- (void)removeMissingObjects
{
  NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
  for (NSUInteger i = 0; i < self.items.count; i++) {
    ISWeakReference *reference = self.items[i];
    if (reference.object == nil) {
      [indexes addIndex:i];
    }
  }
  [self.items removeObjectsAtIndexes:indexes];
}


@end
