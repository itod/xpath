//
//  XPExceptEnumeration.m
//  Panthro
//
//  Created by Todd Ditchendorf on 5/9/14.
//
//

#import "XPExceptEnumeration.h"
#import "XPNodeSetExtent.h"
#import "XPLocalOrderComparer.h"

@interface XPExceptEnumeration ()
@property (nonatomic, retain) id <XPSequenceEnumeration>p1;
@property (nonatomic, retain) id <XPSequenceEnumeration>p2;
@property (nonatomic, retain) id <XPSequenceEnumeration>e1;
@property (nonatomic, retain) id <XPSequenceEnumeration>e2;
@property (nonatomic, retain) id <XPNodeInfo>nextNode1;
@property (nonatomic, retain) id <XPNodeInfo>nextNode2;
@property (nonatomic, retain) id <XPNodeInfo>nextNode;
@property (nonatomic, retain) id <XPNodeOrderComparer>comparer;
@end

@implementation XPExceptEnumeration

- (instancetype)initWithLhs:(id <XPSequenceEnumeration>)lhs rhs:(id <XPSequenceEnumeration>)rhs comparer:(id <XPNodeOrderComparer>)comparer {
    XPAssert(lhs);
    XPAssert(rhs);
    XPAssert(comparer);
    self = [super init];
    if (self) {
        self.p1 = lhs;
        self.p2 = rhs;
        self.comparer = comparer;
        self.e1 = _p1;
        self.e2 = _p2;
        
        if (![_e1 isSorted]) {
            self.e1 = [[[[[XPNodeSetExtent alloc] initWithEnumeration:_e1 comparer:_comparer] autorelease] sort] enumerate];
        }
        if (![_e2 isSorted]) {
            self.e2 = [[[[[XPNodeSetExtent alloc] initWithEnumeration:_e2 comparer:_comparer] autorelease] sort] enumerate];
        }
        
        if ([_e1 hasMoreObjects]) {
            self.nextNode1 = [_e1 nextNodeInfo];
        }
        if ([_e2 hasMoreObjects]) {
            self.nextNode2 = [_e2 nextNodeInfo];
        }
        
        // move to the first node in p1 that isn't in p2
        [self advance];

    }
    return self;
}


- (void)dealloc {
    self.p1 = nil;
    self.p2 = nil;
    self.e1 = nil;
    self.e2 = nil;
    self.nextNode1 = nil;
    self.nextNode2 = nil;
    self.nextNode = nil;
    self.comparer = nil;
    [super dealloc];
}


- (BOOL)isSorted {
    return YES;
}


- (BOOL)isReverseSorted {
    return NO;
}


- (BOOL)isPeer {
    return NO;
}


- (BOOL)hasMoreObjects {
    return _nextNode != nil;
}


- (id <XPNodeInfo>)nextObject {
    id <XPNodeInfo>current = _nextNode;
    [self advance];
    return current;
}


- (void)advance {
    // main merge loop: if the node in p1 has a lower key value that that in p2, return it;
    // if they are equal, advance both nodesets; if p1 is higher, advance p2.
    
    while (_nextNode1 && _nextNode2) {
        NSInteger res = [_comparer compare:_nextNode1 to:_nextNode2];
        if (res < 0) {                                                  // p1 is lower
            id <XPNodeInfo>next = _nextNode1;
            if ([_e1 hasMoreObjects]) {
                self.nextNode1 = [_e1 nextNodeInfo];
            } else {
                self.nextNode1 = nil;
                self.nextNode = nil;
            }
            self.nextNode = next;
            return;
            
        } else if (res > 0) {                                           // p1 is higher
            if ([_e2 hasMoreObjects]) {
                self.nextNode2 = [_e2 nextNodeInfo];
            } else {
                self.nextNode2 = nil;
                self.nextNode = nil;
            }
            
        } else {                                                        // keys are equal
            if ([_e1 hasMoreObjects]) {
                self.nextNode1 = [_e1 nextNodeInfo];
            } else {
                self.nextNode1 = nil;
            }
            if ([_e2 hasMoreObjects]) {
                self.nextNode2 = [_e2 nextNodeInfo];
            } else {
                self.nextNode2 = nil;
            }
        }
    }
    
    // collect the remaining nodes from the residue of p1
    
    if (_nextNode1) {
        self.nextNode = _nextNode1;
        if ([_e1 hasMoreObjects]) {
            self.nextNode1 = [_e1 nextNodeInfo];
        } else {
            self.nextNode1 = nil;
        }
        return;
    }
    
    self.nextNode = nil;
}

@end
