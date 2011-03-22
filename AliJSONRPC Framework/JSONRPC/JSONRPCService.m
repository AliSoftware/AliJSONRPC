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
NSString* const JSONRPCServerErrorNotification = @"JSONRPCServerErrorNotification";
NSString* const JSONRPCInternalErrorDomain = @"JSONRPCInternalError";
NSString* const JSONRPCErrorJSONObjectKey = @"JSONObject";
NSString* const JSONRPCErrorClassNameKey = @"className";
NSInteger const JSONRPCFormatErrorCode = 8;
NSString* const JSONRPCFormatErrorString = @"Server JSON-RPC response invalid : expected dictionary ({id,result,error})";
NSInteger const JSONRPCConversionErrorCode = 10;
NSString* const JSONRPCConversionErrorString = @"Error while converting received JSON data to requested resultClass";


/////////////////////////////////////////////////////////////////////////////


@implementation JSONRPCService
@synthesize serviceURL = _serviceURL;
@synthesize version = _version;
@synthesize delegate;

-(id)proxy {
	return [[[JSONRPCServiceProxy alloc] initWithService:self] autorelease];	
}


/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: Init/Dealloc
/////////////////////////////////////////////////////////////////////////////


+(id)serviceWithURL:(NSURL*)url version:(JSONRPCVersion)version
{
	return [[[JSONRPCService alloc] initWithURL:url version:version] autorelease];
}

- (id) initWithURL:(NSURL*)url  version:(JSONRPCVersion)version
{
	self = [super init];
	if (self != nil) {
		_serviceURL = [url retain];
		_version = version;
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

- (JSONRPCResponseHandler*)callMethod:(JSONRPCMethodCall*)methodCall {
	return [self callMethod:methodCall reuseResponseHandler:nil];
}
- (JSONRPCResponseHandler*)callMethod:(JSONRPCMethodCall*)methodCall reuseResponseHandler:(JSONRPCResponseHandler*)responseHandler
{
	methodCall.service = self;
	NSString* jsonStr = [[methodCall proxyForJson] JSONRepresentation];
	
	if ((self.version<JSONRPCVersion_1_1) && ([methodCall.parameters isKindOfClass:[NSDictionary class]])) {
		NSLog(@"JSON-RPC: warning: named parameters are only supported by JSON-RPC Service version 1.1 or higher");
	}
	
	NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:self.serviceURL];
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:[jsonStr dataUsingEncoding:NSUTF8StringEncoding]];
	[req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	
	JSONRPCResponseHandler* d = responseHandler ?: [[[JSONRPCResponseHandler alloc] init] autorelease];
	d.methodCall = methodCall;
	[NSURLConnection connectionWithRequest:req delegate:d];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	return d;
	
}

// MARK: -

- (JSONRPCResponseHandler*)callMethodWithName:(NSString *)methodName parameters:(NSArray*)params
{
	return [self callMethod:[JSONRPCMethodCall methodCallWithMethodName:methodName parameters:params]];
}

- (JSONRPCResponseHandler*)callMethodWithNameAndParams:(NSString *)methodName, ...
{
	va_list ap;
	va_start(ap, methodName);
	JSONRPCMethodCall* mCall = [[[JSONRPCMethodCall alloc] initWithMethodName:methodName parametersList:ap] autorelease];
	JSONRPCResponseHandler* ret = [self callMethod:mCall];
	va_end(ap);
	
	return ret;
}

- (JSONRPCResponseHandler*)callMethodWithName:(NSString *)methodName namedParameters:(NSDictionary*)params
{
	return [self callMethod:[JSONRPCMethodCall methodCallWithMethodName:methodName namedParameters:params]];
}
- (JSONRPCResponseHandler*)callMethodWithNameAndNamedParams:(NSString *)methodName, ... 
{
	va_list ap;
	va_start(ap,methodName);
	JSONRPCMethodCall* mCall = [[[JSONRPCMethodCall alloc] initWithMethodName:methodName namedParametersList:ap] autorelease];
	JSONRPCResponseHandler* ret = [self callMethod:mCall];
	va_end(ap);
	return ret;
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
	} else if ([params isKindOfClass:[NSDictionary class]]) {
		JSONRPCResponseHandler* d = [_service callMethodWithName:methodName namedParameters:params];
		[anInvocation setReturnValue:&d];
	} else {
		[super forwardInvocation:anInvocation];
	}
}

@end
