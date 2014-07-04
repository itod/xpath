//
//  XPSingletonEnumeration.m
//  Panthro
//
//  Created by Todd Ditchendorf on 5/9/14.
//
//

#import "XPSingletonEnumeration.h"
#import "XPNodeInfo.h"

@interface XPSingletonEnumeration ()
@property (nonatomic, retain) id <XPItem>node;
@property (nonatomic, assign) BOOL gone;
@property (nonatomic, assign) NSUInteger count;
@end

@implementation XPSingletonEnumeration

- (instancetype)init {
    self = [self initWithNode:nil];
    return self;
}


- (instancetype)initWithNode:(id <XPItem>)node {
    self = [super init];
    if (self) {
        self.node = node;
        self.gone = node == nil;
        self.count = (node ? 1 : 0);
    }
    return self;
}


- (void)dealloc {
    self.node = nil;
    [super dealloc];
}

    
- (BOOL)isSorted {
    return YES;
}


- (BOOL)isReverseSorted {
    return YES;
}


- (BOOL)isPeer {
    return YES;
}


- (BOOL)hasMoreObjects {
    return !_gone;
}


- (id <XPItem>)nextObject {
    XPAssert(!_gone);
    _gone = true;
    return _node;
}


- (NSUInteger)lastPosition {
    return _count;
}

@end
