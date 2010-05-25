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




- (void)dealloc {
    [window release];
    [super dealloc];
}


@end
