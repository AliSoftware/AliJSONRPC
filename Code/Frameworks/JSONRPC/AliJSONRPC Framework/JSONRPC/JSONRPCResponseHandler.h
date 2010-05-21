//
//  JSONRPCDeferred.h
//  JSONRPC
//
//  Created by Olivier on 01/05/10.
//  Copyright 2010 AliSoftware. All rights reserved.
//

#import <Foundation/Foundation.h>

//! @file JSONRPCResponseHandler.h
//! @brief Utility object to configure the way to handle the response to a JSON-RPC method call

@class JSONRPCMethodCall;

/** @brief Informal protocol to create an object from a JSON object.
 *
 * If you set the resultClass on your JSONRPCResponseHandler, so that the JSON response returned by the WebService
 * is converted into an Objective-C instance of a custom class, this class must conform to this informal protocol
 * to be able to create an instance from the JSON object.
 */
@interface NSObject (JSONInitializer)
-(id)initWithJson:(NSDictionary*)dict; //!< @param dict the NSDictionary representing the JSON object, used to initialize the object instance from a JSON response
@end


/** @brief an intermediate object returned by the JSONRPCService when you call a method, to help you define how to handle the response.
 *
 * JSONRPCResponseHandler is an intermediate object used to define a delegate and a callback (= a target and an action) to call
 * when the WebService's response is received, and the Objective-C class to use if you want the received
 * JSON object to be converted to a custom Obj-C object automatically before calling the callback.
 *
 * You typically don't create a JSONRPCResponseHandler yourself. Instead, you retreive such objects
 * when calling JSONRPCService#callMethod: or similar methods; this returned object help you define
 * how to handle the response returned by the WebService after the method call.
 */
@interface JSONRPCResponseHandler : NSObject
{
	//! @privatesection
	JSONRPCMethodCall* _methodCall;
	NSMutableData* _receivedData;
	
	id _delegate;
	SEL _callbackSelector;
	
	Class _resultClass; // instances of this class should conform to JSONInitializer
}
@property(nonatomic,retain) JSONRPCMethodCall* methodCall; //!< the method call attached with this response handler
@property(nonatomic,retain) id  delegate; //!< the delegate object on which the callback will be called
/** the callback (\@selector) to call when receiving the response from the WebService
 * This \@selector must take three parameters:
 *  - a JSONRPCMethodCall representing the method call that triggered the response
 *  - a parameter of type 'id' or of a specific class corresponding to the expected response returned by the WebService.
 *    If you define a resultClass on the JSONRPCResponseHandler, the type of this second argument of the \@selector is typically the same class.
 *  - a parameter of type NSError that will hold the error returned by the WebService if any.
 */
@property(nonatomic,assign) SEL callback;
/** The class to convert the received object to, if wanted.
 * If this \@property is not nil, the received JSON object will be converted to an instance of the given class before
 * calling the callback \@selector. The provided class must conform to the JSONInitializer informal protocol, i.e. it must
 * respond to -initWithJson: .
 * @note if the WebService's JSON response is an NSArray (the root JSON object is an array), then instead every object
 *       in the array will be converted to the provided class.
 *       (instead of trying to create the instance of this class by passing the NSArray to initWithJson: directly)
 */
@property(nonatomic,assign) Class resultClass;

/** @brief set both the delegate and the callback to call upon receiving the WebService's response
 * @param target the delegate object that will receive the message (on which the callback will be called)
 * @param callback the \@selector to call (the message to send onto the delegate)
 */
-(void)setDelegate:(id)target callback:(SEL)callback;
/** @brief set both the delegate, the callback and the resultClass at once.
 * @param aDelegate the delegate object that will receive the message (on which the callback will be called)
 * @param callback the \@selector to call (the message to send onto the delegate)
 * @param cls the Class to convert the received JSON object to before calling the callback.
 * @note this method is typically useful when you nest it directly with the call of the JSONRPCMethodCall
 *       (JSONRPCService#callMethod or similar), as doing it that way you avoid the need to declare a temporary JSONRPCResponseHandler
 *       @code [[service callMethod:xxx] setDelegate:d callback:@selector(methodCall:didReturn:error:) resultClass:[MyCustomObject class]] @endcode
 */
-(void)setDelegate:(id)aDelegate callback:(SEL)callback resultClass:(Class)cls;
@end

