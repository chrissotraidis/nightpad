#import "NightPadTouchControlsView.h"

#import <QuartzCore/QuartzCore.h>

#include "../shared/NightPadControlPalette.h"   // AccessibilityOrderForControl

#include <algorithm>
#include <cmath>
#include <vector>

using nightpad::TouchControl;
using nightpad::TouchControlId;

namespace {

constexpr CGFloat kCanvasMargin = 8.0;
constexpr float kDpadDeadZone = 0.22f;

NSString *ControlLabel(TouchControlId id) {
    switch (id) {
        case TouchControlId::LeftStick: return @"L";
        case TouchControlId::RightStick: return @"R";
        case TouchControlId::Dpad: return @"D-PAD";
        case TouchControlId::A: return @"A";
        case TouchControlId::B: return @"B";
        case TouchControlId::X: return @"X";
        case TouchControlId::Y: return @"Y";
        case TouchControlId::LeftTrigger: return @"LT";
        case TouchControlId::RightTrigger: return @"RT";
        case TouchControlId::White: return @"WHT";
        case TouchControlId::Black: return @"BLK";
        case TouchControlId::Start: return @"START";
        case TouchControlId::Back: return @"BACK";
    }
}

NSString *ControlAccessibilityLabel(TouchControlId id) {
    switch (id) {
        case TouchControlId::LeftStick: return @"Move stick";
        case TouchControlId::RightStick: return @"Look stick";
        case TouchControlId::Dpad: return @"Directional pad";
        case TouchControlId::LeftTrigger: return @"Left trigger";
        case TouchControlId::RightTrigger: return @"Right trigger";
        case TouchControlId::White: return @"White button";
        case TouchControlId::Black: return @"Black button";
        case TouchControlId::Start: return @"Start button";
        case TouchControlId::Back: return @"Back button";
        default: return ControlLabel(id);
    }
}

UIImage *ControlSymbol(TouchControlId id) {
    NSString *name = nil;
    if (id == TouchControlId::Start)
        name = @"line.3.horizontal";
    else if (id == TouchControlId::Back)
        name = @"rectangle.on.rectangle";
    if (name == nil)
        return nil;
    UIImageSymbolConfiguration *configuration =
        [UIImageSymbolConfiguration configurationWithPointSize:18.0 weight:UIImageSymbolWeightBold];
    return [UIImage systemImageNamed:name withConfiguration:configuration];
}

// Xbox shapes: round sticks and face buttons, capsules for Start/Back, and a
// rounded shoulder plate for each trigger.
CGFloat ControlCornerRadius(TouchControlId id, CGSize size) {
    const CGFloat side = std::min(size.width, size.height);
    switch (id) {
        case TouchControlId::LeftStick:
        case TouchControlId::RightStick:
        case TouchControlId::A:
        case TouchControlId::B:
        case TouchControlId::X:
        case TouchControlId::Y:
        case TouchControlId::White:
        case TouchControlId::Black:
            return side * 0.5;
        case TouchControlId::Start:
        case TouchControlId::Back:
            return size.height * 0.5;
        default:
            return 12.0;
    }
}

BOOL IsFaceButton(TouchControlId id) {
    return id == TouchControlId::A || id == TouchControlId::B || id == TouchControlId::X ||
           id == TouchControlId::Y;
}

BOOL IsRoundControl(TouchControlId id) {
    return id == TouchControlId::LeftStick || id == TouchControlId::RightStick || IsFaceButton(id) ||
           id == TouchControlId::White || id == TouchControlId::Black;
}

// Xbox controller finish: the four face-button colours, graphite sticks and
// shoulders, and dark system keys. The layout remains GalaxyPad's touch geometry.
struct ControlStyle {
    UIColor *fill;
    UIColor *text;
};

ControlStyle StyleForControl(TouchControlId id) {
    switch (id) {
        case TouchControlId::A:
            return {[UIColor colorWithRed:0.10 green:0.62 blue:0.30 alpha:0.98],
                    [UIColor colorWithWhite:0.06 alpha:1.0]};
        case TouchControlId::B:
            return {[UIColor colorWithRed:0.92 green:0.16 blue:0.18 alpha:0.98],
                    [UIColor colorWithWhite:0.06 alpha:1.0]};
        case TouchControlId::X:
            return {[UIColor colorWithRed:0.10 green:0.48 blue:0.95 alpha:0.98],
                    [UIColor colorWithWhite:0.06 alpha:1.0]};
        case TouchControlId::Y:
            return {[UIColor colorWithRed:0.95 green:0.76 blue:0.08 alpha:0.98],
                    [UIColor colorWithWhite:0.06 alpha:1.0]};
        case TouchControlId::LeftTrigger:
        case TouchControlId::RightTrigger:
            return {[UIColor colorWithWhite:0.10 alpha:0.96], UIColor.whiteColor};
        case TouchControlId::Start:
        case TouchControlId::Back:
            return {[UIColor colorWithWhite:0.16 alpha:0.96], UIColor.whiteColor};
        case TouchControlId::LeftStick:
        case TouchControlId::RightStick:
            return {[UIColor colorWithWhite:0.055 alpha:0.96], UIColor.whiteColor};
        case TouchControlId::Dpad:
            return {UIColor.clearColor, UIColor.whiteColor};
        case TouchControlId::White:
            return {[UIColor colorWithWhite:0.92 alpha:0.96], [UIColor colorWithWhite:0.06 alpha:1.0]};
        default:
            return {[UIColor colorWithWhite:0.22 alpha:0.88], UIColor.whiteColor};
    }
}

}  // namespace

@interface NightPadOverlayControlView : UIView
@property(nonatomic, assign) nightpad::TouchControlId controlId;
@property(nonatomic, strong) UILabel *label;
@property(nonatomic, strong) UIView *thumb;
@property(nonatomic, strong) UIView *fill;
@property(nonatomic, strong) CAGradientLayer *gloss;
@property(nonatomic, strong) UIView *stickWell;
@property(nonatomic, strong) UIView *thumbHighlight;
@property(nonatomic, strong) UIView *dpadDish;
@property(nonatomic, strong) UIView *dpadHorizontal;
@property(nonatomic, strong) UIView *dpadVertical;
@property(nonatomic, strong) UIImageView *symbol;
@property(nonatomic, assign) CGFloat displayAlpha;
- (void)setTouchPoint:(CGPoint)point offset:(CGPoint)offset active:(BOOL)active;
@end

@implementation NightPadOverlayControlView

- (instancetype)initWithControl:(const TouchControl &)control {
    if ((self = [super initWithFrame:CGRectZero])) {
        _controlId = control.id;
        const ControlStyle style = StyleForControl(control.id);
        _displayAlpha = std::clamp<CGFloat>(control.opacity, 0.2, 1.0);
        self.backgroundColor = style.fill;
        self.layer.cornerRadius = 12;
        const BOOL stick = control.id == TouchControlId::LeftStick || control.id == TouchControlId::RightStick;
        self.layer.borderColor = [UIColor colorWithWhite:1 alpha:(stick ? 0.42 : 0.48)].CGColor;
        // Xbox's D-pad is one dished cross. The parent remains the combined hit
        // area; the cross itself is drawn from two overlapping arms.
        self.layer.borderWidth = control.id == TouchControlId::Dpad ? 0 : 2;
        self.clipsToBounds = YES;
        self.userInteractionEnabled = NO;
        self.isAccessibilityElement = YES;
        self.accessibilityLabel = ControlAccessibilityLabel(control.id);
        self.accessibilityIdentifier = [@"nightpad.touch."
            stringByAppendingString:[NSString stringWithUTF8String:nightpad::TouchControlName(control.id)]];
        self.accessibilityTraits = UIAccessibilityTraitNone;

        if (!stick && control.id != TouchControlId::Dpad) {
            // A restrained top highlight and bottom shade give the face and
            // system keys the molded-plastic depth of a controller.
            _gloss = [CAGradientLayer layer];
            _gloss.colors = @[
                (id)[UIColor colorWithWhite:1 alpha:0.18].CGColor,
                (id)[UIColor colorWithWhite:1 alpha:0.02].CGColor,
                (id)[UIColor colorWithWhite:0 alpha:0.12].CGColor,
            ];
            _gloss.locations = @[ @0.0, @0.48, @1.0 ];
            _gloss.startPoint = CGPointMake(0.5, 0.0);
            _gloss.endPoint = CGPointMake(0.5, 1.0);
            [self.layer insertSublayer:_gloss atIndex:0];
        }

        if (control.id == TouchControlId::LeftStick || control.id == TouchControlId::RightStick) {
            _stickWell = [[UIView alloc] initWithFrame:CGRectZero];
            _stickWell.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.66];
            _stickWell.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.18].CGColor;
            _stickWell.layer.borderWidth = 1;
            _stickWell.userInteractionEnabled = NO;
            [self addSubview:_stickWell];

            _thumb = [[UIView alloc] initWithFrame:CGRectZero];
            _thumb.backgroundColor = [UIColor colorWithWhite:0.66 alpha:0.98];
            _thumb.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.28].CGColor;
            _thumb.layer.borderWidth = 1;
            _thumb.clipsToBounds = YES;
            _thumb.userInteractionEnabled = NO;
            [self addSubview:_thumb];

            _thumbHighlight = [[UIView alloc] initWithFrame:CGRectZero];
            _thumbHighlight.backgroundColor = [UIColor colorWithWhite:1 alpha:0.20];
            _thumbHighlight.userInteractionEnabled = NO;
            [_thumb addSubview:_thumbHighlight];
        }
        if (control.id == TouchControlId::LeftTrigger || control.id == TouchControlId::RightTrigger) {
            _fill = [[UIView alloc] initWithFrame:CGRectZero];
            _fill.backgroundColor = [UIColor colorWithWhite:1 alpha:0.24];
            _fill.userInteractionEnabled = NO;
            [self insertSubview:_fill atIndex:0];
        }
        if (control.id == TouchControlId::Dpad) {
            _dpadDish = [UIView new];
            _dpadDish.backgroundColor = [UIColor colorWithWhite:0.04 alpha:0.96];
            _dpadDish.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.40].CGColor;
            _dpadDish.layer.borderWidth = 1.5;
            _dpadDish.clipsToBounds = YES;
            _dpadDish.userInteractionEnabled = NO;
            [self addSubview:_dpadDish];

            _dpadHorizontal = [UIView new];
            _dpadHorizontal.backgroundColor = [UIColor colorWithWhite:0.56 alpha:1.0];
            _dpadHorizontal.userInteractionEnabled = NO;
            [_dpadDish addSubview:_dpadHorizontal];
            _dpadVertical = [UIView new];
            _dpadVertical.backgroundColor = [UIColor colorWithWhite:0.56 alpha:1.0];
            _dpadVertical.userInteractionEnabled = NO;
            [_dpadDish addSubview:_dpadVertical];
        }

        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.text = ControlLabel(control.id);
        _label.textColor = style.text;
        _label.textAlignment = NSTextAlignmentCenter;
        UIFont *baseFont = [UIFont systemFontOfSize:19.0 weight:UIFontWeightBold];
        if (control.id == TouchControlId::White || control.id == TouchControlId::Black ||
            control.id == TouchControlId::Back)
            baseFont = [UIFont systemFontOfSize:9.5 weight:UIFontWeightBold];
        _label.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleHeadline]
            scaledFontForFont:baseFont maximumPointSize:20];
        _label.adjustsFontForContentSizeCategory = YES;
        _label.adjustsFontSizeToFitWidth = YES;
        _label.minimumScaleFactor = 0.5;
        _label.userInteractionEnabled = NO;
        _label.isAccessibilityElement = NO;
        _label.layer.shadowColor = UIColor.blackColor.CGColor;
        _label.layer.shadowOpacity = 0.72;
        _label.layer.shadowRadius = 2.0;
        _label.layer.shadowOffset = CGSizeMake(0, 1);
        // The D-pad's raised cross already says what it is; a centred caption
        // would sit underneath it.
        _label.hidden = control.id == TouchControlId::Dpad || control.id == TouchControlId::LeftStick ||
                        control.id == TouchControlId::RightStick || control.id == TouchControlId::Start ||
                        control.id == TouchControlId::Back;
        [self addSubview:_label];

        UIImage *symbolImage = ControlSymbol(control.id);
        if (symbolImage != nil) {
            _symbol = [[UIImageView alloc] initWithImage:symbolImage];
            _symbol.tintColor = UIColor.whiteColor;
            _symbol.contentMode = UIViewContentModeScaleAspectFit;
            _symbol.userInteractionEnabled = NO;
            _symbol.layer.shadowColor = UIColor.blackColor.CGColor;
            _symbol.layer.shadowOpacity = 0.7;
            _symbol.layer.shadowRadius = 2.0;
            _symbol.layer.shadowOffset = CGSizeMake(0, 1);
            [self addSubview:_symbol];
        }
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    const CGFloat side = std::min(self.bounds.size.width, self.bounds.size.height);
    _gloss.frame = self.bounds;
    if (_stickWell != nil) {
        const CGFloat diameter = side * 0.80;
        _stickWell.bounds = CGRectMake(0, 0, diameter, diameter);
        _stickWell.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        _stickWell.layer.cornerRadius = diameter * 0.5;
    }
    if (_thumb != nil) {
        const CGFloat diameter = side * 0.44;
        _thumb.bounds = CGRectMake(0, 0, diameter, diameter);
        _thumb.layer.cornerRadius = diameter * 0.5;
        _thumb.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        _thumbHighlight.frame = CGRectMake(diameter * 0.18, diameter * 0.12,
                                           diameter * 0.46, diameter * 0.24);
        _thumbHighlight.layer.cornerRadius = diameter * 0.12;
    }
    if (_fill != nil) {
        _fill.frame = CGRectMake(0, self.bounds.size.height, self.bounds.size.width, 0);
    }
    if (_dpadDish != nil) {
        const CGFloat dishSide = side * 0.92;
        const CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        _dpadDish.bounds = CGRectMake(0, 0, dishSide, dishSide);
        _dpadDish.center = center;
        _dpadDish.layer.cornerRadius = dishSide * 0.5;
        const CGFloat thickness = dishSide * 0.24;
        const CGFloat length = dishSide * 0.70;
        _dpadHorizontal.frame = CGRectMake((dishSide - length) * 0.5, (dishSide - thickness) * 0.5,
                                           length, thickness);
        _dpadVertical.frame = CGRectMake((dishSide - thickness) * 0.5, (dishSide - length) * 0.5,
                                         thickness, length);
        _dpadHorizontal.layer.cornerRadius = thickness * 0.32;
        _dpadVertical.layer.cornerRadius = thickness * 0.32;
    }
    _label.frame = self.bounds;
    if (_symbol != nil) {
        const CGFloat symbolSide = std::min<CGFloat>(24.0, side * 0.52);
        _symbol.bounds = CGRectMake(0, 0, symbolSide, symbolSide);
        _symbol.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    }
}

- (void)setTouchPoint:(CGPoint)point offset:(CGPoint)offset active:(BOOL)active {
    (void)offset;
    switch (_controlId) {
        case TouchControlId::LeftStick:
        case TouchControlId::RightStick: {
            const CGFloat radius = std::min(self.bounds.size.width, self.bounds.size.height) * 0.5;
            const CGFloat thumbRadius = _thumb.bounds.size.width * 0.5;
            const CGFloat travel = std::max<CGFloat>(0, radius - thumbRadius - 4);
            CGFloat dx = 0, dy = 0;
            if (active) {
                dx = (point.x - CGRectGetMidX(self.bounds)) / std::max<CGFloat>(1, radius);
                dy = (point.y - CGRectGetMidY(self.bounds)) / std::max<CGFloat>(1, radius);
                const CGFloat length = std::hypot(dx, dy);
                if (length > 1) {
                    dx /= length;
                    dy /= length;
                }
            }
            _thumb.center = CGPointMake(CGRectGetMidX(self.bounds) + dx * travel,
                                        CGRectGetMidY(self.bounds) + dy * travel);
            self.accessibilityValue = active
                ? [NSString stringWithFormat:@"%.0f%% right, %.0f%% down", dx * 100, dy * 100]
                : @"Centred";
            break;
        }
        case TouchControlId::Dpad: {
            CGFloat dx = 0, dy = 0;
            if (active) {
                dx = (point.x - CGRectGetMidX(self.bounds)) / std::max<CGFloat>(1, self.bounds.size.width * 0.5);
                dy = (point.y - CGRectGetMidY(self.bounds)) / std::max<CGFloat>(1, self.bounds.size.height * 0.5);
            }
            const BOOL up = active && dy < -kDpadDeadZone;
            const BOOL down = active && dy > kDpadDeadZone;
            const BOOL left = active && dx < -kDpadDeadZone;
            const BOOL right = active && dx > kDpadDeadZone;
            UIColor *horizontal = [UIColor colorWithWhite:(left || right) ? 1.0 : 0.56 alpha:1.0];
            UIColor *vertical = [UIColor colorWithWhite:(up || down) ? 1.0 : 0.56 alpha:1.0];
            _dpadHorizontal.backgroundColor = horizontal;
            _dpadVertical.backgroundColor = vertical;
            _dpadDish.transform = active ? CGAffineTransformMakeScale(0.97, 0.97)
                                         : CGAffineTransformIdentity;
            break;
        }
        case TouchControlId::LeftTrigger:
        case TouchControlId::RightTrigger: {
            CGFloat depth = 0;
            if (active)
                depth = std::clamp((point.y - CGRectGetMinY(self.bounds)) / std::max<CGFloat>(1, self.bounds.size.height),
                                   0.0, 1.0);
            _fill.frame = CGRectMake(0, self.bounds.size.height * (1 - depth), self.bounds.size.width,
                                     self.bounds.size.height * depth);
            self.accessibilityValue = [NSString stringWithFormat:@"%.0f percent", depth * 100];
            break;
        }
        default:
            self.backgroundColor = StyleForControl(_controlId).fill;
            _gloss.opacity = active ? 1.0f : 0.86f;
            self.transform = active ? CGAffineTransformMakeScale(0.96, 0.96) : CGAffineTransformIdentity;
            break;
    }
}

@end

@interface NightPadTouchControlsView ()
@end

@implementation NightPadTouchControlsView {
    nightpad::TouchLayout _layout;
    NSMutableArray<NightPadOverlayControlView *> *_controlViews;
    NSMutableSet<UITouch *> *_activeTouches;
    NSMutableDictionary<NSValue *, NSNumber *> *_touchOrder;  // begin order, newest wins
    int _nextTouchOrder;
    UIImpactFeedbackGenerator *_feedback;
    BOOL _hidden;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = UIColor.clearColor;
        self.multipleTouchEnabled = YES;
        _controlViews = [NSMutableArray array];
        _activeTouches = [NSMutableSet set];
        _touchOrder = [NSMutableDictionary dictionary];
        _feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        _layout = nightpad::TouchLayout::Defaults(nightpad::TouchDeviceClass::Phone);
    }
    return self;
}

- (BOOL)controlsHidden {
    return _hidden;
}

- (void)setTouchLayout:(const nightpad::TouchLayout &)layout {
    _layout = layout;
    for (UIView *view in _controlViews)
        [view removeFromSuperview];
    [_controlViews removeAllObjects];
    for (const auto &control : _layout.controls) {
        if (!control.visible)
            continue;
        NightPadOverlayControlView *view = [[NightPadOverlayControlView alloc] initWithControl:control];
        // A layout rebuild must not reveal controls the controller-hide policy
        // has hidden.
        view.alpha = _hidden ? 0.0 : view.displayAlpha;
        [self addSubview:view];
        [_controlViews addObject:view];
    }
    NSArray<NightPadOverlayControlView *> *ordered = [_controlViews sortedArrayUsingComparator:^NSComparisonResult(
        NightPadOverlayControlView *first, NightPadOverlayControlView *second) {
        const int left = nightpad::AccessibilityOrderForControl(first.controlId);
        const int right = nightpad::AccessibilityOrderForControl(second.controlId);
        return left < right ? NSOrderedAscending : (left > right ? NSOrderedDescending : NSOrderedSame);
    }];
    self.accessibilityElements = ordered;
    self.accessibilityElementsHidden = _hidden;
    [self setNeedsLayout];
}

- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated {
    if (_hidden == hidden)
        return;
    _hidden = hidden;
    [self releaseAllTouches];
    self.accessibilityElementsHidden = hidden;
    void (^apply)(void) = ^{
        for (UIView *view in self->_controlViews)
            view.alpha = hidden ? 0.0 : ((NightPadOverlayControlView *)view).displayAlpha;
    };
    if (animated) {
        [UIView animateWithDuration:0.22 animations:apply];
    } else {
        apply();
    }
    self.userInteractionEnabled = !hidden;
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
}

- (CGRect)canvasRect {
    const UIEdgeInsets safe = self.safeAreaInsets;
    CGRect rect = CGRectInset(self.bounds, safe.left + kCanvasMargin, safe.top + kCanvasMargin);
    rect.size.width -= safe.right + kCanvasMargin;
    rect.size.height -= safe.bottom + kCanvasMargin;
    return rect;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    const CGRect canvas = [self canvasRect];
    if (canvas.size.width <= 0 || canvas.size.height <= 0)
        return;
    NSUInteger index = 0;
    for (const auto &control : _layout.controls) {
        if (!control.visible)
            continue;
        if (index >= _controlViews.count)
            break;
        NightPadOverlayControlView *view = _controlViews[index++];
        CGRect frame = CGRectMake(CGRectGetMinX(canvas) + control.x * canvas.size.width,
                                  CGRectGetMinY(canvas) + control.y * canvas.size.height,
                                  control.width * canvas.size.width, control.height * canvas.size.height);
        if (IsRoundControl(control.id)) {
            // A normalized rectangle is not square on every canvas aspect; keep
            // the round controls round by using the smaller side about the same
            // centre (SunPad places round controls by point size).
            const CGFloat side = std::min(frame.size.width, frame.size.height);
            frame = CGRectMake(CGRectGetMidX(frame) - side * 0.5,
                               CGRectGetMidY(frame) - side * 0.5, side, side);
        }
        view.frame = frame;
        view.layer.cornerRadius = ControlCornerRadius(control.id, view.bounds.size);
    }
    [self refreshVisuals];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (_hidden || !self.userInteractionEnabled)
        return nil;
    UIView *hit = [super hitTest:point withEvent:event];
    if (hit != self)
        return hit;
    // Empty space belongs to the game and to the shell's persistent menu.
    for (NightPadOverlayControlView *view in _controlViews)
        if (!view.hidden && CGRectContainsPoint(view.frame, point))
            return self;
    return nil;
}

- (const TouchControl *)controlAtPoint:(CGPoint)point index:(NSUInteger *)index {
    const CGRect canvas = [self canvasRect];
    if (canvas.size.width <= 0 || canvas.size.height <= 0)
        return nullptr;
    const float nx = (point.x - CGRectGetMinX(canvas)) / canvas.size.width;
    const float ny = (point.y - CGRectGetMinY(canvas)) / canvas.size.height;
    NSUInteger visibleIndex = 0;
    for (const auto &control : _layout.controls) {
        if (!control.visible)
            continue;
        if (nx >= control.x && nx <= control.x + control.width && ny >= control.y && ny <= control.y + control.height) {
            if (index != nullptr)
                *index = visibleIndex;
            return &control;
        }
        ++visibleIndex;
    }
    return nullptr;
}

- (nightpad::PadState)currentPad {
    std::vector<nightpad::TouchPoint> points;
    points.reserve(_activeTouches.count);
    const CGRect canvas = [self canvasRect];
    if (canvas.size.width <= 0 || canvas.size.height <= 0)
        return nightpad::TouchPadState(_layout, nullptr, 0);
    for (UITouch *touch in _activeTouches) {
        const CGPoint p = [touch locationInView:self];
        NSNumber *order = _touchOrder[[NSValue valueWithNonretainedObject:touch]];
        points.push_back({order != nil ? order.intValue : 0,
                          static_cast<float>((p.x - CGRectGetMinX(canvas)) / canvas.size.width),
                          static_cast<float>((p.y - CGRectGetMinY(canvas)) / canvas.size.height)});
    }
    return nightpad::TouchPadState(_layout, points.data(), points.size());
}

- (void)refreshVisuals {
    NSMutableDictionary<NSNumber *, NSValue *> *latest = [NSMutableDictionary dictionary];

    for (UITouch *touch in _activeTouches) {
        const CGPoint point = [touch locationInView:self];
        NSUInteger index = 0;
        if ([self controlAtPoint:point index:&index] == nullptr)
            continue;
        NSNumber *key = @(index);
        latest[key] = [NSValue valueWithCGPoint:point];
    }

    for (NSUInteger i = 0; i < _controlViews.count; ++i) {
        NightPadOverlayControlView *view = _controlViews[i];
        NSNumber *key = @(i);
        NSValue *value = latest[key];
        const CGPoint point = value != nil ? value.CGPointValue
                                           : CGPointMake(CGRectGetMidX(view.bounds), CGRectGetMidY(view.bounds));
        [view setTouchPoint:point offset:CGPointZero active:value != nil];
    }
}

- (void)noteTouches:(NSSet<UITouch *> *)touches active:(BOOL)active {
    if (active) {
        for (UITouch *touch in touches) {
            NSValue *key = [NSValue valueWithNonretainedObject:touch];
            if (_touchOrder[key] == nil)
                _touchOrder[key] = @(++_nextTouchOrder);
        }
        [_activeTouches unionSet:touches];
    } else {
        for (UITouch *touch in touches)
            [_touchOrder removeObjectForKey:[NSValue valueWithNonretainedObject:touch]];
        [_activeTouches minusSet:touches];
    }
    [_feedback prepare];
    [self refreshVisuals];
    if (self.touchStateChanged)
        self.touchStateChanged();
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    (void)event;
    [_feedback impactOccurred];
    [self noteTouches:touches active:YES];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    (void)event;
    [self noteTouches:touches active:YES];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    (void)event;
    [self noteTouches:touches active:NO];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    (void)event;
    [self noteTouches:touches active:NO];
}

- (void)releaseAllTouches {
    if (_activeTouches.count == 0)
        return;
    [_activeTouches removeAllObjects];
    [_touchOrder removeAllObjects];
    [self refreshVisuals];
    if (self.touchStateChanged)
        self.touchStateChanged();
}

@end
