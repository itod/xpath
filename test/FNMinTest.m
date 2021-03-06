//
//  FNMinTest.m
//  Panthro
//
//  Created by Todd Ditchendorf on 7/20/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "XPTestScaffold.h"

@interface FNMinTest : XCTestCase
@property (nonatomic, retain) XPExpression *expr;
@property (nonatomic, retain) XPFunction *fn;
@property (nonatomic, assign) double res;
@end

@implementation FNMinTest

- (void)setUp {
    
}


- (void)testErrors {
    NSError *err = nil;
    [XPExpression expressionFromString:@"min()" inContext:[XPStandaloneContext standaloneContext] error:&err];
    TDNotNil(err);

    [XPExpression expressionFromString:@"min('1', '2')" inContext:[XPStandaloneContext standaloneContext] error:&err];
    TDNotNil(err);
}


- (void)testNumbers {
    self.expr = [XPExpression expressionFromString:@"min((0))" inContext:[XPStandaloneContext standaloneContext] error:nil];
    self.res = [_expr evaluateAsNumberInContext:nil];
    TDEquals(0.0, _res);
    
    self.expr = [XPExpression expressionFromString:@"min((-1))" inContext:[XPStandaloneContext standaloneContext] error:nil];
    self.res = [_expr evaluateAsNumberInContext:nil];
    TDEquals(-1.0, _res);
    
    self.expr = [XPExpression expressionFromString:@"min((1))" inContext:[XPStandaloneContext standaloneContext] error:nil];
    self.res = [_expr evaluateAsNumberInContext:nil];
    TDEquals(1.0, _res);
    
    self.expr = [XPExpression expressionFromString:@"min((1, 2))" inContext:[XPStandaloneContext standaloneContext] error:nil];
    self.res = [_expr evaluateAsNumberInContext:nil];
    TDEquals(1.0, _res);
    
    self.expr = [XPExpression expressionFromString:@"min((0, 1, 2))" inContext:[XPStandaloneContext standaloneContext] error:nil];
    self.res = [_expr evaluateAsNumberInContext:nil];
    TDEquals(0.0, _res);
    
    self.expr = [XPExpression expressionFromString:@"min((1, 2, 0))" inContext:[XPStandaloneContext standaloneContext] error:nil];
    self.res = [_expr evaluateAsNumberInContext:nil];
    TDEquals(0.0, _res);
    
    self.expr = [XPExpression expressionFromString:@"min((1, -2))" inContext:[XPStandaloneContext standaloneContext] error:nil];
    self.res = [_expr evaluateAsNumberInContext:nil];
    TDEquals(-2.0, _res);
    
    self.expr = [XPExpression expressionFromString:@"min((1, -2, 0))" inContext:[XPStandaloneContext standaloneContext] error:nil];
    self.res = [_expr evaluateAsNumberInContext:nil];
    TDEquals(-2.0, _res);
    
    self.expr = [XPExpression expressionFromString:@"min((1.1, -2, 0.0))" inContext:[XPStandaloneContext standaloneContext] error:nil];
    self.res = [_expr evaluateAsNumberInContext:nil];
    TDEquals(-2.0, _res);
    
    self.expr = [XPExpression expressionFromString:@"min((1.1, -2.0, 0.0))" inContext:[XPStandaloneContext standaloneContext] error:nil];
    self.res = [_expr evaluateAsNumberInContext:nil];
    TDEquals(-2.0, _res);
    
    self.expr = [XPExpression expressionFromString:@"min((1, 2, number('')))" inContext:[XPStandaloneContext standaloneContext] error:nil];
    self.res = [_expr evaluateAsNumberInContext:nil];
    TDTrue(isnan(_res));
    
    self.expr = [XPExpression expressionFromString:@"min((0, 1, 2, number('')))" inContext:[XPStandaloneContext standaloneContext] error:nil];
    self.res = [_expr evaluateAsNumberInContext:nil];
    TDTrue(isnan(_res));
    
    self.expr = [XPExpression expressionFromString:@"min((-5, 0, 1, 2, number('')))" inContext:[XPStandaloneContext standaloneContext] error:nil];
    self.res = [_expr evaluateAsNumberInContext:nil];
    TDTrue(isnan(_res));
}


- (void)testEmpty {
    self.expr = [XPExpression expressionFromString:@"min(())" inContext:[XPStandaloneContext standaloneContext] error:nil];
    id res = [_expr evaluateAsSequenceInContext:nil];
    TDEquals(0.0, [res count]);
}


- (void)testStrings {
    self.expr = [XPExpression expressionFromString:@"min(('foo'))" inContext:[XPStandaloneContext standaloneContext] error:nil];
    self.res = [_expr evaluateAsNumberInContext:nil];
    TDTrue(isnan(_res));
    
    self.expr = [XPExpression expressionFromString:@"min(('foo', 'bar'))" inContext:[XPStandaloneContext standaloneContext] error:nil];
    self.res = [_expr evaluateAsNumberInContext:nil];
    TDTrue(isnan(_res));
}

@end
