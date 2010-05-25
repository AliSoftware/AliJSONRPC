//
//  JSONRPCDeferred.m
//  JSONRPC
//
//  Created by Olivier on 01/05/10.
//  Copyright 2010 AliSoftware. All rights reserved.
//

#import "JSONRPCResponseHandler.h"
#import "JSON.h"

#import "JSONRPCMethodCall.h"
#import "JSONRPCService.h"

//! @private Private API @internal
@interface JSONRPCResponseHandler()
-(id)objectFromJson:(id)jsonObject; //!< @private @internal
@end

@implementation JSONRPCResponseHandler
@synthesize methodCall = _methodCall;
@synthesize delegate = _delegate;
@synthesize callback = _callbackSelector;

@synthesize resultClass = _resultClass;

-(void)setDelegate:(id)aDelegate callback:(SEL)callback
{
	self.delegate = aDelegate;
	self.callback = callback;
	if (![aDelegate respondsToSelector:callback]) {
		NSLog(@"%@ warning: %@ does not respond to selector %@",[self class],aDelegate,NSStringFromSelector(callback));
	}
}
-(void)setDelegate:(id)aDelegate callback:(SEL)callback resultClass:(Class)cls {
	[self setDelegate:aDelegate callback:callback];
	self.resultClass = cls;
}

-(void)dealloc {
	[_methodCall release];
	[_delegate release];
	[super dealloc];
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	[_receivedData release];
	_receivedData = [[NSMutableData alloc] init];
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_receivedData appendData:data];
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	SEL errSel = @selector(methodCall:didFailWithError:);
	BOOL cont = YES;
	
	if (_delegate && [_delegate respondsToSelector:errSel]) {
		cont = [_delegate methodCall:self.methodCall didFailWithError:error];
	}
	if (cont)
	{
		id<JSONRPCErrorHandler> del = self.methodCall.service.delegate;
		if (del && [del respondsToSelector:errSel]) {
			cont = [del methodCall:self.methodCall didFailWithError:error];
		}
		(void)cont; // UNUSED AFTER THAT
	}
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (!self.methodCall.uuid) return; // if it was a notification, no response expected.
	
	if (!_delegate || [_delegate respondsToSelector:_callbackSelector])
	{
		NSError* jsonParsingError = nil;
		NSString* jsonStr = [[[NSString alloc] initWithData:_receivedData encoding:NSUTF8StringEncoding] autorelease];
		SBJSON* parser = [[SBJSON alloc] init];
		id respObj = [parser objectWithString:jsonStr error:&jsonParsingError];
		[parser release];

		if (jsonParsingError) {
			// raise an error regarding JSON Parsing
			NSMutableDictionary* verboseUserInfo = [NSMutableDictionary dictionaryWithDictionary:[jsonParsingError userInfo]];
			[verboseUserInfo setObject:jsonStr forKey:JSONRPCErrorDataKey];
			NSError* verboseJsonParsingError = [NSError errorWithDomain:[jsonParsingError domain]
																   code:[jsonParsingError code]
															   userInfo:verboseUserInfo];
			
			SEL errSel = @selector(methodCall:didFailWithError:);
			BOOL cont = YES;
			if (_delegate && [_delegate respondsToSelector:errSel]) {
				cont = [_delegate methodCall:self.methodCall didFailWithError:verboseJsonParsingError];
			}
			if (cont)
			{
				id<JSONRPCErrorHandler> del = self.methodCall.service.delegate;
				if (del && [del respondsToSelector:errSel]) {
					cont = [del methodCall:self.methodCall didFailWithError:verboseJsonParsingError];
				}
				(void)cont; // UNUSED AFTER THAT
			}			
		} else {
			// extract result from JSON response
			id resultJsonObject = [respObj objectForKey:@"result"];
			if (resultJsonObject == [NSNull null]) resultJsonObject = nil;
			id parsedResult = resultJsonObject;
			if (resultJsonObject && _resultClass) {
				// decode object as expected Class
				parsedResult = [self objectFromJson:resultJsonObject];
				if (!parsedResult) {
					// raise and error regarding conversion (send to _delegate or fallback to service)
					SEL errSel = @selector(methodCall:didFailToConvertResponse:toClass:);
					NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
											  resultJsonObject,JSONRPCErrorDataKey,
											  NSLocalizedString(@"error.json-conversion.message","Error message upon conversion"),NSLocalizedDescriptionKey,
											  NSStringFromClass(_resultClass),JSONRPCErrorClassNameKey,
											  nil];
					NSError* error = [NSError errorWithDomain:JSONRPCInternalErrorDomain
														 code:JSONRPCConversionErrorCode
													 userInfo:userInfo];
					BOOL cont = YES;
					if (_delegate && [_delegate respondsToSelector:errSel]) {
						cont = [_delegate methodCall:self.methodCall didFailWithError:error];
					}
					if (cont)
					{
						id<JSONRPCErrorHandler> del = self.methodCall.service.delegate;
						if (del && [del respondsToSelector:errSel]) {
							cont = [del methodCall:self.methodCall didFailWithError:error];
						}
						(void)cont; // UNUSED AFTER THAT
					}
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
														[errorJsonObject objectForKey:@"data"]?:@"",JSONRPCErrorDataKey,
														nil]];
			}

			if (_delegate) {
				JSONRPCMethodCall* methCall = self.methodCall;
				NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[_delegate methodSignatureForSelector:_callbackSelector]];
				[inv setSelector:_callbackSelector];
				[inv setArgument:&methCall atIndex:2];
				[inv setArgument:&parsedResult atIndex:3];
				[inv setArgument:&parsedError atIndex:4];
				[inv invokeWithTarget:_delegate];
			} else {
				[self.methodCall.service methodCall:self.methodCall didReturnResult:parsedResult error:parsedError];
			}
		}	
	} else {
		[_delegate doesNotRecognizeSelector:_callbackSelector];
	}
}

-(id)objectFromJson:(id)jsonObject {
	//if ([_resultConvertionClass instancesRespondToSelector:@selector(initWithJson:)])
	{
		if ([jsonObject isKindOfClass:[NSArray class]]) {
			// Convert each object in the NSArray
			NSMutableArray* tab = [NSMutableArray arrayWithCapacity:[jsonObject count]];
			for(id oneJsonObj in jsonObject) {
				id oneObj = [[[_resultClass alloc] initWithJson:oneJsonObj] autorelease];
				if (!oneObj) return nil;
				[tab addObject:oneObj];
			}
			return [NSArray arrayWithArray:tab];
		} else {
			// not an NSArray
			return [[[_resultClass alloc] initWithJson:jsonObject] autorelease];
		}
	}
}
@end



