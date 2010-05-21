//
//  MyTypes.m
//  JSONRPCExample
//
//  Created by Olivier on 04/05/10.
//  Copyright 2010 AliSoftware. All rights reserved.
//

#import "MyTypes.h"

/////////////////////////////////////////////////////////////////////////////
// MARK: Parent class to wrap JSON-based objects
/////////////////////////////////////////////////////////////////////////////
@implementation ValueObject
-(id)initWithJson:(NSDictionary*)dict {
	self = [super init];
	if (self != nil) {
		_jsonData = [dict retain];
	}
	return self;
}
-(id)proxyForJson {
	return [[_jsonData retain] autorelease];
}
-(NSString*)description {
	return [NSString stringWithFormat:@"<%@ %@>",NSStringFromClass([self class]),_jsonData];
}
-(void)dealloc {
	[_jsonData release];
	[super dealloc];
}
@end



/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: Person
/////////////////////////////////////////////////////////////////////////////

@implementation Person
-(NSString*)firstName { return [_jsonData objectForKey:@"FirstName"]?:[_jsonData objectForKey:@"firstName"]; } // getCouple and getAuthor does not use the same case "first"/"First"... pfff...
-(NSString*)lastName { return [_jsonData objectForKey:@"LastName"]?:[_jsonData objectForKey:@"lastName"]; } // getCouple and getAuthor does not use the same case "last"/"Last"... pfff...
-(NSString*)description { return [NSString stringWithFormat:@"<Person \"%@ %@\">",self.firstName,self.lastName]; }
@end


/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: Couple
/////////////////////////////////////////////////////////////////////////////

@implementation Couple
-(Person*)husband { return [[[Person alloc] initWithJson:[_jsonData objectForKey:@"husband"]] autorelease]; }
-(Person*)wife { return [[[Person alloc] initWithJson:[_jsonData objectForKey:@"wife"]] autorelease]; }
-(NSString*)description { return [NSString stringWithFormat:@"<Couple (%@ + %@)>",self.husband,self.wife]; }
@end

