//
//  XPAssembler.m
//  Panthro
//
//  Created by Todd Ditchendorf on 7/16/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "XPAssembler.h"
#import <Panthro/Panthro.h>
#import <PEGKit/PEGKit.h>
#import <PEGKit/PKParser+Subclass.h>

#import "XPBooleanExpression.h"
#import "XPRelationalExpression.h"
#import "XPArithmeticExpression.h"

#import "XPStep.h"
#import "XPAxis.h"
#import "XPNodeTypeTest.h"
#import "XPNameTest.h"

#import "XPPathExpression.h"

#import "XPRootExpression.h"
#import "XPContextNodeExpression.h"
#import "XPFilterExpression.h"
#import "XPUnionExpression.h"

#import "XPVariableReference.h"

@interface XPAssembler ()
@property (nonatomic, retain) id <XPStaticContext>env;
@property (nonatomic, retain) NSDictionary *nodeTypeTab;
@property (nonatomic, retain) PKToken *openParen;
@property (nonatomic, retain) PKToken *slash;
@property (nonatomic, retain) PKToken *colon;
@property (nonatomic, retain) PKToken *doubleSlash;
@property (nonatomic, retain) PKToken *dotDotDot;
@property (nonatomic, retain) PKToken *pipe;
@property (nonatomic, retain) PKToken *closeBracket;
@property (nonatomic, retain) PKToken *atAxis;
@property (nonatomic, retain) NSCharacterSet *singleQuoteCharSet;
@property (nonatomic, retain) NSCharacterSet *doubleQuoteCharSet;
@end

@implementation XPAssembler

- (instancetype)initWithContext:(id <XPStaticContext>)env {
    XPAssert(env);
    if (self = [super init]) {
        self.env = env;
        self.openParen = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"(" doubleValue:0.0];
        self.slash = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"/" doubleValue:0.0];
        self.colon = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@":" doubleValue:0.0];
        self.doubleSlash = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"//" doubleValue:0.0];
        self.dotDotDot = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"…" doubleValue:0.0];
        self.pipe = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"|" doubleValue:0.0];
        self.closeBracket = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"]" doubleValue:0.0];
        self.atAxis = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"@" doubleValue:0.0];
        self.singleQuoteCharSet = [NSCharacterSet characterSetWithCharactersInString:@"'"];
        self.doubleQuoteCharSet = [NSCharacterSet characterSetWithCharactersInString:@"\""];
        
        self.nodeTypeTab = @{
            XPNodeTypeName[XPNodeTypeNode] : @(XPNodeTypeNode),
            XPNodeTypeName[XPNodeTypeElement] : @(XPNodeTypeElement),
            XPNodeTypeName[XPNodeTypeAttribute] : @(XPNodeTypeAttribute),
            XPNodeTypeName[XPNodeTypeText] : @(XPNodeTypeText),
            XPNodeTypeName[XPNodeTypePI] : @(XPNodeTypePI),
            XPNodeTypeName[XPNodeTypeComment] : @(XPNodeTypeComment),
            XPNodeTypeName[XPNodeTypeRoot] : @(XPNodeTypeRoot),
            XPNodeTypeName[XPNodeTypeNamespace] : @(XPNodeTypeNamespace),
            XPNodeTypeName[XPNodeTypeNumberOfTypes] : @(XPNodeTypeNumberOfTypes),
            XPNodeTypeName[XPNodeTypeNone] : @(XPNodeTypeNone),
            @"file" : @(XPNodeTypeText),
            @"folder" : @(XPNodeTypeElement),
        };
    }
    return self;
}


- (void)dealloc {
    self.env = nil;
    self.nodeTypeTab = nil;
    self.openParen = nil;
    self.slash = nil;
    self.colon = nil;
    self.doubleSlash = nil;
    self.dotDotDot = nil;
    self.pipe = nil;
    self.closeBracket = nil;
    self.atAxis = nil;
    self.singleQuoteCharSet = nil;
    self.doubleQuoteCharSet = nil;
    [super dealloc];
}


- (void)parser:(PKParser *)p didMatchOrAndExpr:(PKAssembly *)a { [self parser:p didMatchAnyBooleanExpr:a]; }
- (void)parser:(PKParser *)p didMatchAndEqualityExpr:(PKAssembly *)a { [self parser:p didMatchAnyBooleanExpr:a]; }

- (void)parser:(PKParser *)p didMatchAnyBooleanExpr:(PKAssembly *)a {
    XPValue *v2 = [a pop];
    PKToken *opTok = [a pop];
    XPValue *v1 = [a pop];

    NSInteger op = XPTokenTypeAnd;

    if ([@"or" isEqualToString:opTok.stringValue]) {
        op = XPTokenTypeOr;
    }

    XPExpression *boolExpr = [XPBooleanExpression booleanExpressionWithOperand:v1 operator:op operand:v2];
    boolExpr.range = NSMakeRange(v1.range.location, NSMaxRange(v2.range));
    [a push:boolExpr];
}


- (void)parser:(PKParser *)p didMatchCompareAdditiveExpr:(PKAssembly *)a { [self parser:p didMatchAnyRelationalExpr:a]; }
- (void)parser:(PKParser *)p didMatchEqRelationalExpr:(PKAssembly *)a { [self parser:p didMatchAnyRelationalExpr:a]; }

- (void)parser:(PKParser *)p didMatchAnyRelationalExpr:(PKAssembly *)a {
    XPExpression *p2 = [a pop];
    XPAssertExpr(p2);
    PKToken *opTok = [a pop];
    XPAssertToken(opTok);
    XPExpression *p1 = [a pop];
    XPAssertExpr(p1);
    
    NSInteger op = XPTokenTypeEquals;
    NSString *opStr = opTok.stringValue;

    if ([@"!=" isEqualToString:opStr]) {
        op = XPTokenTypeNE;
    } else if ([@"<" isEqualToString:opStr]) {
        op = XPTokenTypeLT;
    } else if ([@">" isEqualToString:opStr]) {
        op = XPTokenTypeGT;
    } else if ([@"<=" isEqualToString:opStr]) {
        op = XPTokenTypeLE;
    } else if ([@">=" isEqualToString:opStr]) {
        op = XPTokenTypeGE;
    }
    
    XPExpression *relExpr = [XPRelationalExpression relationalExpressionWithOperand:p1 operator:op operand:p2];
    relExpr.range = NSMakeRange(p1.range.location, NSMaxRange(p2.range));
    [a push:relExpr];
}


- (void)parser:(PKParser *)p didMatchPlusOrMinusMultiExpr:(PKAssembly *)a { [self parser:p didMatchAnyArithmeticExpr:a]; }
- (void)parser:(PKParser *)p didMatchMultDivOrModUnaryExpr:(PKAssembly *)a { [self parser:p didMatchAnyArithmeticExpr:a]; }

- (void)parser:(PKParser *)p didMatchAnyArithmeticExpr:(PKAssembly *)a {
    XPValue *v2 = [a pop];
    PKToken *opTok = [a pop];
    XPValue *v1 = [a pop];
    
    NSInteger op = XPTokenTypePlus;
    
    if ([@"-" isEqualToString:opTok.stringValue]) {
        op = XPTokenTypeMinus;
    } else if ([@"div" isEqualToString:opTok.stringValue]) {
        op = XPTokenTypeDiv;
    } else if ([@"*" isEqualToString:opTok.stringValue]) {
        op = XPTokenTypeMult;
    } else if ([@"mod" isEqualToString:opTok.stringValue]) {
        op = XPTokenTypeMod;
    }
    
    XPExpression *mathExpr = [XPArithmeticExpression arithmeticExpressionWithOperand:v1 operator:op operand:v2];
    mathExpr.range = NSMakeRange(v1.range.location, NSMaxRange(v2.range));
    [a push:mathExpr];
}


- (void)parser:(PKParser *)p didMatchBooleanLiteralFunctionCall:(PKAssembly *)a {
    PKToken *closeParenTok = [a pop];
    XPAssert([closeParenTok.stringValue isEqualToString:@")"]);
    PKToken *nameTok = [a pop];
    
    BOOL b = NO;
    
    if ([nameTok.stringValue isEqualToString:@"true"]) {
        b = YES;
    }

    XPExpression *boolExpr = [XPBooleanValue booleanValueWithBoolean:b];
    NSUInteger offset = nameTok.offset;
    boolExpr.range = NSMakeRange(offset, (closeParenTok.offset+1) - offset);
    [a push:boolExpr];
}


- (void)parser:(PKParser *)p didMatchActualFunctionCall:(PKAssembly *)a {
    PKToken *closeParenTok = [a pop];
    XPAssert([closeParenTok.stringValue isEqualToString:@")"]);

    NSArray *args = [a objectsAbove:_openParen];
    [a pop]; // '('
    
    PKToken *nameTok = [a pop];
    NSString *name = [nameTok stringValue];

    XPAssert(_env);
    NSError *err = nil;
    XPFunction *fn = [_env makeSystemFunction:name error:&err];
    if (!fn) {
        if (err) {
            PKRecognitionException *rex = [[[PKRecognitionException alloc] init] autorelease];
            rex.range = NSMakeRange(nameTok.offset, [name length]);
            rex.currentName = @"Unknown XPath function";
            rex.currentReason = [err localizedFailureReason];
            [rex raise];
        }
    }
    
    for (id arg in [args reverseObjectEnumerator]) {
        [fn addArgument:arg];
    }
    
    NSUInteger offset = nameTok.offset;
    fn.range = NSMakeRange(offset, (closeParenTok.offset+1) - offset);
    [a push:fn];
}


- (void)parser:(PKParser *)p didMatchVariableReference:(PKAssembly *)a {
    PKToken *nameTok = [a pop];
    XPAssertToken(nameTok);
    
    PKToken *dollarTok = [a pop];
    XPAssertToken(dollarTok);
    XPAssert([dollarTok.stringValue isEqualToString:@"$"]);

    NSString *name = nameTok.stringValue;
    XPVariableReference *ref = [[[XPVariableReference alloc] initWithName:name] autorelease];
    NSUInteger offset = dollarTok.offset;
    ref.range = NSMakeRange(offset, (nameTok.offset+name.length) - offset);
    [a push:ref];
}


- (void)parser:(PKParser *)p didMatchFilterExpr:(PKAssembly *)a {
    NSArray *filters = [self filtersFrom:a];
    NSUInteger lastBracketMaxOffset = [[a pop] unsignedIntegerValue];
    
    if ([filters count]) {
        XPFilterExpression *filterExpr = [a pop];
        for (XPExpression *f in filters) {
            NSUInteger offset = filterExpr.range.location;
            filterExpr = [[[XPFilterExpression alloc] initWithStart:filterExpr filter:f] autorelease];
            filterExpr.range = NSMakeRange(offset, NSMaxRange(f.range));
            XPAssert(NSNotFound != filterExpr.range.location);
            XPAssert(NSNotFound != filterExpr.range.length);
            XPAssert(filterExpr.range.length);
        }
        
        filterExpr.range = NSMakeRange(filterExpr.range.location, lastBracketMaxOffset - filterExpr.range.location);
        [a push:filterExpr];
    }
}


- (void)parser:(PKParser *)p didMatchLocationPath:(PKAssembly *)a {
    
    NSArray *pathParts = [a objectsAbove:_dotDotDot];
    [a pop]; // pop …
    
    XPExpression *pathExpr = [a pop]; // either context-node() or root() expr
    XPAssertExpr(pathExpr);
    
    for (id part in [pathParts reverseObjectEnumerator]) {
        XPStep *step = nil;
        if ([_slash isEqualTo:part]) {
            continue;
        } else if ([_doubleSlash isEqualTo:part]) {
            XPNodeTest *nodeTest = [[[XPNodeTypeTest alloc] initWithNodeType:XPNodeTypeNode] autorelease];
            NSUInteger offset = [part offset];
            nodeTest.range = NSMakeRange(offset+2, 0);
            step = [self stepWithStartOffset:offset maxOffset:NSNotFound axis:XPAxisDescendantOrSelf nodeTest:nodeTest filters:nil];
        } else {
            XPAssert([part isKindOfClass:[XPStep class]]);
            step = (id)part;
        }
        NSUInteger offset = pathExpr.range.location;
        pathExpr = [[[XPPathExpression alloc] initWithStart:pathExpr step:step] autorelease];
        pathExpr.range = NSMakeRange(offset, NSMaxRange(step.range));
        XPAssert(NSNotFound != pathExpr.range.location);
        XPAssert(NSNotFound != pathExpr.range.length);
        XPAssert(pathExpr.range.length);
    }
    
    [a push:pathExpr];
}

    
- (void)parser:(PKParser *)p didMatchComplexFilterPathStartExpr:(PKAssembly *)a {
    [a push:_dotDotDot];
}


- (void)parser:(PKParser *)p didMatchComplexFilterPath:(PKAssembly *)a {
    [self parser:p didMatchLocationPath:a];
}


- (void)parser:(PKParser *)p didMatchUnionTail:(PKAssembly *)a {
    XPExpression *rhs = [a pop];
    id peek = [a pop];
    
    if ([peek isEqualTo:_pipe]) {
        XPExpression *lhs = [a pop];
        
        XPExpression *unionExpr = [[[XPUnionExpression alloc] initWithLhs:lhs rhs:rhs] autorelease];
        unionExpr.range = NSMakeRange(lhs.range.location, NSMaxRange(rhs.range));
        [a push:unionExpr];
    } else {
        [a push:peek];
        [a push:rhs];
    }
}


- (void)parser:(PKParser *)p didMatchFirstRelativeStep:(PKAssembly *)a {
    XPStep *step = [a pop];
    XPAssert([step isKindOfClass:[XPStep class]]);
    
    XPExpression *ctxNodeExpr = [[[XPContextNodeExpression alloc] init] autorelease];
    ctxNodeExpr.range = step.range;
    [a push:ctxNodeExpr];
    [a push:_dotDotDot];
    
    if (XPAxisSelf == step.axis && XPNodeTypeNode == step.nodeTest.nodeType) {
        // drop redundant self::node() step
    } else {
        [a push:step];
    }
}


- (void)parser:(PKParser *)p didMatchRootSlash:(PKAssembly *)a {
    PKToken *slashTok = [a pop];
    XPAssertToken(slashTok);
    XPExpression *rootExpr = [[[XPRootExpression alloc] init] autorelease];
    rootExpr.range = NSMakeRange(slashTok.offset, 1);
    [a push:rootExpr];
    [a push:_dotDotDot];
}


- (void)parser:(PKParser *)p didMatchRootDoubleSlash:(PKAssembly *)a {
    PKToken *slashTok = [a pop];
    XPAssertToken(slashTok);
    XPExpression *rootExpr = [[[XPRootExpression alloc] init] autorelease];
    rootExpr.range = NSMakeRange(slashTok.offset, 2);
    [a push:rootExpr];
    [a push:_dotDotDot];

    XPNodeTest *nodeTest = [[[XPNodeTypeTest alloc] initWithNodeType:XPNodeTypeNode] autorelease];
    NSUInteger offset = slashTok.offset;
    nodeTest.range = NSMakeRange(offset+2, 0);
    XPStep *step = [self stepWithStartOffset:offset maxOffset:NSNotFound axis:XPAxisDescendantOrSelf nodeTest:nodeTest filters:nil];
    [a push:step];
    [a push:_slash];
}


- (NSArray *)filtersFrom:(PKAssembly *)a {
    NSMutableArray *filters = nil;
    
    NSUInteger lastBracketMaxOffset = NSNotFound;
    
    id peek = [a pop];
    while ([peek isEqualTo:_closeBracket]) {
        XPExpression *f = [a pop];
        XPAssertExpr(f);
        
        if (!filters) {
            filters = [NSMutableArray arrayWithCapacity:2];
        }
        [filters insertObject:f atIndex:0];

        if (NSNotFound == lastBracketMaxOffset) {
            lastBracketMaxOffset = [(PKToken *)peek offset] + 1;
        }
        
        peek = [a pop];
    }
    [a push:peek];
    [a push:@(lastBracketMaxOffset)];
    
    return filters;
}


- (XPStep *)stepWithStartOffset:(NSUInteger)startOffset maxOffset:(NSUInteger)maxOffset axis:(XPAxis)axis nodeTest:(XPNodeTest *)nodeTest filters:(NSArray *)filters {
    XPStep *step = [[[XPStep alloc] initWithAxis:axis nodeTest:nodeTest] autorelease];
    for (XPExpression *f in filters) {
        [step addFilter:f];
    }

    if (NSNotFound == maxOffset) {
        maxOffset = NSMaxRange(nodeTest.range);
    }

    step.range = NSMakeRange(startOffset, maxOffset - startOffset);
    XPAssert(NSNotFound != step.range.location);
    XPAssert(NSNotFound != step.range.length);
    XPAssert(step.range.length);
    return step;
}


- (void)parser:(PKParser *)p didMatchExplicitAxisStep:(PKAssembly *)a {
    
    NSArray *filters = [self filtersFrom:a];
    NSUInteger maxOffset = [[a pop] unsignedIntegerValue];

    XPNodeTest *nodeTest = [a pop];
    XPAssert([nodeTest isKindOfClass:[XPNodeTest class]]);
    
    PKToken *axisTok = [a pop];
    XPAssertToken(axisTok);
    
    XPAxis axis;
    if ([axisTok isEqualTo:_atAxis]) {
        axis = XPAxisAttribute;
    } else {
        axis = XPAxisForName(axisTok.stringValue);
    }
    
    if ([nodeTest isKindOfClass:[XPNameTest class]] && XPNodeTypePI != nodeTest.nodeType) {
        nodeTest.nodeType = XPAxisPrincipalNodeType[axis];
    }
    
    XPStep *step = [self stepWithStartOffset:axisTok.offset maxOffset:maxOffset axis:axis nodeTest:nodeTest filters:filters];
    [a push:step];
}


- (void)parser:(PKParser *)p didMatchImplicitAxisStep:(PKAssembly *)a {

    NSArray *filters = [self filtersFrom:a];
    NSUInteger maxOffset = [[a pop] unsignedIntegerValue];

    XPNodeTest *nodeTest = [a pop];
    XPAssert([nodeTest isKindOfClass:[XPNodeTest class]]);

    XPAxis axis = XPAxisChild;
    
    if ([nodeTest isKindOfClass:[XPNameTest class]] && XPNodeTypePI != nodeTest.nodeType) {
        nodeTest.nodeType = XPAxisPrincipalNodeType[axis];
    }

    XPStep *step = [self stepWithStartOffset:nodeTest.range.location maxOffset:maxOffset axis:axis nodeTest:nodeTest filters:filters];
    [a push:step];
}


- (void)parser:(PKParser *)p didMatchAbbreviatedStep:(PKAssembly *)a {
    PKToken *dotTok = [a pop];
    
    XPAxis axis;
    NSUInteger len;
    if ([dotTok.stringValue isEqualToString:@"."]) {
        axis = XPAxisSelf;
        len = 1;
    } else {
        XPAssert([dotTok.stringValue isEqualToString:@".."])
        axis = XPAxisParent;
        len = 2;
    }
    
    XPNodeTest *nodeTest = [[[XPNodeTypeTest alloc] initWithNodeType:XPNodeTypeNode] autorelease];
    nodeTest.range = NSMakeRange(dotTok.offset, len);
    XPStep *step = [self stepWithStartOffset:dotTok.offset maxOffset:NSNotFound axis:axis nodeTest:nodeTest filters:nil];
    [a push:step];
}


- (void)parser:(PKParser *)p didMatchTypeTest:(PKAssembly *)a {
    PKToken *closeParenTok = [a pop];
    XPAssert([closeParenTok.stringValue isEqualToString:@")"]);
    
    PKToken *typeTok = [a pop];
    XPAssertToken(typeTok);
    XPAssert(_nodeTypeTab);
    XPNodeType type = [_nodeTypeTab[typeTok.stringValue] unsignedIntegerValue];
    XPAssert(XPNodeTypeNone != type);
    XPNodeTypeTest *typeTest = [[[XPNodeTypeTest alloc] initWithNodeType:type] autorelease];

    NSUInteger offset = typeTok.offset;
    typeTest.range = NSMakeRange(offset, (closeParenTok.offset+1) - offset);

    [a push:typeTest];
}


- (void)parser:(PKParser *)p didMatchSpecificPITest:(PKAssembly *)a {
    PKToken *closeParenTok = [a pop];
    XPAssert([closeParenTok.stringValue isEqualToString:@")"]);
    
    NSString *localName = [p popQuotedString];
    XPAssert([localName isKindOfClass:[NSString class]]);
    
    PKToken *typeTok = [a pop];
    XPAssert([typeTok.stringValue isEqualToString:@"processing-instruction"]);
    
    XPNameTest *nameTest = [[[XPNameTest alloc] initWithNamespaceURI:@"" localName:localName] autorelease];
    nameTest.nodeType = XPNodeTypePI;
    
    NSUInteger offset = typeTok.offset;
    nameTest.range = NSMakeRange(offset, (closeParenTok.offset+1) - offset);
    
    [a push:nameTest];
}


- (void)parser:(PKParser *)p didMatchNameTest:(PKAssembly *)a {
    PKToken *nameTok = [a pop];
    XPAssertToken(nameTok);
    
    NSString *localName = nameTok.stringValue;
    NSRange localRange = NSMakeRange(nameTok.offset, [localName length]);
    NSRange range = localRange;
    
    NSString *nsURI = @"";
    id peek = [a pop];
    if ([_colon isEqualTo:peek]) {
        PKToken *prefixTok = [a pop];
        XPAssertToken(prefixTok);
        NSString *prefix = prefixTok.stringValue;
        
        if ([prefix isEqualToString:@"*"]) {
            nsURI = prefix;
        } else {
            NSError *err = nil;
            nsURI = [_env namespaceURIForPrefix:prefix error:&err];
            if (err) {
                PKRecognitionException *rex = [[[PKRecognitionException alloc] init] autorelease];
                rex.range = NSMakeRange(prefixTok.offset, [prefix length]);
                rex.currentName = @"Missing XPath namespace";
                rex.currentReason = [err localizedFailureReason];
                [rex raise];
            }
        }
        
        NSRange prefixRange = NSMakeRange(prefixTok.offset, [prefixTok.stringValue length]);
        NSUInteger offset = prefixRange.location;
        range = NSMakeRange(offset, NSMaxRange(localRange) - offset);
    } else {
        [a push:peek];
    }
    XPNameTest *nameTest = [[[XPNameTest alloc] initWithNamespaceURI:nsURI localName:localName] autorelease];
    
    XPAssert(NSNotFound != range.location);
    XPAssert(NSNotFound != range.length);
    XPAssert(range.length);
    nameTest.range = range;
    [a push:nameTest];
}


- (void)parser:(PKParser *)p didMatchMinusUnionExpr:(PKAssembly *)a {
    XPValue *val = [a pop];
    PKToken *tok = [a pop];
    XPAssert([tok.stringValue isEqualToString:@"-"]);

    BOOL isNegative = NO;
    NSUInteger offset = NSNotFound;
    while ([tok.stringValue isEqualToString:@"-"]) {
        offset = tok.offset;
        isNegative = !isNegative;
        tok = [a pop];
    }
    [a push:tok]; // put that last one back, fool
    
    double d = [val asNumber];
    if (isNegative) d = -d;
    
    XPExpression *numExpr = [XPNumericValue numericValueWithNumber:d];
    XPAssert(NSNotFound != offset);
    numExpr.range = NSMakeRange(offset, NSMaxRange(val.range));
    [a push:numExpr];
}


- (void)parser:(PKParser *)p didMatchNumber:(PKAssembly *)a {
    PKToken *tok = [a pop];
    XPExpression *numExpr = [XPNumericValue numericValueWithNumber:tok.doubleValue];
    numExpr.range = NSMakeRange(tok.offset, [tok.stringValue length]);
    [a push:numExpr];
}


- (void)parser:(PKParser *)p didMatchLiteral:(PKAssembly *)a {
    PKToken *tok = [a pop];
    NSString *s = tok.stringValue;
    NSUInteger len = [s length];
    
    if (len) {
        unichar c = [s characterAtIndex:0];
        NSCharacterSet *set = _singleQuoteCharSet;
        if ('"' == c) {
            set = _doubleQuoteCharSet;
        }
        s = [s stringByTrimmingCharactersInSet:set];
    }

    XPExpression *strExpr = [XPStringValue stringValueWithString:s];
    strExpr.range = NSMakeRange(tok.offset, len);
    [a push:strExpr];
}

@end
