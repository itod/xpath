//
//  XPStandaloneContext.m
//  Panthro
//
//  Created by Todd Ditchendorf on 5/4/14.
//
//

#import "XPStandaloneContext.h"
#import "XPUtils.h"

#import "XPSync.h"
#import "XPContext.h"
#import "XPExpression.h"

#import "XPNSXMLNodeImpl.h"
#import "XPLibxmlNodeImpl.h"

NSString * const XPNamespaceXML = @"http://www.w3.org/XML/1998/namespace";
NSString * const XPNamespaceXSLT = @"http://www.w3.org/1999/XSL/Transform";

@interface XPStandaloneContext ()
@property (nonatomic, retain) NSMutableDictionary *vars;
@end

@implementation XPStandaloneContext

+ (instancetype)standaloneContext {
    return [[[self alloc] init] autorelease];
}


- (instancetype)init {
    self = [super init];
    if (self) {
        self.vars = [NSMutableDictionary dictionary];
        self.namespaces = [NSMutableDictionary dictionary];
        self.debugSync = [XPSync sync];

		[self declareNamespaceURI:XPNamespaceXML forPrefix:@"xml"];
		[self declareNamespaceURI:XPNamespaceXSLT forPrefix:@"xsl"];
        [self declareNamespaceURI:@"" forPrefix:@""];
    }
    return self;
}


- (void)dealloc {
    self.vars = nil;
    self.namespaces = nil;
    self.debugSync = nil;
    [super dealloc];
}


- (XPExpression *)compile:(NSString *)xpathStr withContextNode:(id <XPNodeInfo>)ctxNode error:(NSError **)outErr {
    NSParameterAssert([xpathStr length]);
    NSParameterAssert(ctxNode);
    
    XPExpression *result = nil;
    NSError *err = nil;
    
    @autoreleasepool {
        result = [XPExpression expressionFromString:xpathStr inContext:self error:&err];
        
        [result retain]; // +1 to survive autorelase pool drain
        [err retain]; // +1 to survive autorelase pool drain
    }
    
    if (outErr) {
        *outErr = err;
    }
    
    [err autorelease]; // -1 to balance
    return [result autorelease]; // -1 to balance
}


- (id)evaluate:(XPExpression *)expr withContextNode:(id <XPNodeInfo>)ctxNode error:(NSError **)outErr {
    NSParameterAssert(expr);
    NSParameterAssert(ctxNode);
    
    id result = nil;
    NSError *err = nil;
    
    @autoreleasepool {
        XPContext *ctx = [[[XPContext alloc] initWithStaticContext:self] autorelease];
        ctx.contextNode = ctxNode;
        
        @try {
            result = [expr evaluateInContext:ctx];
        } @catch (NSException *ex) {
            result = nil;
            err = [NSError errorWithDomain:XPathErrorDomain code:XPathErrorCodeRuntime userInfo:[ex userInfo]];
        }
        
        [result retain]; // +1 to survive autorelase pool drain
        [err retain]; // +1 to survive autorelase pool drain
    }
    
    if (outErr) {
        *outErr = err;
    }
    
    [err autorelease]; // -1 to balance
    return [result autorelease]; // -1 to balance
}


- (id)execute:(NSString *)xpathStr withNSXMLContextNode:(NSXMLNode *)nsxmlCtxNode error:(NSError **)outErr {
    id <XPNodeInfo>ctxNode = [XPNSXMLNodeImpl nodeInfoWithNode:nsxmlCtxNode];
    return [self execute:xpathStr withContextNode:ctxNode error:outErr];
}


- (id)execute:(NSString *)xpathStr withLibxmlContextNode:(void *)libxmlCtxNode parserContext:(xmlParserCtxtPtr)parserCtx error:(NSError **)outErr;{
    id <XPNodeInfo>ctxNode = [XPLibxmlNodeImpl nodeInfoWithNode:libxmlCtxNode parserContext:parserCtx];
    return [self execute:xpathStr withContextNode:ctxNode error:outErr];
}


- (id)execute:(NSString *)xpathStr withContextNode:(id <XPNodeInfo>)ctxNode error:(NSError **)outErr {
    XPExpression *expr = [self compile:xpathStr withContextNode:ctxNode error:outErr];
    id result = nil;
    if (expr) {
        result = [self evaluate:expr withContextNode:ctxNode error:outErr];
    }
    return result;
}


/**
 * Declare a namespace whose prefix can be used in expressions
 */
    
- (void)declareNamespaceURI:(NSString *)uri forPrefix:(NSString *)prefix {
    NSParameterAssert(uri);
    NSParameterAssert(prefix);
    XPAssert(_namespaces);
    _namespaces[prefix] = uri;
}
    

/**
 * Get the system ID of the container of the expression
 * @return "" always
 */
    
- (NSString *)systemId {
    return @"";
}


/**
 * Get the Base URI of the stylesheet element, for resolving any relative URI's used
 * in the expression.
 * Used by the document() function.
 * @return "" always
 */
    
- (NSString *)baseURI {
    return @"";
}


/**
 * Get the line number of the expression within that container
 * @return -1 always
 */
    
- (NSUInteger)lineNumber {
    return NSNotFound;
}


/**
 * Get the URI for a prefix, using this Element as the context for namespace resolution
 * @param prefix The prefix
 * @throw XPathException if the prefix is not declared
 */
    
- (NSString *)namespaceURIForPrefix:(NSString *)prefix {
    NSParameterAssert(prefix);
    XPAssert(_namespaces);
    
    NSString *uri = _namespaces[prefix];
    if (!uri) {
        [NSException raise:@"XPathException" format:@"Prefix %@ has not been declared", prefix];
    }

    return uri;
}


/**
 * Determine if an extension element is available
 */
    
- (BOOL)isElementAvailable:(NSString *)qname {
    return NO;
}


/**
 * Determine if a function is available
 */
    
- (BOOL)isFunctionAvailable:(NSString *)qname {
    
    NSString *prefix = XPNameGetPrefix(qname);
    if (![prefix length]) {
        return nil != [XPExpression makeSystemFunction:qname];
    }
    
    return NO;   // no user functions allowed in standalone context.
}


/**
 * Get the effective XSLT version in this region of the stylesheet
 */

- (NSString *)version {
    return @"1.1";
}


- (void)setValue:(XPValue *)val forVariable:(NSString *)name {
    NSParameterAssert(val);
    NSParameterAssert(name);
    XPAssert(_vars);
    
    [_vars setObject:val forKey:name];
}


- (XPValue *)valueForVariable:(NSString *)name {
    NSParameterAssert(name);
    XPAssert(_vars);
    
    return [_vars objectForKey:name];
}

@end
