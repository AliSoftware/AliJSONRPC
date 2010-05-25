//
//  JSONRPCService.h
//  JSONRPC
//
//  Created by Olivier on 01/05/10.
//  Copyright 2010 AliSoftware. All rights reserved.
//

#import <Foundation/Foundation.h>

//! @file JSONRPCService.h
//! @brief Represent a JSON-RPC WebService.


NSString* const JSONRPCServerErrorDomain; //!< domain for errors returned by the server (in the JSON object)
NSString* const JSONRPCErrorDataKey; //!< key used in NSError's userInfo dict to hold JSON-RPC's error "data" member

NSString* const JSONRPCInternalErrorDomain; //!< domain for internal errors: conversion from JSON to Object, ...
NSInteger const JSONRPCConversionErrorCode; //!< The code for an NSError (JSONRPCInternalErrorDomain) that occurs when converting the JSON object to the resultClass instance
NSString* const JSONRPCErrorClassNameKey; //!< the key used in NSError's userInfo dict to hold the class we expected to convert the JSON response to.


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
-(BOOL)methodCall:(JSONRPCMethodCall*)methodCall didFailWithError:(NSError*)error;
@end



/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: JSON-RPC v1.0
/////////////////////////////////////////////////////////////////////////////

//! The class representing a JSON-RPC WebService (identified by an URL to call methods to). It handle JSON-RPC v1.0 WebServices.
@interface JSONRPCService : NSObject {
	//! @privatesection
	NSURL* _serviceURL;
	NSObject<JSONRPCDelegate>* delegate;
}
@property(nonatomic, retain) NSURL* serviceURL; //!< The URL to forward JSONRPC method calls to.
@property(nonatomic, assign) NSObject<JSONRPCDelegate>* delegate; //!< Object to handle errors if not handled by JSONRPCResponseHandler#delegate .
@property(nonatomic, readonly) id proxy; //!< A proxy object on which you can call any Obj-C message (without any param or with an NSArray as a parameter), and which will be forwarded as a JSONRPC method call.

+(id)serviceWithURL:(NSURL*)url; //!< Commodity constructor @param url the URL of the WebService.
-(id)initWithURL:(NSURL*)url; //!< Designed initializer @param url the URL of the WebService.

/** @brief Designed method to call a JSON-RPC method on the WebService.
 * @param methodCall the JSONRPCMethodCall to call
 * @return a JSONRPCResponseHandler object that allows you to define a delegate, callback and resultClass to use upon the WebService's response.
 */
- (JSONRPCResponseHandler*)callMethod:(JSONRPCMethodCall*)methodCall;
/** @brief Commodity method to call a JSON-RPC method on the WebService.
 * @param methodName the name of the method to call on the WebService
 * @param params the array of parameters to pass to the method call
 * @return a JSONRPCResponseHandler object that allows you to define a delegate, callback and resultClass to use upon the WebService's response.
 */
- (JSONRPCResponseHandler*)callMethodWithName:(NSString *)methodName parameters:(NSArray*)params;
/** @brief Commodity method to call a JSON-RPC method on the WebService.
 * @param methodName the name of the method to call on the WebService
 * @param NS_REQUIRES_NIL_TERMINATION the subsequent parameters are the parameters sent to the JSON-RPC method. This list of parameters must be nil-terminated.
 * @return a JSONRPCResponseHandler object that allows you to define a delegate, callback and resultClass to use upon the WebService's response.
 */
- (JSONRPCResponseHandler*)callMethodWithNameAndParams:(NSString *)methodName, ... NS_REQUIRES_NIL_TERMINATION;
/** @brief Commodity method to send a JSON-RPC notification on the WebService.
 *  @note A notification (in the JSON-RPC context) is the same as a method call, except that it does not expect any response from the server.
 * @param methodName the name of the method to call on the WebService
 * @param params the array of parameters to pass to the method call
 */
- (void)sendNotificationWithName:(NSString *)methodName parameters:(NSArray*)params;
@end



/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: JSON-RPC v2.0
/////////////////////////////////////////////////////////////////////////////

//! @brief This class is a subclass of JSONRPCService that handle JSON-RPC v2.0 services
@interface JSONRPCService_v2_0 : JSONRPCService
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
/** @brief Commodity method to send a JSON-RPC notification on the WebService.
 *  @note A notification (in the JSON-RPC context) is the same as a method call, except that it does not expect any response from the server.
 * @param methodName the name of the method to call on the WebService
 * @param params the array of parameters to pass to the method call
 */
- (void)sendNotificationWithName:(NSString *)methodName namedParameters:(NSDictionary*)params;
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
