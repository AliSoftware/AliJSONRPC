//
//  MyService.h
//  JSONRPCExample
//
//  Created by Olivier on 04/05/10.
//  Copyright 2010 AliSoftware. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "JSONRPC.h"
#import "MyTypes.h"

@interface MyWebService : NSObject <JSONRPCDelegate> {
	JSONRPCService* service;
}
+ (MyWebService*)defaultService;

// -(void)methodCall:(JSONRPCMethodCall*)mc didReturnAuthor:(Person*)user error:(NSError*)error;
-(void)getAuthorWithDelegate:(id)delegate callback:(SEL)callback;

// -(void)methodCall:(JSONRPCMethodCall*)mc didReturnCouple:(Couple*)user error:(NSError*)error;
-(void)getCoupleWithDelegate:(id)delegate callback:(SEL)callback;

// -(void)methodCall:(JSONRPCMethodCall*)mc didReturnSum:(NSNumber*)user error:(NSError*)error;
-(void)addValue:(int)val1 withValue:(int)val2 delegate:(id)delegate callback:(SEL)callback;

// -(void)methodCall:(JSONRPCMethodCall*)mc didReturnSum:(NSNumber*)user error:(NSError*)error;
-(void)getSumOfValues:(NSArray*)values delegate:(id)delegate callback:(SEL)callback;

// -(void)methodCall:(JSONRPCMethodCall*)mc didReturnDef:(ServiceDef*)def error:(NSError*)error;
-(void)getServiceDescriptionWithDelegate:(id)delegate callback:(SEL)callback;
@end

