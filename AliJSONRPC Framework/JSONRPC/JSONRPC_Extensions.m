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

#import "JSONRPC_Extensions.h"
#import "JSONRPC.h"

/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: NSError category for JSON
/////////////////////////////////////////////////////////////////////////////

@implementation NSError(JSON)
-(id)data {
	id jsonObj = [[self userInfo] objectForKey:JSONRPCErrorJSONObjectKey];
	if (jsonObj && [jsonObj isKindOfClass:[NSDictionary class]])
		return [jsonObj objectForKey:@"data"];
	else
		return nil;
}
@end


/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: NSArray category for JSON
/////////////////////////////////////////////////////////////////////////////

@implementation NSArray(JSON)
+(id)arrayWithJson:(NSArray *)arrayOfJsonObjects itemsClass:(Class)itemsClass {
	return [[[self alloc] initWithJson:arrayOfJsonObjects itemsClass:itemsClass] autorelease];
}
-(id)initWithJson:(NSArray *)arrayOfJsonObjects itemsClass:(Class)itemsClass
{
	NSMutableArray* tab = [[NSMutableArray alloc] initWithCapacity:[arrayOfJsonObjects count]];
	for(id jsonObj in arrayOfJsonObjects)
	{
		id obj = [[[itemsClass alloc] initWithJson:jsonObj] autorelease];
		if (!obj) obj = [NSNull null];
		[tab addObject:obj];
	}
	self = [self initWithArray:tab];
	[tab release];
	
	return self;
}
@end
