//
//  XPFilterExpression.m
//  Panthro
//
//  Created by Todd Ditchendorf on 5/7/14.
//
//

#import "XPFilterExpression.h"
#import "XPEmptyNodeSet.h"
#import "XPNumericValue.h"
#import "XPFilterEnumerator.h"
#import "XPSingletonNodeSet.h"
#import "XPException.h"

@interface XPFilterExpression ()
@end

@implementation XPFilterExpression

/**
 * Constructor
 * @param start A node-set expression denoting the absolute or relative set of nodes from which the
 * navigation path should start.
 * @param filter An expression defining the filter predicate
 */

- (instancetype)initWithStart:(XPExpression *)start filter:(XPExpression *)filter {
    NSParameterAssert(start);
    NSParameterAssert(filter);
    self = [super init];
    if (self) {
        self.start = start;
        self.filter = filter;
        self.dependencies = XPDependenciesInvalid;
    }
    return self;
}


- (void)dealloc {
    self.start = nil;
    self.filter = nil;
    [super dealloc];
}


- (id)copyWithZone:(NSZone *)zone {
    XPFilterExpression *expr = [super copyWithZone:zone];
    expr.start = [[_start copy] autorelease];
    expr.filter = [[_filter copy] autorelease];
    expr.dependencies = _dependencies;
    return expr;
}


- (NSString *)description {
    return [NSString stringWithFormat:@"(%@)[%@]", _start, _filter];
}


- (NSArray *)filters {
    return @[_filter]; // ??
}


- (NSUInteger)numberOfFilters {
    return _filter ? 1 : 0;
}


/**
 * Simplify an expression
 */

- (XPExpression *)simplify {
    XPExpression *result = self;
    
    self.start = [_start simplify];
    self.filter = [_filter simplify];
    
    // ignore the filter if the base expression is an empty node-set
    if ([_start isKindOfClass:[XPEmptyNodeSet class]]) {
        result = _start;
    } else if ([_filter isValue] && ![_filter isKindOfClass:[XPNumericValue class]]) { // check whether the filter is a constant true() or false()
        BOOL f = [(XPValue *)_filter asBoolean];
        if (f) {
            result = _start;
        } else {
            result = [XPEmptyNodeSet instance];
        }
    }
    
    result.range = self.range;
    return result;
    
//    // check whether the filter is [last()] (note, position()=last() will
//    // have already been simplified)
//    
//    if (filter instanceof Last) {
//        filter = new IsLastExpression(true);
//    }
//    
//    // following code is designed to catch the case where we recurse over a node-set
//    // setting $ns := $ns[position()>1]. The effect is to combine the accumulating
//    // filters, for example on the third iteration the filter will be effectively
//    // x[position()>3] rather than x[position()>1][position()>1][position()>1].
//    
//    if (start instanceof NodeSetIntent &&
//        filter instanceof PositionRange) {
//        PositionRange pred = (PositionRange)filter;
//        if (pred.getMinPosition()==2 && pred.getMaxPosition()==Integer.MAX_VALUE) {
//            //System.err.println("Found candidate ");
//            NodeSetIntent b = (NodeSetIntent)start;
//            //System.err.println("Found candidate start is " + b.getNodeSetExpression().getClass());
//            if (b.getNodeSetExpression() instanceof FilterExpression) {
//                FilterExpression t = (FilterExpression)b.getNodeSetExpression();
//                if (t.filter instanceof PositionRange) {
//                    PositionRange pred2 = (PositionRange)t.filter;
//                    if (pred2.getMaxPosition()==Integer.MAX_VALUE) {
//                        //System.err.println("Opt!! start =" + pred2.getMinPosition() );
//                        return new FilterExpression(t.start,
//                                                    new PositionRange(pred2.getMinPosition()+1, Integer.MAX_VALUE));
//                    }
//                }
//            }
//        }
//    }
    
    return self;
}

/**
 * Evaluate the filter expression in a given context to return a Node Enumeration
 * @param context the evaluation context
 * @param sort true if the result must be in document order
 */

- (id <XPSequenceEnumeration>)enumerateInContext:(XPContext *)ctx sorted:(BOOL)sort {
    
    // if the expression references variables, or depends on other aspects
    // of the XSLT context, then fix up these dependencies now. If the expression
    // will only return nodes from the context document, then any dependency on
    // the context document within the predicate can also be fixed up now.
    
    XPDependencies actualdep = [self dependencies];
    XPDependencies removedep = 0;
    
    if ((actualdep & XPDependenciesXSLTContext) != 0) {
        removedep |= XPDependenciesXSLTContext;
    }
    
    if ([_start isContextDocumentNodeSet] && ((actualdep & XPDependenciesContextDocument) != 0)) {
        removedep |= XPDependenciesContextDocument;
    }
    
    if (removedep != 0) {
        return [[self reduceDependencies:removedep inContext:ctx] enumerateInContext:ctx sorted:sort];
    }
    
    if (!sort) {
        // the user didn't ask for document order, but we may need to do it anyway
        if (_filter.dataType == XPDataTypeNumber ||
            _filter.dataType == XPDataTypeAny ||
            ([_filter dependencies] & (XPDependenciesContextPosition|XPDependenciesLast)) != 0) {
            sort = YES;
        }
    }
    
    if ([_start isKindOfClass:[XPSingletonNodeSet class]]) {
        if (![(XPSingletonNodeSet *)_start isGeneralUseAllowed]) {
            [XPException raiseIn:self format:@"To use a result tree fragment in a filter expression, either use exsl:node-set() or specify version='1.1'"];
        }
    }
    
    id <XPSequenceEnumeration>base = [_start enumerateInContext:ctx sorted:sort];
    if (![base hasMoreItems]) {
        return base;        // quick exit for an empty node set
    }
    
    return [[[XPFilterEnumerator alloc] initWithBase:base filter:_filter context:ctx finishAfterReject:NO] autorelease];
}


/**
 * Determine which aspects of the context the expression depends on. The result is
 * a bitwise-or'ed value composed from constants such as Context.VARIABLES and
 * Context.CURRENT_NODE
 */

- (XPDependencies)dependencies {
    // not all dependencies in the filter expression matter, because the context node,
    // position, and size are not dependent on the outer context.
    if (XPDependenciesInvalid == _dependencies) {

        // 2nd half herelooks for Variables and CurrentNode only.
        // That masks out the ctx node, ctx position, and ctx size (these 3 are derived in a predicate, not used from the context)
        self.dependencies = [_start dependencies] | ([_filter dependencies] & XPDependenciesXSLTContext);
    }
    // System.err.println("Filter expression getDependencies() = " + dependencies);
    return _dependencies;
}


/**
 * Perform a partial evaluation of the expression, by eliminating specified dependencies
 * on the context.
 * @param dep The dependencies to be removed
 * @param context The context to be used for the partial evaluation
 * @return a new expression that does not have any of the specified
 * dependencies
 */

- (XPExpression *)reduceDependencies:(XPDependencies)dep inContext:(XPContext *)ctx {
    XPExpression *result = self;

    if ((self.dependencies & dep) != 0) {
        XPExpression *newstart = [_start reduceDependencies:dep inContext:ctx];
        XPExpression *newfilter = [_filter reduceDependencies:(dep & XPDependenciesXSLTContext) inContext:ctx];
        XPExpression *e = [[[XPFilterExpression alloc] initWithStart:newstart filter:newfilter] autorelease];
        e.staticContext = self.staticContext;
        e.range = self.range;
        result = [e simplify];
    }
    
    return result;
}


/**
 * Determine, in the case of an expression whose data type is Value.NODESET,
 * whether all the nodes in the node-set are guaranteed to come from the same
 * document as the context node. Used for optimization.
 */

- (BOOL)isContextDocumentNodeSet {
    return [_start isContextDocumentNodeSet];
}

@end
