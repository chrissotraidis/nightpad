#import <UIKit/UIKit.h>

#include "../shared/NightPadInput.h"
#include "../shared/NightPadTouchInput.h"
#include "../shared/NightPadTouchLayout.h"

// One drawn Xbox control. The live overlay and the layout editor use the same
// view, so what you arrange is exactly what you play with.
@interface NightPadOverlayControlView : UIView
@property(nonatomic, readonly) nightpad::TouchControlId controlId;
@property(nonatomic, assign) CGFloat displayAlpha;
- (instancetype)initWithControl:(const nightpad::TouchControl &)control;
@end

// The in-game Xbox touch surface. It renders the authored layout above the
// engine window, keeps every control's touch independent so move, look, fire
// and aim work together, and publishes the resulting pad. The surface passes
// untouched points through, so the shell's menu button stays usable while the
// controls are visible.
@interface NightPadTouchControlsView : UIView

@property(nonatomic, copy) void (^touchStateChanged)(void);
@property(nonatomic, readonly) BOOL controlsHidden;
// One opacity for every control (0.2 to 1).
@property(nonatomic, assign) CGFloat controlOpacity;

- (void)setTouchLayout:(const nightpad::TouchLayout &)layout;
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated;
- (nightpad::PadState)currentPad;
// Drops every finger without emitting a release edge; use on pause and when the
// native menu covers the surface.
- (void)releaseAllTouches;

@end
