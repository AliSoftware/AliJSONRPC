/*
 Copyright (C) 2009 Olivier Halligon. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
 to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "JSONRPCService.h"
#import "JSON.h"

#import "JSONRPCMethodCall.h"
#import "JSONRPCResponseHandler.h"

NSString* const JSONRPCServerErrorDomain = @"JSONRPCServerError";
NSString* const JSONRPCInternalErrorDomain = @"JSONRPCInternalError";
NSString* const JSONRPCErrorJSONObjectKey = @"JSONObject";
NSString* const JSONRPCErrorClassNameKey = @"className";
NSInteger const JSONRPCConversionErrorCode = 10;

/////////////////////////////////////////////////////////////////////////////

@implementation NSError(JSON)
-(id)data {
	id jsonObj = [[self userInfo] objectForKey:JSONRPCErrorJSONObjectKey];
	if (jsonObj && [jsonObj isKindOfClass:[NSDictionary class]])
		return [jsonObj objectForKey:@"data"];
	else
		return nil;
}
@end


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
