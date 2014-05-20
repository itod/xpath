//
//  XPStep.h
//  Panthro
//
//  Created by Todd Ditchendorf on 4/22/14.
//
//

#import <Foundation/Foundation.h>
#import "XPAxis.h"

@class XPExpression;
@class XPNodeTest;
@class XPContext;

@protocol XPNodeEnumeration;
@protocol XPNodeInfo;

@interface XPStep : NSObject

- (instancetype)initWithAxis:(XPAxis)axis nodeTest:(XPNodeTest *)nodeTest;

- (XPStep *)addFilter:(XPExpression *)expr;
- (XPStep *)simplify;
- (id <XPNodeEnumeration>)enumerate:(id <XPNodeInfo>)node inContext:(XPContext *)ctx;

@property (nonatomic, retain, readonly) NSArray *filters;
@property (nonatomic, assign, readonly) NSUInteger numberOfFilters;
@property (nonatomic, assign) XPAxis axis;
@property (nonatomic, retain) XPNodeTest *nodeTest;

@property (nonatomic, assign) NSRange range;
@property (nonatomic, retain) NSArray *filterRanges;
@end
