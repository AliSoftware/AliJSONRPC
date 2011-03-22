//
//  MyService.m
//  JSONRPCExample
//
//  Created by Olivier on 04/05/10.
//  Copyright 2010 AliSoftware. All rights reserved.
//

#import "MyWebService.h"

#define SERVICE_URL @"http://www.raboof.com/Projects/Jayrock/Demo.ashx"

// Singleton ; allocate a JSONRPCService in its -init method

@implementation MyWebService

-(void)getAuthorWithDelegate:(id)delegate callback:(SEL)callback
{
	[[service callMethodWithNameAndParams:@"getAuthor",nil]
	 setDelegate:delegate callback:callback resultClass:[Person class]];
}

-(void)getCoupleWithDelegate:(id)delegate callback:(SEL)callback
{
	[[service callMethodWithNameAndParams:@"getCouple",nil]
	 setDelegate:delegate callback:callback resultClass:[Couple class]];
}

-(void)addValue:(int)val1 withValue:(int)val2 delegate:(id)delegate callback:(SEL)callback
{
	[[service callMethodWithNameAndParams:@"wadd",mkInt(val1),mkInt(val2),nil]
	 setDelegate:delegate callback:callback];
}

-(void)getSumOfValues:(NSArray*)values delegate:(id)delegate callback:(SEL)callback
{
	[[service callMethodWithNameAndParams:@"total",values,nil]
	 setDelegate:delegate callback:callback];
}

-(void)getServiceDescriptionWithDelegate:(id)delegate callback:(SEL)callback
{
	[[service callMethodWithNameAndParams:@"system.smd",[NSNull null],nil]
	 setDelegate:delegate callback:callback resultClass:[ServiceDef class]];
}


/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: Error fallbacks
/////////////////////////////////////////////////////////////////////////////

-(BOOL)methodCall:(JSONRPCMethodCall*)methodCall didFailWithError:(NSError*)error
{
	// Network error, Parsing JSON Response, error while post-processing JSON response to object, ...
	[[[[UIAlertView alloc] initWithTitle:@"error"
								 message:[error localizedDescription]
								delegate:nil cancelButtonTitle:nil otherButtonTitles:nil]
	  autorelease] show];
	return NO;
}







/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: Singleton Methods
/////////////////////////////////////////////////////////////////////////////

static MyWebService* _sharedInstance = nil;

+ (MyWebService*)defaultService
{
    @synchronized(self) {
        if (_sharedInstance == nil) {
            [[[self alloc] init] autorelease]; // assignment not done here
        }
    }
    return _sharedInstance;
}

- (id) init
{
	self = [super init];
	if (self != nil) {
		service = [[JSONRPCService alloc] initWithURL:[NSURL URLWithString:SERVICE_URL] version:JSONRPCVersion_1_1];
		service.delegate = self; // for errors catching
		
	}
	return self;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (_sharedInstance == nil) {
            _sharedInstance = [super allocWithZone:zone];
            return _sharedInstance;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}
-(void)dealloc { [service release]; [super dealloc]; }

- (id)copyWithZone:(NSZone *)zone { return self; }
- (id)retain { return self; }
- (unsigned)retainCount { return UINT_MAX; /* denotes an object that cannot be released */ }
- (void)release { /* do nothing */ }
- (id)autorelease { return self; }

@end
