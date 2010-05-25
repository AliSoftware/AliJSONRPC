//
//  JSONRPC_FrameworkAppDelegate.h
//  JSONRPC Framework
//
//  Created by Olivier on 20/05/10.
//  Copyright AliSoftware 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSONRPC.h"

@interface JSONRPCExample_AppDelegate : NSObject <UIApplicationDelegate, JSONRPCDelegate> {
    UIWindow *window;
	IBOutlet UITextView* logView;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

-(IBAction)getAuthorDemo;
-(IBAction)getCoupleDemo;
-(IBAction)addTwoValuesDemo;
-(IBAction)sumValuesDemo;
-(IBAction)echoMethodDemo;
@end

