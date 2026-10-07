#import <Cordova/CDVPlugin.h>

@interface IonicDeeplinkPlugin : CDVPlugin {
  // Handlers for URL events
  NSMutableArray *_handlers;
  CDVPluginResult *_lastEvent;
}

// User-plugin command handler
- (void)canOpenApp:(CDVInvokedUrlCommand *)command;
- (void)onDeepLink:(CDVInvokedUrlCommand *)command;
- (void)getHardwareInfo:(CDVInvokedUrlCommand *)command;

// Internal deeplink and CUA handlers
- (BOOL)handleLink:(NSURL *)url;
- (BOOL)handleContinueUserActivity:(NSUserActivity *)userActivity;

// Holds a universal link that arrived before any plugin instance existed
// (cold start via the scene delegate). Consumed once in pluginInitialize.
+ (void)queuePendingUserActivity:(NSUserActivity *)userActivity;

- (void)sendToJs;

- (CDVPluginResult*)createResult:(NSURL *)url;

@end
