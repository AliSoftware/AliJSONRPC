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


/** @brief Category to easily retrieve the 'data' member of the error object
 *
 * This only has a meaning if this error object conforms to
 * <a href="http://groups.google.com/group/json-rpc/web/json-rpc-2-0">the JSON-RPC 2.0
 * specification, paragraph 5.1</a>, e.g. the object in the 'error' member of the WebService's response
 * is a JSON object with three fields: */
//! @code
//! {
//!   code: /* a Number that indicates the error type that occurred */,
//!   message: /* a String providing a short description of the error */,
//!   data: /* A Primitive or Structured value that contains additional information about the error. The value of this member is defined by the Server */
//! } @endcode 
@interface NSError(JSON)
/** @brief return the 'data' member of the JSON-RPC error when an error is returned by the WebService.
 *
 * This returns the 'data' key of the NSDictionary corresponding to the JSONRPCErrorJSONObjectKey of the userInfo dictionary.
 * This this userInfo key does not exist, is not an NSDictionary or does not contain this 'data' key, this returns nil.
 */
@property(nonatomic, readonly) id data;
@end


/** @brief Category to easily convert an NSArray of JSON objects to an NSArray of objects of a given class
 *
 * For each object in the passed NSArray, the class "itemsClass" will be instanciated
 * with the "initWithJson:" method to create a new object corresponding to the JSON object.
 * So this will finally initialize the NSArray with an array of "itemsClass" objects.
 */
@interface NSArray(JSON)
//! Commodity constructor to create an NSArray of itemsClass objects from an NSArray of JSON (typically NSDictionary) objects
+(id)arrayWithJson:(NSArray *)arrayOfJsonObjects itemsClass:(Class)itemsClass;
//! Designed initializer to create an NSArray of itemsClass objects from an NSArray of JSON (typically NSDictionary) objects
-(id)initWithJson:(NSArray *)arrayOfJsonObjects itemsClass:(Class)itemsClass;
@end
