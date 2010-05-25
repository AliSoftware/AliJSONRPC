//
//  JSONRPCService.m
//  JSONRPC
//
//  Created by Olivier on 01/05/10.
//  Copyright 2010 AliSoftware. All rights reserved.
//

#import "JSONRPCService.h"
#import "JSON.h"

#import "JSONRPCMethodCall.h"
#import "JSONRPCResponseHandler.h"

NSString* const JSONRPCServerErrorDomain = @"JSONRPCServerError";
NSString* const JSONRPCInternalErrorDomain = @"JSONRPCInternalError";
NSString* const JSONRPCErrorDataKey = @"data";
NSString* const JSONRPCErrorClassNameKey = @"className";
NSInteger const JSONRPCConversionErrorCode = 10;

/////////////////////////////////////////////////////////////////////////////

@implementation JSONRPCService
@synthesize serviceURL = _serviceURL;
@synthesize delegate;

-(id)proxy {
	return [[[JSONRPCServiceProxy alloc] initWithService:self] autorelease];	
}


/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: Init/Dealloc
/////////////////////////////////////////////////////////////////////////////


+(id)serviceWithURL:(NSURL*)url
{
	return [[[JSONRPCService alloc] initWithURL:url] autorelease];
}

- (id) initWithURL:(NSURL*)url
{
	self = [super init];
	if (self != nil) {
		_serviceURL = [url retain];
	}
	return self;
}


-(NSString*)description {
	return [NSString stringWithFormat:@"<%@ %@>",NSStringFromClass([self class]),self.serviceURL];
}

-(void)dealloc
{
	[_serviceURL release];
	[super dealloc];
}



/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: Call a RPC method
/////////////////////////////////////////////////////////////////////////////

- (JSONRPCResponseHandler*)callMethod:(JSONRPCMethodCall*)methodCall
{
	NSString* jsonStr = [[methodCall proxyForJson] JSONRepresentation];
	
	NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:self.serviceURL];
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:[jsonStr dataUsingEncoding:NSUTF8StringEncoding]];
	[req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	
	JSONRPCResponseHandler* d = [[[JSONRPCResponseHandler alloc] init] autorelease];
	d.methodCall = methodCall;
	d.methodCall.service = self;
	[NSURLConnection connectionWithRequest:req delegate:d];
	return d;
	
}

- (JSONRPCResponseHandler*)callMethodWithName:(NSString *)methodName parameters:(NSArray*)params
{
	return [self callMethod:[JSONRPCMethodCall methodCallWithMethodName:methodName parameters:params]];
}

- (JSONRPCResponseHandler*)callMethodWithNameAndParams:(NSString *)methodName, ...
{
	va_list ap;
	va_start(ap, methodName);
	JSONRPCMethodCall* mCall = [[[JSONRPCMethodCall alloc] initWithMethodName:methodName parametersList:ap notifyOnly:NO] autorelease];
	JSONRPCResponseHandler* ret = [self callMethod:mCall];
	va_end(ap);
	
	return ret;
}

- (void)sendNotificationWithName:(NSString *)methodName parameters:(NSArray*)params
{
	JSONRPCMethodCall* mCall = [[[JSONRPCMethodCall alloc] initWithMethodName:methodName parameters:params notifyOnly:YES] autorelease];
	[self callMethod:mCall];
}



@end




@implementation JSONRPCService_v2_0
- (JSONRPCResponseHandler*)callMethodWithName:(NSString *)methodName namedParameters:(NSDictionary*)params
{
	return [self callMethod:[JSONRPCMethodCall_v2_0 methodCallWithMethodName:methodName namedParameters:params]];
}
- (JSONRPCResponseHandler*)callMethodWithNameAndNamedParams:(NSString *)methodName, ... 
{
	va_list ap;
	va_start(ap,methodName);
	JSONRPCMethodCall_v2_0* mCall = [[[JSONRPCMethodCall_v2_0 alloc] initWithMethodName:methodName namedParametersList:ap notifyOnly:NO] autorelease];
	JSONRPCResponseHandler* ret = [self callMethod:mCall];
	va_end(ap);
	return ret;
}
- (void)sendNotificationWithName:(NSString *)methodName namedParameters:(NSDictionary*)params
{
	[self callMethod:[JSONRPCMethodCall_v2_0 notificationWithName:methodName namedParameters:params]];
}
- (void)sendNotificationWithNameAndNamedParams:(NSString *)methodName, ... {
	va_list ap;
	va_start(ap,methodName);
	JSONRPCResponseHandler* ret = [self callMethod:[[[JSONRPCMethodCall_v2_0 alloc] initWithMethodName:methodName namedParametersList:ap notifyOnly:YES] autorelease]];
	va_end(ap);
	(void)ret;	//ignore result
}
@end






/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: JSONRPC Service Proxy
/////////////////////////////////////////////////////////////////////////////

@implementation JSONRPCServiceProxy
@synthesize service = _service;
- (id) initWithService:(JSONRPCService*)service
{
	_service = service;
	return self;
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
	NSMethodSignature *ret = nil;
	if (! (ret = [_service methodSignatureForSelector:aSelector])) { 
		NSString* mName = [NSString stringWithUTF8String:sel_getName(aSelector)];
		NSArray* parts = [mName componentsSeparatedByString:@":"];
		int nArgs = [parts count] - 1;
		if (nArgs==0) {
			// -(id self,SEL _cmd, NSString* methodName)
			ret = [NSMethodSignature signatureWithObjCTypes:"@:@"];
		} else if (nArgs==1) {
			// -(id self,SEL _cmd, NSString* methodName , NSArray* args)
			ret = [NSMethodSignature signatureWithObjCTypes:"@:@@"];
		} else {
			return nil;
		}
	}
	return ret;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	NSString* methodName = [[NSString stringWithUTF8String:sel_getName([anInvocation selector])]
							stringByReplacingOccurrencesOfString:@":" withString:@""];
	
	id params = nil;
	int nbArgs = [[anInvocation methodSignature] numberOfArguments];
	if (nbArgs>2) [anInvocation getArgument:&params atIndex:2];
	if (!params || [params isKindOfClass:[NSArray class]])
	{
		JSONRPCResponseHandler* d = [_service callMethodWithName:methodName parameters:params];
		[anInvocation setReturnValue:&d];
	} else {
		[super forwardInvocation:anInvocation];
	}
}

@end
