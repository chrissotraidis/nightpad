#import <UIKit/UIKit.h>

// A local report the player can read before explicitly sharing it. It never
// uploads anything by itself.
@interface NightPadDiagnosticsViewController : UIViewController
@property(nonatomic, copy) void (^onClose)(void);
- (instancetype)initWithReport:(NSString *)report reportURL:(NSURL *)reportURL;
@end
