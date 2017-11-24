#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"

#include <Client/Client.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];

  // The path we'll store all LND data.
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *dir = [paths objectAtIndex:0];
  
  FlutterViewController* controller =
  (FlutterViewController*)self.window.rootViewController;
  
  FlutterMethodChannel* lndChannel = [FlutterMethodChannel
                                      methodChannelWithName:@"wallet_init_channel"
                                      binaryMessenger:controller];
  [lndChannel setMethodCallHandler:^(FlutterMethodCall* call,
                                     FlutterResult result) {
    if ([@"createMnemonic" isEqualToString:call.method]) {
      NSError* err = NULL;
      NSString* mnemonic = ClientCreateBip39Seed(&err);
      result(mnemonic);
    } else if ([@"start" isEqualToString:call.method]) {
      NSLog(@"Calling ClientStart with argument '%@'", call.arguments);
      NSError* err = NULL;
      ClientStart(dir, call.arguments, &err);
      NSLog(@"ClientStart returned: %@", err);
      result(err);
    } else if ([@"walletExists" isEqualToString:call.method]) {
      result(@(ClientWalletExists(call.arguments)));
    } else {
      result(FlutterMethodNotImplemented);
    }
  }];

  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  NSLog(@"applicationDidBecomeActive");
  ClientResume();
  [super applicationDidBecomeActive:application];
}

- (void)applicationWillResignActive:(UIApplication *)application {
  NSLog(@"applicationWillResignActive");
  [super applicationWillResignActive:application];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  NSLog(@"applicationWillEnterForeground");
  [super applicationWillEnterForeground:application];
}

- (void)applicationWillTerminate:(UIApplication *)application {
  NSLog(@"applicationWillTerminate");
  ClientStop();
  [super applicationWillTerminate:application];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  NSLog(@"applicationDidEnterBackground");
  ClientPause();
  [super applicationDidEnterBackground:application];
}

@end
