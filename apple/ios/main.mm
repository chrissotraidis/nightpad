#import <UIKit/UIKit.h>

#define SDL_MAIN_HANDLED 1
#include <SDL3/SDL_main.h>

#import "NightPadShellViewController.h"

@interface NightPadAppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow *window;
@end

@implementation NightPadAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    (void)application;
    (void)options;
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [NightPadShellViewController new];
    [self.window makeKeyAndVisible];
    return YES;
}
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
