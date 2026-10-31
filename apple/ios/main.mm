#import <UIKit/UIKit.h>

#define SDL_MAIN_HANDLED 1
#include <SDL3/SDL_main.h>

#import "NightPadShellViewController.h"

// iOS 27 requires the UIScene lifecycle: the window belongs to the scene.
@interface NightPadSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, strong) UIWindow *window;
@end

@implementation NightPadSceneDelegate
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session
      options:(UISceneConnectionOptions *)options {
    (void)session;
    (void)options;
    if (![scene isKindOfClass:UIWindowScene.class])
        return;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.rootViewController = [NightPadShellViewController new];
    [self.window makeKeyAndVisible];
}
@end

@interface NightPadAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation NightPadAppDelegate
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        // NightPad owns the UIKit entry point, so SDL's iOS main wrapper is not
        // installed. Tell SDL that this is the process main thread before the
        // engine initializes its video, audio and gamepad subsystems.
        SDL_SetMainReady();
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([NightPadAppDelegate class]));
    }
}
