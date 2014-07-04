//
//  XPExceptEnumeration.h
//  Panthro
//
//  Created by Todd Ditchendorf on 5/9/14.
//
//

#import "XPBaseFastEnumeration.h"

@protocol XPNodeOrderComparer;

@interface XPExceptEnumeration : XPBaseFastEnumeration

- (instancetype)initWithLhs:(id <XPNodeEnumeration>)lhs rhs:(id <XPNodeEnumeration>)rhs comparer:(id <XPNodeOrderComparer>)comparer;
@end