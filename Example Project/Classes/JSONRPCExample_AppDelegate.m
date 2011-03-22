//
//  JSONRPC_FrameworkAppDelegate.m
//  JSONRPC Framework
//
//  Created by Olivier on 20/05/10.
//  Copyright AliSoftware 2010. All rights reserved.
//

#import "JSONRPCExample_AppDelegate.h"
#import "MyWebService.h"

@implementation JSONRPCExample_AppDelegate
@synthesize window;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    [window makeKeyAndVisible];
}


-(IBAction)getAuthorDemo {
	[[MyWebService defaultService] getAuthorWithDelegate:self callback:@selector(methodCall:gotAuthor:error:)];
}
-(void)methodCall:(JSONRPCMethodCall*)mc gotAuthor:(Person*)author error:(NSError*)err {
	NSLog(@"%@ result:%@ error:%@",mc,author,err);
	logView.text = [author description];
}

-(IBAction)getCoupleDemo {
	[[MyWebService defaultService] getCoupleWithDelegate:self callback:@selector(methodCall:gotCouple:error:)];
}
-(void)methodCall:(JSONRPCMethodCall*)mc gotCouple:(Couple*)couple error:(NSError*)err {
	NSLog(@"%@ result:%@ error:%@",mc,couple,err);
	logView.text = [couple description];
}

-(IBAction)addTwoValuesDemo {
	[[MyWebService defaultService] addValue:8 withValue:13 delegate:self callback:@selector(methodCall:gotMathResult:error:)];
}
-(IBAction)sumValuesDemo {
	[[MyWebService defaultService] getSumOfValues:mkArray(mkInt(3),mkInt(5),mkInt(24),mkInt(9))
										 delegate:self callback:@selector(methodCall:gotMathResult:error:)];
}
-(void)methodCall:(JSONRPCMethodCall*)mc gotMathResult:(NSNumber*)result error:(NSError*)err {
	NSLog(@"%@ result:%d error:%@",mc,[result intValue],err);
	logView.text = [NSString stringWithFormat:@"sum of %@ = %d",mc.parameters,[result intValue]];
}
-(IBAction)echoMethodDemo {
	NSURL* serviceURL = [NSURL URLWithString:@"http://www.raboof.com/Projects/Jayrock/Demo.ashx"];
	JSONRPCService* s = [JSONRPCService serviceWithURL:serviceURL version:JSONRPCVersion_1_1];
	s.delegate = self; // we are using the JSONRPCService's delegate here, not the one in JSONRPCResponseHandler.
	//[s callMethodWithName:@"echo" namedParameters:mkDict(@"Hello",@"text")];
	[s.proxy echo:mkDict(@"Hello",@"text")]; // Warning: No '-echo:' method found, but this is normal, it is not a real method and will be handled by the proxy object magically and transformed to a JSON-RPC call!
	// the response will be handled in the current object (as s.delegate = self)
	// in the "methodCall:didReturn:error:" method (as we will not override the "callback" of the JSONRPCResponseHandler,
	// the default method defined in the JSONRPCDelegate @protocol will be called)
}
-(void)methodCall:(JSONRPCMethodCall *)mc didReturn:(id)result error:(NSError *)error {
	if ([mc.methodName isEqualToString:@"echo"])
	{
		logView.text = [NSString stringWithFormat:@"echo method did return: %@ (error: %@)",result,error];
	} else {
		logView.text = [NSString stringWithFormat:@"JSON-RPC response received for a unexpected method (%@)",mc.methodName];
	}
}

-(IBAction)serviceDescr {
	[[MyWebService defaultService] getServiceDescriptionWithDelegate:self callback:@selector(methodCall:didReturnSystemDescritiption:error:)];
}
-(void)methodCall:(JSONRPCMethodCall*)mc didReturnSystemDescritiption:(ServiceDef*)def error:(NSError*)err {
	NSLog(@"%@ result:%@ error:%@",mc,def,err);
	logView.text = [NSString stringWithFormat:@"Service Definition: %@",def];
}

- (void)dealloc {
    [window release];
    [super dealloc];
}


@end
