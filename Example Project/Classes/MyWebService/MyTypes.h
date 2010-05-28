//
//  MyTypes.h
//  JSONRPCExample
//
//  Created by Olivier on 04/05/10.
//  Copyright 2010 AliSoftware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef NSInteger FourSquareID;



/////////////////////////////////////////////////////////////////////////////
// MARK: Parent class to wrap JSON-based objects
/////////////////////////////////////////////////////////////////////////////

@interface ValueObject : NSObject {
	NSDictionary* _jsonData;
}
-(id)initWithJson:(NSDictionary*)dict;
-(id)proxyForJson;
@end


/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: Person
/////////////////////////////////////////////////////////////////////////////

@interface Person : ValueObject
@property(nonatomic, readonly) NSString* firstName;
@property(nonatomic, readonly) NSString* lastName;
@end


/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: Couple
/////////////////////////////////////////////////////////////////////////////

@interface Couple : ValueObject
@property(nonatomic, readonly) Person* husband;
@property(nonatomic, readonly) Person* wife;
@end


/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: ServiceDef
/////////////////////////////////////////////////////////////////////////////

@interface ServiceDef : ValueObject
@property(nonatomic, readonly) NSString* objectName;
@property(nonatomic, readonly) NSURL* serviceURL;
@property(nonatomic, readonly) NSArray* methods;
@end

@interface MethodDef : ValueObject
@property(nonatomic, readonly) NSString* name;
@property(nonatomic, readonly) NSArray* parameters;
@end

@interface ParamDef : ValueObject
@property(nonatomic, readonly) NSString* name;
@end
