#import <UIKit/UIKit.h>

#import "NightPadMetalProbe.h"
#import "NightPadMediaProbe.h"

int NightfireGameWindowTestMain(int argc, char **argv);

static NSString *gPointerResult = @"Pointer probe not run";
static NSString *gMetalResult = @"Metal probe not run";
static NSString *gMediaResult = @"Media probe not run";

@interface NightPadProbeController : UIViewController
@property(nonatomic, strong) UILabel *label;
@end

@implementation NightPadProbeController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor colorWithRed:0.035 green:0.055 blue:0.09 alpha:1.0];
  self.label = [[UILabel alloc] initWithFrame:self.view.bounds];
  self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.label.numberOfLines = 0;
  self.label.textAlignment = NSTextAlignmentCenter;
  self.label.textColor = UIColor.whiteColor;
  self.label.font = [UIFont monospacedSystemFontOfSize:18 weight:UIFontWeightMedium];
  self.label.accessibilityIdentifier = @"nightpad.probe.status";
  [self.view addSubview:self.label];
  [self refresh];
  [self runProbes];
}

- (void)refresh {
  self.label.text = [NSString stringWithFormat:@"NightPad platform probe\n\n%@\n%@\n%@",
                                               gPointerResult, gMetalResult, gMediaResult];
}

- (void)runProbes {
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    char operations[] = "200000";
    char program[] = "NightPadProbe";
    char *argv[] = {program, operations, NULL};
    int status = NightfireGameWindowTestMain(2, argv);
    NSString *pointer = status == 0 ? @"Pointer/linker/heap: PASS"
                                    : [NSString stringWithFormat:@"Pointer/linker/heap: FAIL (%d)", status];
    NSString *metalError = NightPadRunMetalProbe();
    NSString *metal = metalError ?: @"Metal shader/readback: PASS";
    NSString *media = NightPadRunMediaProbe();
    dispatch_async(dispatch_get_main_queue(), ^{
      gPointerResult = pointer;
      gMetalResult = metal;
      gMediaResult = media;
      [self refresh];
      NSDictionary *results = @{
        @"schema_version": @1,
        @"pointer_window_base": @"0x100000000",
        @"pointer_operations": @200000,
        @"pointer": pointer,
        @"metal": metal,
        @"media": media,
        @"passed": @([pointer containsString:@"PASS"] &&
                     [metal containsString:@"PASS"] &&
                     [media containsString:@"PASS"]),
      };
      NSData *json = [NSJSONSerialization dataWithJSONObject:results
                                                     options:NSJSONWritingPrettyPrinted
                                                       error:nil];
      NSURL *caches = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory
                                                              inDomains:NSUserDomainMask] firstObject];
      [json writeToURL:[caches URLByAppendingPathComponent:@"nightpad-probe-result.json"]
            atomically:YES];
      NSLog(@"NightPadProbeResult %@", [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding]);
    });
  });
}

@end

@interface NightPadProbeAppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow *window;
@end

@implementation NightPadProbeAppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
  self.window.rootViewController = [[NightPadProbeController alloc] init];
  [self.window makeKeyAndVisible];
  return YES;
}

@end

int main(int argc, char **argv) {
  @autoreleasepool {
    return UIApplicationMain(argc, argv, nil, NSStringFromClass(NightPadProbeAppDelegate.class));
  }
}

