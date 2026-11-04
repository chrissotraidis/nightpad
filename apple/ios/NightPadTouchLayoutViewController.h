#import <UIKit/UIKit.h>

#include "../shared/NightPadTouchLayout.h"

// Full-screen touch-layout editor. Tap a control to select it (grouped controls
// select together), drag to move, pinch anywhere or use the slider to resize.
// Opacity is one setting for every control.
@interface NightPadTouchLayoutViewController : UIViewController

- (instancetype)initWithLayout:(nightpad::TouchLayout)layout
                      savePath:(NSURL *)savePath
                opacityPercent:(int)opacityPercent;

@property(nonatomic, copy) void (^onClose)(void);
// Set when Save succeeded; opacityPercent is then the chosen overlay opacity.
@property(nonatomic, readonly) BOOL saved;
@property(nonatomic, readonly) int opacityPercent;

@end
