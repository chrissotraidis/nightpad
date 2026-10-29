#import <UIKit/UIKit.h>

// A short reference for the Xbox controls NightPad sends: on foot, in vehicles
// and in menus. The vehicle rows follow the game's own drivecfg.def/POV
// definitions rather than guessed PC bindings.
@interface NightPadControlsHelpViewController : UIViewController
@property(nonatomic, copy) void (^onClose)(void);
@end
