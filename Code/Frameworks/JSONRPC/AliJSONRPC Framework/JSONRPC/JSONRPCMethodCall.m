//
//  JSONRPCMethodCall.m
//  JSONRPC
//
//  Created by Olivier on 01/05/10.
//  Copyright 2010 AliSoftware. All rights reserved.
//

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

+(id)methodCallWithMethodName:(NSString*)methodName parameters:(NSArray*)params
{
	return [[[JSONRPCMethodCall alloc] initWithMethodName:methodName parameters:params] autorelease];
}
+(id)methodCallWithMethodNameAndParams:(NSString*)methodName, ...
{
	va_list ap;
	va_start(ap, methodName);
	id ret = [[[JSONRPCMethodCall alloc] initWithMethodName:methodName parametersList:ap notifyOnly:NO] autorelease];
	va_end(ap);
	return ret;
}
+(id)notificationWithName:(NSString*)methodName parameters:(NSArray*)params
{
	return [[[JSONRPCMethodCall alloc] initWithMethodName:methodName parameters:params notifyOnly:YES] autorelease];
}

-(id)initWithMethodName:(NSString*)methodName parameters:(NSArray*)params {
	return [self initWithMethodName:methodName parameters:params notifyOnly:NO];
}
-(id)initWithMethodNameAndParams:(NSString *)methodName, ...
{	
	va_list ap;
	va_start(ap, methodName);
	id ret = [self initWithMethodName:methodName parametersList:ap notifyOnly:NO];
	va_end(ap);
	return ret;
}
-(id)initWithMethodName:(NSString *)methodName parametersList:(va_list)paramsList notifyOnly:(BOOL)notifyOnly
{
	NSMutableArray* args = [NSMutableArray array];
	id obj;
	while(obj = va_arg(paramsList,id)) [args addObject:obj];
	return [self initWithMethodName:methodName parameters:args notifyOnly:notifyOnly];
}

-(id)initWithMethodName:(NSString*)methodName parameters:(NSArray*)params notifyOnly:(BOOL)notifyOnly
{
	self = [super init];
	if (self != nil) {
		self.methodName = methodName;
		self.parameters = params;
		_uuid = notifyOnly ? nil : [generateUUID() retain];
	}
	return self;	
}

-(id)proxyForJson {
	return [NSDictionary dictionaryWithObjectsAndKeys:
			_methodName,@"method",
			((id)_parameters?:(id)[NSNull null]),@"params",
			_uuid,@"id",
			nil];
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
	[super dealloc];
}
@end




@implementation JSONRPCMethodCall_v2_0
+(id)methodCallWithMethodName:(NSString*)methodName namedParameters:(NSDictionary*)params
{
	return [[[JSONRPCMethodCall_v2_0 alloc] initWithMethodName:methodName namedParameters:params] autorelease];
}
+(id)methodCallWithMethodNameAndNamedParams:(NSString *)methodName, ... {
	va_list ap;
	va_start(ap, methodName);
	id ret = [[[JSONRPCMethodCall_v2_0 alloc] initWithMethodName:methodName namedParametersList:ap notifyOnly:NO] autorelease];
	va_end(ap);
	return ret;
}
+(id)notificationWithName:(NSString*)methodName namedParameters:(NSDictionary*)params
{
	return [[[JSONRPCMethodCall alloc] initWithMethodName:methodName namedParameters:params notifyOnly:YES] autorelease];
}
-(id)initWithMethodName:(NSString*)methodName namedParameters:(NSDictionary*)params {
	return [self initWithMethodName:methodName namedParameters:params notifyOnly:NO];
}
-(id)initWithMethodNameAndNamedParams:(NSString *)methodName, ...
{	
	va_list ap;
	va_start(ap, methodName);
	id ret = [self initWithMethodName:methodName namedParametersList:ap notifyOnly:NO];
	va_end(ap);
	return ret;
}
-(id)initWithMethodName:(NSString*)methodName namedParametersList:(va_list)paramsList notifyOnly:(BOOL)notifyOnly
{
	NSMutableDictionary* args = [NSMutableDictionary dictionary];
	id obj;
	NSString* key;
	while(obj = va_arg(paramsList,id)) {
		key = va_arg(paramsList,NSString*);
		[args setObject:obj forKey:key];
	}
	return [self initWithMethodName:methodName namedParameters:args  notifyOnly:notifyOnly];
}
-(id)initWithMethodName:(NSString*)methodName namedParameters:(NSDictionary*)params notifyOnly:(BOOL)notifyOnly
{
	self = [super init];
	if (self != nil) {
		self.methodName = methodName;
		self.parameters = params;
		_uuid = notifyOnly ? nil : [generateUUID() retain];
	}
	return self;	
}

-(id)proxyForJson {
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"2.0",@"jsonrpc",
			_methodName,@"method",
			((id)_parameters?:(id)[NSNull null]),@"params",
			_uuid,@"id",
			nil];
}

@end