//
//  JSONRPCMethodCall.h
//  JSONRPC
//
//  Created by Olivier on 01/05/10.
//  Copyright 2010 AliSoftware. All rights reserved.
//

#import <Foundation/Foundation.h>

//! @file JSONRPCMethodCall.h
//! @brief Represent a method call on a JSON-RPC WebService.

@class JSONRPCService;

/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: JSON-RPC v1.0
/////////////////////////////////////////////////////////////////////////////

/** @brief This class represent a method call on a JSON-RPC WebService.
 * @note In practive, you rarely create a JSONRPCMethodCall directly.
 *  (except if you want to call the designed JSONRPCService#callMethod: method but everybody typically prefer commodity methods).
 *
 * But this class is still useful as it is returned as a parameter when receiving the response of the WebService, as it can be used
 *  to identify which method call correspond to the response, by inspecting its methodName and parameters \@properties.
 */
@interface JSONRPCMethodCall : NSObject
{
	//! @privatesection
	NSString* _methodName;
	id _parameters;
	NSString* _uuid;
	
	JSONRPCService* _service; //! will be affected when the JSONRPCMethodCall is called by a service
}
@property(nonatomic, retain) NSString* methodName; //!< the name of the JSON-RPC method
@property(nonatomic, retain) id parameters; //!< NSArray in JSON-RPC v1.0, NSDictionary in JSON-RPC v2.0
@property(nonatomic, retain, readonly) NSString* uuid; //!< the id of the JSON-RPC method call (nil for notifications). You typically don't need to use this \@property. @internal

/** The service associated with the method call.
 * You should never affect this \@property manually.
 * It will be nil upon the JSONRPCMethodCall creation; after the method has been called on a JSONRPCService, it will contain the service used to call the method.
 */
@property(nonatomic, retain) JSONRPCService* service;

//! Commodity constructor. @see JSONRPCMethodCall#initWithMethodName:parameters:
+(id)methodCallWithMethodName:(NSString*)methodName parameters:(NSArray*)params;
//! Commodity constructor. @see JSONRPCMethodCall#initWithMethodNameAndParameters: 
+(id)methodCallWithMethodNameAndParams:(NSString *)methodName, ... NS_REQUIRES_NIL_TERMINATION;
//! Commodity constructor. @see JSONRPCMethodCall#initWithMethodName:parameters:notifyOnly:
+(id)notificationWithName:(NSString*)methodName parameters:(NSArray*)params; 

/** @brief Constructor
 * @param methodName the name of the JSON-RPC method for this method call
 * @param params the array of parameters to pass to the method call
 * @note if you want to create a notification instead of a method call, use the designed initializer.
 */
-(id)initWithMethodName:(NSString*)methodName parameters:(NSArray*)params; // notifyOnly=NO
/** @brief Constructor
 * 
 * @param methodName the name of the JSON-RPC method for this method call
 * @param NS_REQUIRES_NIL_TERMINATION the subsequent parameters are the parameters of the JSON-RPC method. This list of parameters must be nil-terminated.
 * @note if you want to create a notification instead of a method call, use the designed initializer.
 */
-(id)initWithMethodNameAndParams:(NSString *)methodName, ... NS_REQUIRES_NIL_TERMINATION;

-(id)initWithMethodName:(NSString *)methodName parametersList:(va_list)paramsList notifyOnly:(BOOL)notifyOnly; //!< @privatesection @internal

/** @brief Designed initializer
 * @param methodName the name of the JSON-RPC method for this method call
 * @param params the array of parameters to pass to the method call
 * @param notifyOnly if YES, will create a notification instead of a method call
 * @note a notification is the same as a method call except that it does not expect a response from the WebService.
 */
-(id)initWithMethodName:(NSString*)methodName parameters:(NSArray*)params notifyOnly:(BOOL)notifyOnly;

-(id)proxyForJson; //!< @return the JSON representation of the JSONRPCMethodCall. @internal
@end






/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: JSON-RPC v2.0
/////////////////////////////////////////////////////////////////////////////


//! @brief This class is a subclass of JSONRPCMethodCall that handle JSON-RPC v2.0 method call @see JSONRPCService_v2_0
@interface JSONRPCMethodCall_v2_0 : JSONRPCMethodCall
//! Commodity constructor. @see JSONRPCMethodCall#initWithMethodName:namedParameters:
+(id)methodCallWithMethodName:(NSString*)methodName namedParameters:(NSDictionary*)params;
//! Commodity constructor. @see JSONRPCMethodCall#initWithMethodNameAndNamedParameters:
+(id)methodCallWithMethodNameAndNamedParams:(NSString *)methodName, ... NS_REQUIRES_NIL_TERMINATION;
//! Commodity constructor. @see JSONRPCMethodCall#initWithMethodName:namedParameters:notifyOnly:
+(id)notificationWithName:(NSString*)methodName namedParameters:(NSDictionary*)params;

/** @brief Constructor
 * @param methodName the name of the JSON-RPC method for this method call
 * @param params the dictionary of named parameters to pass to the method call
 * @note if you want to create a notification instead of a method call, use the designed initializer.
 */
-(id)initWithMethodName:(NSString*)methodName namedParameters:(NSDictionary*)params; // notifyOnly=NO
/** @brief Constructor
 * @param methodName the name of the JSON-RPC method for this method call
 * @param NS_REQUIRES_NIL_TERMINATION the subsequent parameters are the parameters values and names for the JSON-RPC method.
 *        This list of parameters must have a even number of items, alternating the parameter value
 *        with the corresponding parameter name, and must be nil-terminated (as in NSDictionary's dictionaryWithObjectsAndKeys:)
 * @note if you want to create a notification instead of a method call, use the designed initializer.
 */
-(id)initWithMethodNameAndNamedParams:(NSString *)methodName, ... NS_REQUIRES_NIL_TERMINATION;

-(id)initWithMethodName:(NSString*)methodName namedParametersList:(va_list)paramsList notifyOnly:(BOOL)notifyOnly; //!< @privatesection @internal

/** @brief Designed initializer
 * @param methodName the name of the JSON-RPC method for this method call
 * @param params the dictionary of (named) parameters to pass to the method call
 * @param notifyOnly if YES, will create a notification instead of a method call
 * @note a notification is the same as a method call except that it does not expect a response from the WebService.
 */
-(id)initWithMethodName:(NSString*)methodName namedParameters:(NSDictionary*)params notifyOnly:(BOOL)notifyOnly;
@end
