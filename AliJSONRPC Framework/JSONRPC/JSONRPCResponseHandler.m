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

#import "JSONRPCResponseHandler.h"
#import "JSON.h"

#import "JSONRPCMethodCall.h"
#import "JSONRPCService.h"
#import "JSONRPC_Extensions.h"

//! @private Private API @internal
@interface JSONRPCResponseHandler()
-(id)objectFromJson:(id)jsonObject; //!< @private @internal
-(void)forwardConnectionError:(NSError*)error; //!< @private @internal
@end

@implementation JSONRPCResponseHandler
@synthesize methodCall = _methodCall;
@synthesize delegate = _delegate;
@synthesize callback = _callbackSelector;

@synthesize resultClass = _resultClass;
@synthesize maxRetryAttempts = _maxRetryAttempts, delayBeforeRetry = delayBeforeRetry;

- (id) init
{
	self = [super init];
	if (self != nil) {
		_maxRetryAttempts = 2;
		_delayBeforeRetry = 0.5;
	}
	return self;
}


-(void)setDelegate:(id<NSObject>)aDelegate callback:(SEL)callback
{
	self.delegate = aDelegate;
	self.callback = callback;
	if (![aDelegate respondsToSelector:callback]) {
		NSLog(@"%@ warning: %@ does not respond to selector %@",[self class],aDelegate,NSStringFromSelector(callback));
	}
}
-(void)setDelegate:(id<NSObject>)aDelegate callback:(SEL)callback resultClass:(Class)cls {
	[self setDelegate:aDelegate callback:callback];
	self.resultClass = cls;
}

#if NS_BLOCKS_AVAILABLE
-(void)completion:(void(^)(JSONRPCMethodCall* methodCall,id result,NSError* error))completionBlock {
	_completionBlock = [completionBlock copy];
}
-(void)completion:(void(^)(JSONRPCMethodCall* methodCall,id result,NSError* error))completionBlock resultClass:(Class)cls {
	[self completion:completionBlock];
	self.resultClass = cls;
}
#endif

-(void)dealloc {
	[_methodCall release];
	[_delegate release];
	[_completionBlock release];
	[super dealloc];
}

/////////////////////////////////////////////////////////////////////////////

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	[_receivedData release];
	_receivedData = [[NSMutableData alloc] init];
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_receivedData appendData:data];
}

-(void)retryRequest {
	--_maxRetryAttempts;
	if (_delegate && [_delegate respondsToSelector:@selector(methodCallIsRetrying:)]) {
		[(id<JSONRPCDelegate>)_delegate methodCallIsRetrying:self.methodCall];
	}
	[self.methodCall.service callMethod:self.methodCall reuseResponseHandler:self];
}

- (void)forwardConnectionError:(NSError*)error {
	SEL errSel = @selector(methodCall:shouldForwardConnectionError:);
	BOOL cont = YES;
	if (_delegate && [_delegate respondsToSelector:errSel]) {
		cont = [(id<JSONRPCDelegate>)_delegate methodCall:self.methodCall shouldForwardConnectionError:error];
	}
	if (cont)
	{
		id<JSONRPCDelegate> del = self.methodCall.service.delegate;
		if (del && [del respondsToSelector:errSel]) {
			cont = [del methodCall:self.methodCall shouldForwardConnectionError:error];
		}
		(void)cont; // UNUSED AFTER THAT
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[_receivedData release];
	_receivedData = nil;

	BOOL networkDomain = ( ([error domain] == NSURLErrorDomain) /* || ([error domain] == (NSString*)kCFErrorDomainCFNetwork) */ );
	if ( networkDomain /* && ([error code]==NSURLErrorNetworkConnectionLost) */ && (_maxRetryAttempts>0)) {
		// Retry
		NSLog(@"Connection lost. Retrying call to %@ (TTL=%d).",self.methodCall.methodName,_maxRetryAttempts);
		if (_delegate && [_delegate respondsToSelector:@selector(methodCall:willRetryAfterError:)]) {
			[(id<JSONRPCDelegate>)_delegate methodCall:self.methodCall willRetryAfterError:error];
		}
		[self performSelector:@selector(retryRequest) withObject:nil afterDelay:_delayBeforeRetry];
	} else {
		[self forwardConnectionError:error];
	}
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	NSError* jsonParsingError = nil;
	NSString* jsonStr = [[[NSString alloc] initWithData:_receivedData encoding:NSUTF8StringEncoding] autorelease];
	SBJSON* parser = [[SBJSON alloc] init];
	id respObj = [parser objectWithString:jsonStr error:&jsonParsingError];
	[parser release];

	[_receivedData release];
	_receivedData = nil;

	if (jsonParsingError) {
		// raise an error regarding JSON Parsing
		NSMutableDictionary* verboseUserInfo = [NSMutableDictionary dictionaryWithDictionary:[jsonParsingError userInfo]];
		[verboseUserInfo setObject:jsonStr?:@"" forKey:JSONRPCErrorJSONObjectKey];
		[self forwardConnectionError:[NSError errorWithDomain:[jsonParsingError domain] code:[jsonParsingError code] userInfo:verboseUserInfo]];
	} else {
		// extract result from JSON response
		if (![respObj isKindOfClass:[NSDictionary class]]) {
			NSString* locDesc = [[NSBundle mainBundle] localizedStringForKey:@"JSONRPCFormatErrorString" value:JSONRPCFormatErrorString table:nil];
			NSLog(@"[JSON-RPC] %@",locDesc);
			NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									  respObj,JSONRPCErrorJSONObjectKey,
									  locDesc,NSLocalizedDescriptionKey,
									  nil];
			[self forwardConnectionError:[NSError errorWithDomain:JSONRPCInternalErrorDomain code:JSONRPCFormatErrorCode userInfo:userInfo]];
			return;
		}
		
		id resultJsonObject = [respObj objectForKey:@"result"];
		if (resultJsonObject == [NSNull null]) resultJsonObject = nil;
		id parsedResult = resultJsonObject;
		if (resultJsonObject && _resultClass) {
			// decode object as expected Class
			parsedResult = [self objectFromJson:resultJsonObject];
			if (!parsedResult) {
				// raise and error regarding conversion (send to _delegate or fallback to service)
				NSString* locDesc = [[NSBundle mainBundle] localizedStringForKey:@"JSONRPCConversionErrorString" value:JSONRPCConversionErrorString table:nil];
				NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
										  resultJsonObject,JSONRPCErrorJSONObjectKey,
										  locDesc,NSLocalizedDescriptionKey,
										  NSStringFromClass(_resultClass),JSONRPCErrorClassNameKey,
										  nil];
				[self forwardConnectionError:[NSError errorWithDomain:JSONRPCInternalErrorDomain code:JSONRPCConversionErrorCode userInfo:userInfo]];
				return;
			}
		}
		
		// extract error from JSON response
		id errorJsonObject  = [respObj objectForKey:@"error"];
		if (errorJsonObject == [NSNull null]) errorJsonObject = nil;
		NSError* parsedError = nil;
		if (errorJsonObject) {
			parsedError = [NSError errorWithDomain:JSONRPCServerErrorDomain
											  code:[[errorJsonObject objectForKey:@"code"] longValue]
										  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
													[errorJsonObject objectForKey:@"message"]?:@"",NSLocalizedDescriptionKey,
													errorJsonObject,JSONRPCErrorJSONObjectKey,
													nil]];
		}
		if (parsedError) {
			// Send notification for anyone interested
			NSDictionary* notifUserInfo = [NSDictionary dictionaryWithObject:parsedError forKey:JSONRPCErrorJSONObjectKey];
			[[NSNotificationCenter defaultCenter] postNotificationName:JSONRPCServerErrorNotification
																object:self
															  userInfo:notifUserInfo];
		}

		JSONRPCMethodCall* methCall = self.methodCall;
		if (_completionBlock) {
			_completionBlock(methCall,parsedResult,parsedError);
		} else {
			NSObject<JSONRPCDelegate>* realDelegate = _delegate ?: methCall.service.delegate;
			SEL realSel = _callbackSelector ?: @selector(methodCall:didReturn:error:);

			if (realDelegate && [realDelegate respondsToSelector:realSel]) {
				NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[realDelegate methodSignatureForSelector:realSel]];
				[inv setSelector:realSel];
				[inv setArgument:&methCall atIndex:2];
				[inv setArgument:&parsedResult atIndex:3];
				[inv setArgument:&parsedError atIndex:4];
				[inv invokeWithTarget:realDelegate];
			} else {
				NSLog(@"warning: JSONRPCResponseHandler did receive a response but no delegate defined: the response has been ignored"); 
			}
		}
	}	
}

-(id)objectFromJson:(id)jsonObject {
	//if ([_resultConvertionClass instancesRespondToSelector:@selector(initWithJson:)])
	{
		if ([jsonObject isKindOfClass:[NSArray class]]) {
			// Convert each object in the NSArray
			return [NSArray arrayWithJson:jsonObject itemsClass:_resultClass];
		} else {
			// not an NSArray
			return [[[_resultClass alloc] initWithJson:jsonObject] autorelease];
		}
	}
}
@end



