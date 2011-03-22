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

#import <Foundation/Foundation.h>

//! @file JSONRPCService.h
//! @brief Represent a JSON-RPC WebService.


NSString* const JSONRPCServerErrorDomain; //!< domain for errors returned by the server (in the JSON object)
NSString* const JSONRPCServerErrorNotification; //!< notification send for errors returned by the server (in the JSON object)
NSString* const JSONRPCErrorJSONObjectKey; //!< key used in NSError's userInfo dict to hold JSON-RPC's error "data" member

NSString* const JSONRPCInternalErrorDomain;   //!< domain for internal errors: conversion from JSON to Object, ...
NSInteger const JSONRPCFormatErrorCode;       //!< The code for an NSError (JSONRPCInternalErrorDomain) that occurs when the received JSON is not conformant with RPC standard ({id,result,error})
NSString* const JSONRPCFormatErrorString;     //!< English string for JSONRPCFormatErrorCode error. Define a localization for "JSONRPCFormatErrorString" in your Localizable.strings to provide a custom translation
NSInteger const JSONRPCConversionErrorCode;   //!< The code for an NSError (JSONRPCInternalErrorDomain) that occurs when converting the JSON object to the resultClass instance
NSString* const JSONRPCConversionErrorString; //!< English string for JSONRPCConversionErrorCode error. Define a localization for "JSONRPCConversionErrorString" in your Localizable.strings to provide a custom translation
NSString* const JSONRPCErrorClassNameKey;     //!< the key used in NSError's userInfo dict to hold the class we expected to convert the JSON response to.


@class JSONRPCMethodCall;
@class JSONRPCResponseHandler;



/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: Error Handling
/////////////////////////////////////////////////////////////////////////////

//! JSONRPC Error Handler protocol, used on the JSONRPCMethodCall's or JSONRPCService's delegate (see @ref ErrMgmt)
@protocol JSONRPCDelegate <NSObject>
@optional
/** @brief method called upon reception of the result of a JSON-RPC method call,
 * if no callback defined in the returned JSONRPCResponseHandler to catch the response.
 * @param methodCall the methodCall that received a response from the WebService
 * @param result the "result" object returned by the JSON-RPC WebService. (May be nil if the WebService returned an error)
 * @param error the "error" object returned by the JSON-RPC WebService. (Will be nil if no error)
 */
-(void)methodCall:(JSONRPCMethodCall*)methodCall didReturn:(id)result error:(NSError*)error;
/** @brief Called when an error occurred during the method call. (see @ref ErrMgmt)
 *  @param methodCall the JSONRPCMethodCall that triggered the error
 *  @param error the error that happend
 *  @return YES to continue calling this to the next error handler, NO to stop forwarding.
 */
-(BOOL)methodCall:(JSONRPCMethodCall*)methodCall shouldForwardConnectionError:(NSError*)error;

/** @brief Called when a network error occurred because the network has been lost, and so the request will be retried automatically soon
 *  @param methodCall the JSONRPCMethodCall that triggered the error
 *  @param error the error that happend
 */
-(void)methodCall:(JSONRPCMethodCall*)methodCall willRetryAfterError:(NSError*)error;

/** @brief Called to notify when the request, that previously failed because of lost network, is being retried
 *  @param methodCall the JSONRPCMethodCall that triggered the error 
 */
-(void)methodCallIsRetrying:(JSONRPCMethodCall*)methodCall;
@end



/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: JSON-RPC Service
/////////////////////////////////////////////////////////////////////////////

//! Used to specify the JSON-RPC version supported by the WebService
typedef enum {
	JSONRPCVersion_1_0,
	JSONRPCVersion_1_1,
	JSONRPCVersion_2_0
} JSONRPCVersion;


//! The class representing a JSON-RPC WebService (identified by an URL to call methods to). It handle JSON-RPC v1.0 WebServices.
@interface JSONRPCService : NSObject {
	//! @privatesection
	NSURL* _serviceURL;
	JSONRPCVersion _version;
	NSObject<JSONRPCDelegate>* delegate;
}
@property(nonatomic, retain) NSURL* serviceURL; //!< The URL to forward JSONRPC method calls to.
@property(nonatomic, assign) JSONRPCVersion version; //!< The JSON-RPC version supported by the WebService
@property(nonatomic, assign) NSObject<JSONRPCDelegate>* delegate; //!< Object to handle errors if not handled by JSONRPCResponseHandler#delegate .
@property(nonatomic, readonly) id proxy; //!< A proxy object on which you can call any Obj-C message (without any param or with an NSArray as a parameter), and which will be forwarded as a JSONRPC method call.



/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: Constructors
/////////////////////////////////////////////////////////////////////////////

/** Commodity constructor
 * @param url the URL of the WebService.
 * @param version the JSON-RPC version supported by the WebService
 */
+(id)serviceWithURL:(NSURL*)url version:(JSONRPCVersion)version;
/** Designed initializer
 * @param url the URL of the WebService.
 * @param version the JSON-RPC version supported by the WebService
 */
-(id)initWithURL:(NSURL*)url version:(JSONRPCVersion)version;



/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: Calling a Procedure
/////////////////////////////////////////////////////////////////////////////

/** @brief Method to call a JSON-RPC method on the WebService.
 * @param methodCall the JSONRPCMethodCall to call
 * @return a JSONRPCResponseHandler object that allows you to define a delegate, callback and resultClass to use upon the WebService's response.
 */
- (JSONRPCResponseHandler*)callMethod:(JSONRPCMethodCall*)methodCall;
/** @brief Designed method to call a JSON-RPC method on the WebService.
 * @param methodCall the JSONRPCMethodCall to call
 * @param responseHandler the JSONRPCResponseHandler to reuse, or nil to use a new one
 * @return a JSONRPCResponseHandler object that allows you to define a delegate, callback and resultClass to use upon the WebService's response.
 */
- (JSONRPCResponseHandler*)callMethod:(JSONRPCMethodCall*)methodCall reuseResponseHandler:(JSONRPCResponseHandler*)responseHandler;

/** @brief Commodity method to call a JSON-RPC method on the WebService.
 * @param methodName the name of the method to call on the WebService
 * @param params the array of parameters to pass to the method call
 * @return a JSONRPCResponseHandler object that allows you to define a delegate, callback and resultClass to use upon the WebService's response.
 */
// MARK: -
- (JSONRPCResponseHandler*)callMethodWithName:(NSString *)methodName parameters:(NSArray*)params;
/** @brief Commodity method to call a JSON-RPC method on the WebService.
 * @param methodName the name of the method to call on the WebService
 * @param NS_REQUIRES_NIL_TERMINATION the subsequent parameters are the parameters sent to the JSON-RPC method. This list of parameters must be nil-terminated.
 * @return a JSONRPCResponseHandler object that allows you to define a delegate, callback and resultClass to use upon the WebService's response.
 */
- (JSONRPCResponseHandler*)callMethodWithNameAndParams:(NSString *)methodName, ... NS_REQUIRES_NIL_TERMINATION;

/** @brief Commodity method to call a JSON-RPC method on the WebService.
 * @param methodName the name of the method to call on the WebService
 * @param params the dictionary of named parameters to pass to the method call
 * @return a JSONRPCResponseHandler object that allows you to define a delegate, callback and resultClass to use upon the WebService's response.
 */
- (JSONRPCResponseHandler*)callMethodWithName:(NSString *)methodName namedParameters:(NSDictionary*)params;
/** @brief Commodity method to call a JSON-RPC method on the WebService.
 * @param methodName the name of the method to call on the WebService
 * @param NS_REQUIRES_NIL_TERMINATION the subsequent parameters are the parameters values and names for the JSON-RPC method.
 *        This list of parameters must have a even number of items, alternating the parameter value
 *        with the corresponding parameter name, and must be nil-terminated (as in NSDictionary's dictionaryWithObjectsAndKeys:) 
 * @return a JSONRPCResponseHandler object that allows you to define a delegate, callback and resultClass to use upon the WebService's response.
 */
- (JSONRPCResponseHandler*)callMethodWithNameAndNamedParams:(NSString *)methodName, ... NS_REQUIRES_NIL_TERMINATION;
@end




/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: JSONRPC Service Proxy
/////////////////////////////////////////////////////////////////////////////
/** @brief Proxy object which allow you to call JSON-RPC methods as if it was Obj-C method.
 *
 * Use the JSONRPCService#proxy méthod to get a proxy object to a JSON-RPC WebService instead of creating it yourself.
 *
 * Using the proxy object allows you to directly call a JSON-RPC method on a WebService
 * as if it was an Objective-C method like this:
 *  @code
 *  // service is an JSONRPCService object
 *  [service.proxy getUsersList]; // equivalent to [service callMethodWithName:@"getUsersList" parameters:nil]
 *  [service.proxy echo:mkArray(@"Hello")]; // equivalent to [service callMethodWithName:@"echo" parameters:mkArray(@"Hello")]
 *  @endcode
 * It is a nice way to have a somewhat transparent way to manipulate the WebService's API, <b>but has the drawback
 * that it will generate warnings on compilation</b> such as "xxx may not respond to selector yyy"
 * (as the message you will call on this proxy object are not declared but instead automatically forwarded using forwardInvocation:)
 */
@interface JSONRPCServiceProxy : NSProxy
{
	//! @privatesection
	JSONRPCService* _service;
}
@property(nonatomic, assign) JSONRPCService* service; //!< the service the proxy acts for
-(id)initWithService:(JSONRPCService*)service; //!< @private constructor
@end
