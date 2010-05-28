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
#import "JSONRPCMethodCall.h"
#import "JSONRPCResponseHandler.h"
#import "JSONRPC_Extensions.h"


/////////////////////////////////////////////////////////////////////////////
// MARK: Useful macros
//! @file JSONRPC.h
//! @brief Common header that include other headers of the framework. Contains useful macros too.
/////////////////////////////////////////////////////////////////////////////

//! Commodity macro to create an NSArray with arbitrary number of objects.
#define mkArray(...) [NSArray arrayWithObjects:__VA_ARGS__,nil]
//! Commodity macro to create a NSDictionary with arbitrary number of key/value pairs. Parameters are listed in the order objectN,keyN
#define mkDict(...) [NSDictionary dictionaryWithObjectsAndKeys:__VA_ARGS__,nil]
//! Commodity macro to create an NSNumber from an int
#define mkInt(x) [NSNumber numberWithInt:x]
//! Commodity macro to extract an int from an NSNumber
#define rdInt(nsx) [nsx intValue]






/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: Doxygen Documentation
/////////////////////////////////////////////////////////////////////////////


/**
 * @mainpage Ali's JSON-RPC Framework documentation
 *
 * @par Description
 *    This framework aims to provide JSON-RPC support to your Objective-C programs.
 *    Its role is to have a simple API to query any WebService that can be called using JSON-RPC.
 *    \n
 *    This framework currently support JSON-RPCversion  1.0, 1.1 and 2.0.
 *
 * - @subpage Overview
 *    - @subpage OverviewCreate
 *    - @subpage OverviewCall
 *    - @subpage OverviewResponse
 *       - @subpage OverviewResultConversion
 *    - @subpage OverviewRelease
 * - @subpage ErrMgmt
 *    - @subpage ErrCatch
 *    - @subpage ErrCodes
 * - @subpage Example
 *
 ***** <hr>
 *
 * @author O.Halligon
 * @version 1.2
 * @date May 2010
 *
 * @note The JSON part is assured through the <a href="http://code.google.com/p/json-framework/">SBJSON</a> framework.
 *
 */


/**
 * @page Overview Overview
 * 
 * Briefely, you use this framework in four steps:
 *  -# @ref OverviewCreate
 *  -# @ref OverviewCall
 *  -# @ref OverviewResponse
 *  -# @ref OverviewRelease
 *
 * @note some useful macros to create arrays and dicts are defined in JSONRPC.h
 *
 *
 * @section OverviewCreate Create a JSONRPCService object
 * You do this typically by passing the URL of the WebService to the init constructor,
 * specifying the JSON-RPC version supported by the WebService:
 * @code
 * JSONRPCService* service = [[JSONRPCService alloc] initWithURL:kServiceURL version:JSONRPCVersion_1_0];
 * @endcode
 *
 *
 * @section OverviewCall Call a remote procedure of the WebService using JSON-RPC
 * To do this, you have <b>multiple equivalent possibilities</b>:
 * <ul>
 *
 *   <li> Use the JSONRPCService#callMethodWithName:parameters: or JSONRPCService#callMethodWithName:namedParameters: method,
 *       passing it the name of the method to call (an NSString) and its parameters (an NSArray for the first case, NSDictionary for the second)
 *   </li>
 *
 *   <li> Use the JSONRPCService#callMethodWithNameAndParams: or JSONRPCService#callMethodWithNameAndNamedParams: method,
 *       passing it the name (NSString) of the method to call, followed by a variable number of arguments
 *       representing the parameters, terminated by 'nil'.
 *
 *       This variable number of arguments are at the same format as:
 *       - +[NSArray arrayWithObjects:] for JSONRPCService#callMethodWithNameAndParams:
 *       - +[NSDictionary dictionaryWithObjectsAndKeys:] for JSONRPCService#callMethodWithNameAndNamedParams:
 *   </li>
 *
 *   <li> Create a JSONRPCMethodCall object, passing it the name of the method to call and its arguments,
 *       then pass it to the JSONRPCService#callMethod: to actually call the method.
 *       (This is actually what the two previous options do in their implementation).</li>
 *
 *   <li> Ask the JSONRPCService for a proxy object (see JSONRPCService#proxy), then call directly any method you want
 *      as an Objective-C call (as if it was the WebService itself), with the arguments in an NSArray or NSDictionary.
 *      The following 3 lines will in fact be equivalent:
 *      @code
 *        [service.proxy echo:[NSArray arrayWithObject:@"Hello there"]]
 *        [service callMethodWithName:@"echo" parameters:[NSArray arrayWithObject:@"Hello there"]];
 *        [service callMethodWithNameAndParams:@"echo",@"Hello there",nil];
 *      @endcode
 *   </li>
 * 
 * </ul>
 *
 *
 * @section OverviewResponse Handle the response from the server
 * When you call a JSON-RPC method, you get a JSONRPCResponseHandler object as a return value.
 *   <ul>
 *     <li> If you don't do anything with the JSONRPCResponseHandler (neither set a delegate nor a the callback),
 *          the method @ref JSONRPCDelegate "methodCall:didReturn:error:" will be called on the JSONRPCService 's delegate.
 *          If no delegate is set on the JSONRPCService object neither, the response will be ignored.</li>
 *     <li> If you set the delegate of the JSONRPCResponseHandler object (JSONRPCResponseHandler#delegate:), this object
 *          will handle the response for this methodCall instead of the JSONRPCService's delegate.
 *          This is useful if you have a unique JSONRPCService object (e.g. singleton) and call it from multiple places in your project,
 *          to define different delegate objects depending on the place you call the service from, etc.</li>
 *     <li> You can also set the callback (\@selector) to call instead of the default @ref JSONRPCDelegate "methodCall:didReturn:error:".
 *          The callback should be a \@selector that accept 3 parameters : a JSONRPCMethodCall object, a generic object
 *          representing the response, and an NSError. (as the @ref JSONRPCDelegate "methodCall:didReturn:error:" \@selector).
 *     </li>
 * 	    @code
 *        JSONRPCResponseHandler* h = [service callMethodWithName:@"echo" parameters:mkArray(@"Hello there")];
 *        // (1) If we stop here, the response will be received by the JSONRPCService's delegate method methodCall:didReturn:error:
 *
 *        [h setDelegate:x];
 *        // at this stage, the response will be received by x through the method methodCall:didReturn:error:
 *
 *        [h setCallback:@selector(remoteProcedureCall:didReturnObject:serviceError:)];
 *        // at this stage, the response will be received by x through the method remoteProcedureCall:didReturnObject:serviceError:
 *	    @endcode
 *     <li> You can also set the Class you want the result to be converted into. This way, you can receive
 *      a custom object (e.g. your 'User' or 'ItemDetail', ... custom classes) as a response to you JSON-RPC method call,
 *      and not only JSON objects (NSDictionary, NSArray, NSString, ...).
 *      @see @ref OverviewResultConversion
 *     </li>
 *   </ul>
 *   Note that you can nest the JSONRPCService method call with the JSONRPCResponseHandler calls to be more concise:
 *   @code
 *   [[service callMethodWithNameAndParams:@"echo",@"Hello there",nil]
 *    setDelegate:self callback:@selector(methodCall:didReturn:error) resultClass:[MyCustomClass class]];
 *   @endcode
 *
 *
 * @section OverviewRelease Release the service
 * Of course don't forget to release your JSONRPCService when you are done.
 * @note JSONRPCService objects are internally retained while a request has been sent to the service
 *  (and then automatically autoreleased when the request receive the response, avec forwarding the response to the delegate).
 *  This way, you are not required to retain the JSONRPCService instance until you get the response (otherwise this would have
 *   required for you to keep a reference on the JSONRPCService as an instance variable)
 *
 * @section OverviewNext Going further
 * As you can see, the usage of this framework is highly flexible. You can call a JSON-RPC method using multiple different syntaxes,
 * and you can also receive the response in the way you think it's the best suitable for your project, centralizing the responses on
 * one object (the JSONRPCService#delegate) or on separate objects (JSONRPCResponseHandler#delegate) and calling a unique \@selector
 * method for handling the response of all your method calls, or a different \@selector for each.
 *
 * For more information, you can look at the @ref Example.
 */

/**
 * @page OverviewResultConversion Converting the JSON response to a custom class
 *
 * You can make the JSON response of your remote method call be converted into the class of your choice.
 * This is very useful to manipulate instances of your custom classes instead of only use NSDictionaries
 *
 * To make this possible, the class you want the JSON object to be converted to should respond to initWithJson:
 *  to be initialized using the JSON object. (see @ref ResultConversionExample1)
 * @note Optionally, this class may also respond to -jsonProxy to be converted back to a JSON object if needed later (see SBJSON documentation)
 *
 * If the JSON object returned by the WebService is an array, the convertion from the JSON object to the given Class
 *  will be done on the objects in this array, and not on the array itself.
 * This way, an array of objects representing e.g. a person can be converted into an NSArray of Person objects.
 *
 * For more complex objects, you can call initWithJson in the initWithJson method itself, and also use
 *  arrayWithJson:itemsClass: method of the NSArray(JSON) category (JSONRPC_Extensions.h). See @ref ResultConversionExample2
 *
 * <hr>
 * @section ResultConversionExample1 Simple example
 *
 * As an example, to handle JSON objects representing a person with fields "firstname" and "lastname":
 * @code {
 *    firstname: "John",
 *    lastname: "Doe"
 * }@endcode
 * Then you can define an "Person" Objective-C class (to convert those JSON objects) like this:
 * @code
 * @interface Person : NSObject {
 *   NSString* firstName;
 *   NSString* lastName;
 * }
 * @property(nonatomic, retain) NSString* firstName;
 * @property(nonatomic, retain) NSString* lastName;
 * -(id)initWithJson:(NSDictionary*)json;
 * @endcode
 * @code
 * @implementation Perso
 * @synthesize firstName, lastName;
 * -(id)initWithJson:(NSDictionary*)json {
 *   if (self = [super init]) {
 *     self.firstName = [json objectForKey:@"firstname"];
 *     self.lastName = [json objectForKey:@"lastname"];
 *   }
 *   return self;
 * }
 * -(void)dealloc {
 *   [firstName release];
 *   [lastName release];
 *   [super dealloc];
 * }
 * @endcode
 *
 * Then, if you have a JSON-RPC method that returns a JSON representation of a person as a result, you can call it this way:
 * @code
 * [[service callMethodWithName:@"getAPerson" parameters:nil] setResultClass:[Person class]];
 * @endcode
 * And when the delegate method will be called, a Person instance, constructed from the returned JSON, will be passed as the second parameter:
 * @code
 * -(void)methodCall:(JSONRPCMethodCall*)mc didReturn:(Person*)person error:(NSError*)error {
 *   // handle the Person object here
 * }
 * @endcode
 *
 * <hr>
 *
 * @section ResultConversionExample2 More complex example
 * If the JSON object returned by the WebService is more complex, you can call initWithJson (on other classes) from your initWithJson implementation
 *  and even use the -[NSArray initWithJson:itemsClass:] or +[NSArray arrayWithJson:itemsClass:] methods of the NSArray category to build complex instances.
 *
 * For example, image your WebService also return a JSON object representing a family, like this:
 * @code {
 *   father: { firstname:"John", lastname:"Doe" },
 *   mother: { firstname:"Jane", lastname:"Doe" },
 *   children: [ { firstname:"John Jr", lastname:"Doe" }, { firstname:"Jane Jr", lastname:"Doe" }]
 * } @endcode
 * In this example, the object representing a family is itself composed of objects representing persons.
 * If you want to create a "Family" Objective-C class to represent such object, you can implement it this way:
 * @code
 * @interface Family : NSObject {
 *   Person* father;
 *   Person* mother;
 *   NSArray* children;
 * }
 * @property(nonatomic, retain) Person* father;
 * @property(nonatomic, retain) Person* mother;
 * @property(nonatomic, retain) NSArray* children;
 * -(id)initWithJson:(NSDictionary*)json;
 * @end
 * @endcode
 * @code
 * @implementation Family
 * @synthesize father, mother, children;
 * -(id)initWithJson:(NSDictionary*)json {
 *   if (self = [super init]) {
 *     self.father = [[[Person alloc] initWithson:[json objectForKey:@"father"]] autorelease];
 *     self.mother = [[[Person alloc] initWithson:[json objectForKey:@"mother"]] autorelease];
 *     self.children = [[[NSArray alloc] initWithson:[json objectForKey:@"children"] itemsClass:[Person class]] autorelease];
 *   }
 *   return self;
 * }
 * -(void)dealloc {
 *   [father release];
 *   [mother release];
 *   [children release];
 *   [super dealloc];
 * }
 * @end
 * @endcode
 */




/**
 * @page ErrMgmt Error management
 *
 * @section ErrCatch Catching Errors
 *
 * @subsection ErrCatch1 Internal errors
 
 * When an internal error occur (network error, JSON parsing error, failed to convert to expected class, ...),
 * the JSONRPCResponseHandler will forward the error in the following order:
 *  - try to call @ref JSONRPCDelegate "methodCall:didFailWithError:" on the JSONRPCResponseHandler 's delegate
 *    (i.e. on the object that expect to receive the response)
 *  - if it does not respond, or respond and return YES, we try to call @ref JSONRPCDelegate "methodCall:didFailWithError:"
 *    on the JSONRPCService 's delegate
 *
 * This way, if you don't implement @ref JSONRPCDelegate "methodCall:didFailWithError:" in the delegate object that expect the response,
 *  it will fall back to the implementation of the JSONRPCService's delegate to handle generic cases (which typically display an alert or something).
 *
 * If you want to catch the error on specific cases, you still can implement @ref JSONRPCDelegate "methodCall:didFailWithError:" in the
 *  JSONRPCResponseHandler's delegate object to catch it. At this point, you can return YES to still execute the default behavior
 *  (the one in your JSONRPCService's delegate implementation) or return NO to avoid forwarding the error.
 *
 * @subsection ErrCatch2 Server errors
 *
 * For error returned by the server (a JSON is received but it contains an "error" object), indicating something
 * went wrong in the server (unknown method name, bad parameters, method-specific errors, ...), this object
 * is simply passed as an NSError in the third parameter of the JSONRPCResponseHandler's delegate callback.
 *
 ****************************************************************************
 *
 * @section ErrCodes The different error cases and their error domains
 * 
 * @subsection ErrCodes1 Internal errors ("methodCall:didFailWithError:")
 * This method can receive these kinds of errors:<ul>
 *
 * <li>Network error (Domain NSURLErrorDomain)</li>
 *
 * <li>JSON Parsing error (Domain SBJSONErrorDomain), whose userInfo dictionary contains the following keys:<ul>
 *   <li>key JSONRPCErrorJSONObjectKey : String we tried to parse as a JSON object</li>
 *   <li>key NSUnderlyingErrorKey : contains an underlying error if any</li>
 * </ul></li>
 * 
 * <li>JSON-to-Object Conversion error or internal errors (Domain JSONRPCInternalErrorDomain), whose userInfo dictionary contains the following keys:<ul>
 *   <li>key JSONRPCErrorJSONObjectKey : the JSON object we tried to convert</li>
 *   <li>key JSONRPCErrorClassNameKey : the name of the class we tried to convert to</li>
 * </ul></li>
 *
 * </ul>
 *
 * @subsection ErrCodes2 Server errors ("methodCall:didReturn:error:")
 * This section only receive error that comes directly from the WebService you query using JSON-RPC.
 * When the server returned an error in its JSON response, this is obviously a server-dependant error code.
 *
 * - The Domain for those errors is JSONRPCServerErrorDomain
 * - The userInfo dictionary contains server-specific error object in the <tt>JSONRPCErrorJSONObjectKey</tt> key.
 *
 * @note JSON-RPC v2.0 WebServices should return the error at the following format, according to the specification:
 * @code
 * {
 *    code: // A Number that indicates the error type that occurred. See also reserved codes at http://xmlrpc-epi.sourceforge.net/specs/rfc.fault_codes.php
 *    message: // A String providing a short description of the error. The message SHOULD be limited to a concise single sentence.
 *    data: // A value that contains additional information about the error. Defined by the Server (e.g. detailed error information, nested errors etc.).
 * }
 * @endcode
 * Actually, even some JSON-RPC v1.0 WebServices also return error objects using this convention.
 * In such case, this JSON object is still available the <tt>JSONRPCErrorJSONObjectKey</tt>, but in addition:
 * - The value in 'code' is used as the code of the NSError
 * - The value in 'message' is used as the localizedDescription of the NSError
 * - The value in 'data' can be retrieved with the \@property data of NSError (see NSError(JSON))
 */



/**
 * @page Example Example
 *
 *
 * @section Example_TestClass Test class: a demo of using the JSONRPC Framework
 *
 *     @code
 *     #import "JSONRPC.h"
 *     @interface TestClass : NSObject <JSONRPCErrorHandler>
 *     -(void)testIt;
 *     @end
 *     @endcode
 *
 *     @code
 *     #import "TestClass.h"
 *     #import "Person.h"
 *
 *     @implementation TestClass
 *     -(void)testIt
 *     {
 *       JSONRPCService* service = [[[JSONRPCService alloc] initWithURL:kServiceURL version:JSONRPCVersion_1_0] autorelease];
 *
 *       [[service callMethodWithNameAndParams:@"getUserDetails",@"user1234",nil]
 *        setDelegate:self callback:@selector(methodCall:didReturnUser:error:) resultClass:[Person class]];
 *       // will convert the returned JSON into a Person object (providing that the class Person respond to -initWithJson, this is the case below)
 *     }
 *
 *     -(void)methodCall:(JSONRPCMethodCall*)meth didReturnUser:(Person*)p error:(NSError*)err
 *     {
 *       // We will effectively receive a "Person*" object (and not a JSON object like a NSDictionary) in the parameter p
 *       // because we asked to convert the result using [Person class] in -testIt
 *
 *       NSLog(@"Received person: %@",p);
 *       if (error) NSLog(@"error in method call: %@",err);
 *     }
 *
 *     -(BOOL)methodCall:(JSONRPCMethodCall*)meth didFailWithError:(NSError*)err
 *     {
 *       // handle the NSError (network error / no connection, etc.)
 *       return NO; // don't call methodCall:didFailWithError: on the JSONRPCService's delegate.
 *     }
 *     @end
 *     @endcode
 *
 *
 * @section Example_Person Person class: to represent in ObjC the persons returned by the JSONRPC WebService
 * Used in TestClass as the result is converted into a Person object ("... resultClass:[Person class]")
 *
 *     @code
 *     @interface Person : NSObject {
 *       NSString* firstName;
 *       NSString* lastName;
 *     }
 *     -(void)initWithJson:(id)jsonObj;
 *     @property(nonatomic,retain) NSString* firstName;
 *     @property(nonatomic,retain) NSString* lastName;
 *     @end
 *     @endcode
 *
 *     @code
 *     #import "Person.h"
 *
 *     @implementation Person
 *     @synthesize firstName,lastName;
 *     -(id)initWithJson:(id)jsonObj
 *     {
 *        if (self = [super init]) {
 *          self.firstName = [jsonObj objectForKey:@"firstname"];
 *          self.lastName = [jsonObj objectForKey:@"lastname"];
 *        }
 *        return self;
 *     }
 *     -(NSString*)description { return [NSString stringWithFormat:@"<Person %@ %@>",firstName,lastName]; }
 *     -(void)dealloc
 *     {
 *       [firstName release];
 *       [lastName release];
 *       [super dealloc];
 *     }
 *     @end
 *     @endcode
 *
 */




