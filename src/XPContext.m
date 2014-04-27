//
//  XPContext.m
//  XPath
//
//  Created by Todd Ditchendorf on 7/20/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <XPath/XPContext.h>
#import <XPath/XPController.h>
#import <XPath/XPStaticContext.h>

@implementation XPContext

- (void)dealloc {
    self.staticContext = nil;
    [super dealloc];
}


- (id <XPNodeInfo>)contextNodeInfo {
    return nil;
}


- (NSUInteger)last {
    return 1;
//    if (!lastPositionFinder) return 1;
//    return [lastPositionFinder lastPosition];
}


- (NSUInteger)contextPosition {
    return 1;
}


- (XPController *)controller {
    return nil;
}

@synthesize staticContext;
@end
