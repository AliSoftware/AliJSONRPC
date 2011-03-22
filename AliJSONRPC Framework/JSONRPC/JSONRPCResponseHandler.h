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

//! @file JSONRPCResponseHandler.h
//! @brief Utility object to configure the way to handle the response to a JSON-RPC method call

@class JSONRPCMethodCall;
@protocol JSONRPCDelegate;



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
	
	id<NSObject> _delegate;
	SEL _callbackSelector;
#if NS_BLOCKS_AVAILABLE
	void(^_completionBlock)(JSONRPCMethodCall*,id,NSError*);
#endif
	
	Class _resultClass; // instances of this class should conform to JSONInitializer
	int _maxRetryAttempts;
	NSTimeInterval _delayBeforeRetry;
}
@property(nonatomic,retain) JSONRPCMethodCall* methodCall; //!< the method call attached with this response handler
/** @brief The delegate object on which the callback will be called.
 * @note If this delegate is nil (the default), the JSONRPCService#delegate is used instead.
 */
@property(nonatomic,retain) id<NSObject> delegate;
/** @brief The callback (\@selector) to call when receiving the response from the WebService
 *
 * This \@selector must take three parameters:
 *  - a JSONRPCMethodCall representing the method call that triggered the response
 *  - a parameter of type 'id' or of a specific class corresponding to the expected response returned by the WebService.
 *    If you define a resultClass on the JSONRPCResponseHandler, the type of this second argument of the \@selector is typically the same class.
 *  - a parameter of type NSError that will hold the error returned by the WebService if any.
 *
 * @note This method is called on the JSONRPCResponseHandler#delegate object if set, or on the JSONRPCService#delegate if not.
 * @note By default, this selector is not set (the default) and the @ref JSONRPCDelegate methodCall:didReturn:error: (JSONRPCDelegate \@protocol) method is called instead.
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
 * @param aDelegate the delegate object that will receive the message (on which the callback will be called)
 * @param callback the \@selector to call (the message to send onto the delegate)
 */
-(void)setDelegate:(id<NSObject>)aDelegate callback:(SEL)callback;
/** @brief set both the delegate, the callback and the resultClass at once.
 * @param aDelegate the delegate object that will receive the message (on which the callback will be called)
 * @param callback the \@selector to call (the message to send onto the delegate)
 * @param cls the Class to convert the received JSON object to before calling the callback.
 * @note this method is typically useful when you nest it directly with the call of the JSONRPCMethodCall
 *       (JSONRPCService#callMethod or similar), as doing it that way you avoid the need to declare a temporary JSONRPCResponseHandler
 *       @code [[service callMethod:xxx] setDelegate:d callback:@selector(methodCall:didReturn:error:) resultClass:[MyCustomObject class]] @endcode
 */
-(void)setDelegate:(id<NSObject>)aDelegate callback:(SEL)callback resultClass:(Class)cls;

#if NS_BLOCKS_AVAILABLE
/** @brief use blocks to handle the response
 * @param completionBlock the block to execute when done
 */
-(void)completion:(void(^)(JSONRPCMethodCall* methodCall,id result,NSError* error))completionBlock;
/** @brief set the result class and use blocks to handle the response
 * @param completionBlock the block to execute when done
 * @param cls the Class to convert the received JSON object to before calling the completionBlock
 */
-(void)completion:(void(^)(JSONRPCMethodCall* methodCall,id result,NSError* error))completionBlock resultClass:(Class)cls;
#endif

@property(nonatomic, assign) int maxRetryAttempts;
@property(nonatomic, assign) NSTimeInterval delayBeforeRetry;
-(void)retryRequest; //!< Relaunch the request associated with this responseHandler.  You should not need to call this method yourself as this is done automatically upon network error
@end

