#import <Cordova/CDVSceneDelegate.h>
#import <Cordova/CDVViewController.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "IonicDeeplinkPlugin.h"

static NSString *const PLUGIN_NAME = @"IonicDeeplinkPlugin";

/**
 * Category on CDVSceneDelegate that forwards NSUserActivity (universal links)
 * to IonicDeeplinkPlugin. Required because on iOS 13+ with cordova-ios 8's
 * scene-based lifecycle, AppDelegate's application:continueUserActivity: is
 * never invoked — iOS routes universal links to the scene delegate instead.
 */
@interface CDVSceneDelegate (IonicDeeplink)
@end

@implementation CDVSceneDelegate (IonicDeeplink)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = [CDVSceneDelegate class];

        // Swizzle scene:willConnectToSession:options: so we can inspect
        // connectionOptions.userActivities for cold-start universal links.
        SEL originalSel = @selector(scene:willConnectToSession:options:);
        SEL swizzledSel = @selector(ionic_scene:willConnectToSession:options:);
        Method originalMethod = class_getInstanceMethod(cls, originalSel);
        Method swizzledMethod = class_getInstanceMethod(cls, swizzledSel);
        if (originalMethod && swizzledMethod) {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)ionic_scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    // Call through to the original CDVSceneDelegate implementation
    // (handles URLContexts). After swizzling this refers to the original.
    [self ionic_scene:scene willConnectToSession:session options:connectionOptions];

    // Cold-start universal link: iOS delivers the NSUserActivity in
    // connectionOptions.userActivities, NOT via scene:continueUserActivity:.
    for (NSUserActivity *userActivity in connectionOptions.userActivities) {
        [self ionic_handleUserActivity:userActivity];
    }
}

- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity {
    // Warm resume universal link (app already running / in background).
    [self ionic_handleUserActivity:userActivity];
}

- (void)ionic_handleUserActivity:(NSUserActivity *)userActivity {
    if (![userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb] || userActivity.webpageURL == nil) {
        return;
    }

    CDVViewController *cdvVC = [self ionic_findCDVViewController];
    if (cdvVC == nil) {
        NSLog(@"IonicDeepLinkPlugin: CDVViewController not found in scene window");
        return;
    }

    IonicDeeplinkPlugin *plugin = [cdvVC getCommandInstance:PLUGIN_NAME];
    if (plugin == nil) {
        NSLog(@"IonicDeepLinkPlugin: Unable to get plugin instance from CDVViewController");
        return;
    }

    NSLog(@"IonicDeepLinkPlugin: Forwarding scene user activity %@", userActivity.webpageURL);
    [plugin handleContinueUserActivity:userActivity];
}

- (CDVViewController *)ionic_findCDVViewController {
    UIViewController *root = self.window.rootViewController;
    if ([root isKindOfClass:[CDVViewController class]]) {
        return (CDVViewController *)root;
    }

    // Walk children in case CDVViewController is embedded in a container.
    for (UIViewController *child in root.childViewControllers) {
        if ([child isKindOfClass:[CDVViewController class]]) {
            return (CDVViewController *)child;
        }
    }
    return nil;
}

@end
