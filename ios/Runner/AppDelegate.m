#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"

#include <Lndmobile/Lndmobile.h>

FlutterMethodChannel* lndChannel;

// An implementation of a LndmobileCallback that passes the result of the call back to flutter.
@interface FlutterResultLndCallback : NSObject <LndmobileCallback>
@property FlutterResult resultCb;
- (id)initWithFlutterResult:(FlutterResult)result;
@end

@implementation FlutterResultLndCallback
- (id)initWithFlutterResult:(FlutterResult)result {
  _resultCb = result;
  return self;
}
- (void)onError:(NSError*)p0 {
  _resultCb(p0);
}
- (void)onResponse:(NSData*)p0 {
  if (p0 == nil) {
    // Send back an empty payload for nil responses. This allows dart to parse it properly.
    NSMutableData *empty = [[NSMutableData alloc] init];
    _resultCb([FlutterStandardTypedData typedDataWithBytes:empty]);
  } else {
    _resultCb([FlutterStandardTypedData typedDataWithBytes:p0]);
  }
}
@end


@interface StreamingCallHandler : NSObject<FlutterStreamHandler>
@end

@implementation StreamingCallHandler {
  FlutterEventSink _eventSink;
}

- (void)sendBatteryStateEvent:(FlutterStandardTypedData*)streamId data:(FlutterStandardTypedData*)data {
  NSLog(@"Sending event on stream id %@", streamId);
  if (!_eventSink) return;
  _eventSink(@[streamId, data]);
}

#pragma mark FlutterStreamHandler impl

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
  NSLog(@"onListenWithArguments");
  _eventSink = eventSink;
  return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
  _eventSink = nil;
  return nil;
}

@end


// A streaming implementation of a LndmobileCallback that passes the result of the call back to flutter.
@interface FlutterStreamingResultLndCallback : NSObject <LndmobileCallback>
@property StreamingCallHandler* resultCb;
@property FlutterStandardTypedData* streamId;
- (id)initWithStreamingCallHandler:(StreamingCallHandler*)result streamId:(FlutterStandardTypedData*)streamId;
@end

@implementation FlutterStreamingResultLndCallback
- (id)initWithStreamingCallHandler:(StreamingCallHandler*)result streamId:(FlutterStandardTypedData*)streamId {
  _resultCb = result;
  _streamId = streamId;
  return self;
}
- (void)onError:(NSError*)p0 {
//  _resultCb(p0);
}
- (void)onResponse:(NSData*)p0 {
  FlutterStandardTypedData* d = [FlutterStandardTypedData typedDataWithBytes:p0];
  [_resultCb sendBatteryStateEvent:_streamId data:d];
}
@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];

  // The path we'll store all LND data.
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *dir = [paths objectAtIndex:0];

#ifndef DEBUG
  // Redirect stderr to a file, note that it will no longer appear in the console.
  NSString *logFilePath = [dir stringByAppendingPathComponent:@"stderr.log"];
  freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a", stderr);
  NSString *logFilePath2 = [dir stringByAppendingPathComponent:@"stdout.log"];
  freopen([logFilePath2 cStringUsingEncoding:NSASCIIStringEncoding], "a", stdout);
#endif
  
  FlutterViewController* controller =
  (FlutterViewController*)self.window.rootViewController;
  
  StreamingCallHandler* instance = [[StreamingCallHandler alloc] init];
  FlutterEventChannel* eventChannel =
  [FlutterEventChannel eventChannelWithName:@"rpcstreaming"
                            binaryMessenger:controller];
  [eventChannel setStreamHandler:instance];

  lndChannel = [FlutterMethodChannel methodChannelWithName:@"rpc"
                                      binaryMessenger:controller];
  [lndChannel setMethodCallHandler:^(FlutterMethodCall* call,
                                     FlutterResult result) {
    NSLog(@"Call for %@", call.method);
    if ([@"Start" isEqualToString:call.method]) {
      // Create a minimal config file for LND.
      NSString *fileName = [NSString stringWithFormat:@"%@/lnd.conf", dir];
      NSString *content = @"[Application Options]\ndebuglevel=debug\nnoencryptwallet=1\nnobootstrap=1\n\n[Bitcoin]\nbitcoin.active=1\nbitcoin.testnet=1\nbitcoin.node=neutrino\n\n[Neutrino]\nneutrino.connect=sg.horlick.me:18333\n";
      [content writeToFile:fileName
                atomically:NO
                  encoding:NSUTF8StringEncoding
                     error:nil];
      LndmobileStart(dir, [[FlutterResultLndCallback alloc] initWithFlutterResult:result]);
    } else if ([@"/lnrpc.Lightning/GetInfo" isEqualToString:call.method]) {
      FlutterStandardTypedData *msg = call.arguments[@"req"];
      LndmobileGetInfo(msg.data, [[FlutterResultLndCallback alloc] initWithFlutterResult:result]);
    } else if ([@"/lnrpc.Lightning/WalletBalance" isEqualToString:call.method]) {FlutterStandardTypedData *msg = call.arguments[@"req"];LndmobileWalletBalance(msg.data, [[FlutterResultLndCallback alloc] initWithFlutterResult:result]);
    } else if ([@"/lnrpc.Lightning/ChannelBalance" isEqualToString:call.method]) {FlutterStandardTypedData *msg = call.arguments[@"req"];LndmobileChannelBalance(msg.data, [[FlutterResultLndCallback alloc] initWithFlutterResult:result]);
    } else if ([@"/lnrpc.Lightning/ListPayments" isEqualToString:call.method]) {FlutterStandardTypedData *msg = call.arguments[@"req"];LndmobileListPayments(msg.data, [[FlutterResultLndCallback alloc] initWithFlutterResult:result]);
    } else if ([@"/lnrpc.Lightning/ListInvoices" isEqualToString:call.method]) {FlutterStandardTypedData *msg = call.arguments[@"req"];LndmobileListInvoices(msg.data, [[FlutterResultLndCallback alloc] initWithFlutterResult:result]);
    } else if ([@"/lnrpc.Lightning/LookupInvoice" isEqualToString:call.method]) {FlutterStandardTypedData *msg = call.arguments[@"req"];LndmobileLookupInvoice(msg.data, [[FlutterResultLndCallback alloc] initWithFlutterResult:result]);
    } else if ([@"/lnrpc.Lightning/AddInvoice" isEqualToString:call.method]) {FlutterStandardTypedData *msg = call.arguments[@"req"];LndmobileAddInvoice(msg.data, [[FlutterResultLndCallback alloc] initWithFlutterResult:result]);
    } else if ([@"/lnrpc.Lightning/ConnectPeer" isEqualToString:call.method]) {FlutterStandardTypedData *msg = call.arguments[@"req"];LndmobileConnectPeer(msg.data, [[FlutterResultLndCallback alloc] initWithFlutterResult:result]);
    } else if ([@"/lnrpc.Lightning/PendingChannels" isEqualToString:call.method]) {FlutterStandardTypedData *msg = call.arguments[@"req"];LndmobilePendingChannels(msg.data, [[FlutterResultLndCallback alloc] initWithFlutterResult:result]);
    } else if ([@"/lnrpc.Lightning/ListChannels" isEqualToString:call.method]) {FlutterStandardTypedData *msg = call.arguments[@"req"];LndmobileListChannels(msg.data, [[FlutterResultLndCallback alloc] initWithFlutterResult:result]);
    } else if ([@"/lnrpc.Lightning/GetNetworkInfo" isEqualToString:call.method]) {FlutterStandardTypedData *msg = call.arguments[@"req"];LndmobileGetNetworkInfo(msg.data, [[FlutterResultLndCallback alloc] initWithFlutterResult:result]);
    } else if ([@"/lnrpc.Lightning/GetTransactions" isEqualToString:call.method]) {FlutterStandardTypedData *msg = call.arguments[@"req"];LndmobileGetTransactions(msg.data, [[FlutterResultLndCallback alloc] initWithFlutterResult:result]);
    } else if ([@"/lnrpc.Lightning/NewAddress" isEqualToString:call.method]) {FlutterStandardTypedData *msg = call.arguments[@"req"];LndmobileNewAddress(msg.data, [[FlutterResultLndCallback alloc] initWithFlutterResult:result]);
    } else if ([@"/lnrpc.Lightning/DecodePayReq" isEqualToString:call.method]) {FlutterStandardTypedData *msg = call.arguments[@"req"];LndmobileDecodePayReq(msg.data, [[FlutterResultLndCallback alloc] initWithFlutterResult:result]);
    } else if ([@"/lnrpc.Lightning/SendPaymentSync" isEqualToString:call.method]) {FlutterStandardTypedData *msg = call.arguments[@"req"];LndmobileSendPaymentSync(msg.data, [[FlutterResultLndCallback alloc] initWithFlutterResult:result]);
    } else if ([@"/lnrpc.Lightning/SubscribeTransactions" isEqualToString:call.method]) {
      FlutterStandardTypedData *msg = call.arguments[@"req"];
      FlutterStandardTypedData *streamId = call.arguments[@"streamId"];
      FlutterStreamingResultLndCallback* cb = [[FlutterStreamingResultLndCallback alloc] initWithStreamingCallHandler:instance streamId:streamId];
      NSLog(@"Streaming using id %@", streamId);
      LndmobileSubscribeTransactions(msg.data, cb);
    } else {
      result(FlutterMethodNotImplemented);
    }
  }];
  
  NSLog(@"Starting app...");

  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  NSLog(@"applicationDidBecomeActive");
//  ClientResume();
  [lndChannel invokeMethod:@"resume" arguments:nil];
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
//  ClientStop();
  [super applicationWillTerminate:application];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  NSLog(@"applicationDidEnterBackground");
  [lndChannel invokeMethod:@"pause" arguments:nil];
//  ClientPause();
  [super applicationDidEnterBackground:application];
}

@end
