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

#import "JSONRPCMethodCall.h"
#import "JSONRPCService.h"
#import "JSON.h"

static inline NSString* generateUUID() {
	CFUUIDRef uuid = CFUUIDCreate(nil);
	NSString *uuidString = (NSString *)CFUUIDCreateString(nil, uuid);
	CFRelease(uuid);
	return [uuidString autorelease];
}

/////////////////////////////////////////////////////////////////////////////
// MARK: -
/////////////////////////////////////////////////////////////////////////////

@implementation JSONRPCMethodCall
@synthesize methodName = _methodName;
@synthesize parameters = _parameters;
@synthesize uuid = _uuid;
@synthesize service = _service;



/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: Constructors
/////////////////////////////////////////////////////////////////////////////

-(id)initWithMethodName:(NSString*)methodName parameters:(NSArray*)params
{
	self = [super init];
	if (self != nil) {
		self.methodName = methodName;
		self.parameters = params;
		_uuid = [generateUUID() retain];
	}
	return self;	
}

-(id)initWithMethodNameAndParams:(NSString *)methodName, ...
{	
	va_list ap;
	va_start(ap, methodName);
	id ret = [self initWithMethodName:methodName parametersList:ap];
	va_end(ap);
	return ret;
}
-(id)initWithMethodName:(NSString *)methodName parametersList:(va_list)paramsList
{
	NSMutableArray* args = [NSMutableArray array];
	id obj;
	while(obj = va_arg(paramsList,id)) [args addObject:obj];
	return [self initWithMethodName:methodName parameters:args];
}
// MARK: -
-(id)initWithMethodName:(NSString*)methodName namedParameters:(NSDictionary*)params
{
	self = [super init];
	if (self != nil) {
		self.methodName = methodName;
		self.parameters = params;
		_uuid = [generateUUID() retain];
	}
	return self;	
}
-(id)initWithMethodNameAndNamedParams:(NSString *)methodName, ...
{	
	va_list ap;
	va_start(ap, methodName);
	id ret = [self initWithMethodName:methodName namedParametersList:ap];
	va_end(ap);
	return ret;
}
-(id)initWithMethodName:(NSString*)methodName namedParametersList:(va_list)paramsList
{
	NSMutableDictionary* args = [NSMutableDictionary dictionary];
	id obj;
	NSString* key;
	while(obj = va_arg(paramsList,id)) {
		key = va_arg(paramsList,NSString*);
		[args setObject:obj forKey:key];
	}
	return [self initWithMethodName:methodName namedParameters:args];
}



/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: Commodity Constructors
/////////////////////////////////////////////////////////////////////////////

+(id)methodCallWithMethodName:(NSString*)methodName parameters:(NSArray*)params
{
	return [[[self alloc] initWithMethodName:methodName parameters:params] autorelease];
}
+(id)methodCallWithMethodNameAndParams:(NSString*)methodName, ...
{
	va_list ap;
	va_start(ap, methodName);
	id ret = [[[self alloc] initWithMethodName:methodName parametersList:ap] autorelease];
	va_end(ap);
	return ret;
}
// MARK: -
+(id)methodCallWithMethodName:(NSString*)methodName namedParameters:(NSDictionary*)params
{
	return [[[self alloc] initWithMethodName:methodName namedParameters:params] autorelease];
}
+(id)methodCallWithMethodNameAndNamedParams:(NSString *)methodName, ... {
	va_list ap;
	va_start(ap, methodName);
	id ret = [[[self alloc] initWithMethodName:methodName namedParametersList:ap] autorelease];
	va_end(ap);
	return ret;
}



/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: Conversion to JSON
/////////////////////////////////////////////////////////////////////////////


-(id)proxyForJson {
	NSMutableDictionary* jsonObj = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									_methodName,@"method",
									((id)_parameters?:(id)[NSNull null]),@"params",
									_uuid,@"id",
									nil];
	switch (self.service.version)
	{
		case JSONRPCVersion_1_0:
			// no 'version' or 'jsonrpc' field for this version
			break;
		case JSONRPCVersion_1_1:
			[jsonObj setObject:@"1.1" forKey:@"version"];
			break;
		case JSONRPCVersion_2_0:
			[jsonObj setObject:@"2.0" forKey:@"jsonrpc"];
			break;			
	}
	
	return [NSDictionary dictionaryWithDictionary:jsonObj];
}

-(NSString*)description {
	NSString* paramsStr;
	if (!_parameters) {
		paramsStr = @"";
	} else if ([_parameters isKindOfClass:[NSArray class]]) {
		paramsStr = [_parameters componentsJoinedByString:@","];
	} else if ([_parameters isKindOfClass:[NSDictionary class]]) {
		NSMutableArray* p = [NSMutableArray new];
		for(id key in _parameters) {
			[p addObject:[NSString stringWithFormat:@"%@:%@",key,[_parameters objectForKey:key]]];
		}
		paramsStr = [p componentsJoinedByString:@","];
		[p release];
	} else {
		paramsStr = [_parameters description]; // should not happen
	}
	
	return [NSString stringWithFormat:@"<%@ %@(%@)>",
			NSStringFromClass([self class]), self.methodName, paramsStr];
}
			
-(void)dealloc {
	[_methodName release];
	[_parameters release];
	[_uuid release];
	[_service release];
	[super dealloc];
}
@end
