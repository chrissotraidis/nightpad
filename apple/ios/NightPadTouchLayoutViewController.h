#import <UIKit/UIKit.h>

#include "../shared/NightPadTouchLayout.h"

// Native drag/resize editor for the authored phone/tablet touch geometry.
@interface NightPadTouchLayoutViewController : UIViewController
@property(nonatomic, copy) void (^onClose)(void);
- (instancetype)initWithLayout:(nightpad::TouchLayout)layout savePath:(NSURL *)savePath;
@end
