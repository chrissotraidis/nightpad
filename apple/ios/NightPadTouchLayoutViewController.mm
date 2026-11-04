#import "NightPadTouchLayoutViewController.h"

#import "NightPadTouchControlsView.h"

#include <algorithm>
#include <cmath>

using nightpad::TouchControlId;
using nightpad::TouchGroup;

namespace {

constexpr CGFloat kCanvasMargin = 8.0;   // the live overlay's canvas inset
constexpr float kMinScale = 0.6f, kMaxScale = 2.0f;

NSString *ItemName(TouchControlId id) {
    switch (nightpad::TouchGroupFor(id)) {
        case TouchGroup::Face: return @"A B X Y Buttons";
        case TouchGroup::Shoulders: return @"White & Black Buttons";
        case TouchGroup::System: return @"Start & Back";
        case TouchGroup::None: break;
    }
    switch (id) {
        case TouchControlId::LeftStick: return @"Left Stick";
        case TouchControlId::RightStick: return @"Right Stick";
        case TouchControlId::Dpad: return @"D-Pad";
        case TouchControlId::LeftTrigger: return @"Left Trigger";
        case TouchControlId::RightTrigger: return @"Right Trigger";
        default: return @"Control";
    }
}

}  // namespace

@interface NightPadTouchLayoutViewController () <UIGestureRecognizerDelegate>
@end

@implementation NightPadTouchLayoutViewController {
    nightpad::TouchLayout _layout;
    NSURL *_savePath;
    UIView *_canvas;
    NSMutableArray<NightPadOverlayControlView *> *_controlViews;
    CAShapeLayer *_selection;
    BOOL _hasSelection;
    TouchControlId _selected;
    int _opacity;

    UILabel *_itemTitle;
    UIButton *_visibility;
    UISlider *_sizeSlider;
    UILabel *_sizeValue;
    UISlider *_opacitySlider;
    UILabel *_opacityValue;
    UIView *_inspector;
    UIView *_bar;
}

- (instancetype)initWithLayout:(nightpad::TouchLayout)layout
                      savePath:(NSURL *)savePath
                opacityPercent:(int)opacityPercent {
    if ((self = [super initWithNibName:nil bundle:nil])) {
        _layout = std::move(layout);
        _savePath = [savePath copy];
        _controlViews = [NSMutableArray array];
        _opacity = std::clamp(opacityPercent, 20, 100);
        _selected = TouchControlId::A;
    }
    return self;
}

- (int)opacityPercent {
    return _opacity;
}

- (BOOL)prefersStatusBarHidden { return YES; }
- (BOOL)prefersHomeIndicatorAutoHidden { return YES; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;

    // The same canvas as the live overlay, so saved rectangles match play.
    _canvas = [UIView new];
    _canvas.backgroundColor = [UIColor colorWithWhite:0.055 alpha:1];
    _canvas.layer.cornerRadius = 12;
    _canvas.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_canvas];
    _selection = [CAShapeLayer layer];
    _selection.fillColor = [UIColor colorWithRed:0.25 green:0.55 blue:1 alpha:0.12].CGColor;
    _selection.strokeColor = [UIColor colorWithRed:0.35 green:0.65 blue:1 alpha:1].CGColor;
    _selection.lineWidth = 2;
    _selection.lineDashPattern = @[ @6, @4 ];

    [_canvas addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)]];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    pan.maximumNumberOfTouches = 1;
    pan.delegate = self;   // a drag starts only on a control
    [_canvas addGestureRecognizer:pan];
    [_canvas addGestureRecognizer:[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)]];

    UIButton *cancel = [self barButton:@"Cancel" filled:NO action:@selector(cancel)];
    cancel.accessibilityIdentifier = @"nightpad.touch.cancel";
    UIButton *reset = [self barButton:@"Reset" filled:NO action:@selector(reset)];
    reset.accessibilityIdentifier = @"nightpad.touch.reset";
    UIButton *save = [self barButton:@"Save" filled:YES action:@selector(done)];
    save.accessibilityIdentifier = @"nightpad.touch.save";
    UILabel *title = [UILabel new];
    title.text = @"Touch Layout";
    title.textColor = UIColor.whiteColor;
    title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    title.textAlignment = NSTextAlignmentCenter;
    UIView *leftSpace = [UIView new], *rightSpace = [UIView new];
    UIStackView *bar = [[UIStackView alloc] initWithArrangedSubviews:@[cancel, leftSpace, title, rightSpace, reset, save]];
    bar.spacing = 12;
    bar.alignment = UIStackViewAlignmentCenter;
    bar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:bar];
    _bar = bar;

    UIView *inspector = [self buildInspector];
    [self.view addSubview:inspector];
    _inspector = inspector;

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [_canvas.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:kCanvasMargin],
        [_canvas.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-kCanvasMargin],
        [_canvas.topAnchor constraintEqualToAnchor:safe.topAnchor constant:kCanvasMargin],
        [_canvas.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-kCanvasMargin],
        [bar.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:20],
        [bar.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-20],
        [bar.topAnchor constraintEqualToAnchor:safe.topAnchor constant:14],
        [bar.heightAnchor constraintEqualToConstant:44],
        [leftSpace.widthAnchor constraintEqualToAnchor:rightSpace.widthAnchor],
        [inspector.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor],
        [inspector.topAnchor constraintEqualToAnchor:bar.bottomAnchor constant:8],
        [inspector.widthAnchor constraintEqualToConstant:420],
    ]];
    [self rebuildControls];
    [self select:NO id:_selected];
}

- (UIButton *)barButton:(NSString *)title filled:(BOOL)filled action:(SEL)action {
    UIButtonConfiguration *configuration = filled ? [UIButtonConfiguration filledButtonConfiguration]
                                                  : [UIButtonConfiguration grayButtonConfiguration];
    configuration.title = title;
    configuration.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    UIButton *button = [UIButton buttonWithConfiguration:configuration primaryAction:nil];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [button.heightAnchor constraintEqualToConstant:40].active = YES;
    [button.widthAnchor constraintGreaterThanOrEqualToConstant:76].active = YES;
    return button;
}

- (UIStackView *)sliderRow:(NSString *)name slider:(UISlider *)slider value:(UILabel *)value {
    UILabel *label = [UILabel new];
    label.text = name;
    label.textColor = [UIColor colorWithWhite:1 alpha:0.86];
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    [label.widthAnchor constraintEqualToConstant:70].active = YES;
    value.textColor = [UIColor colorWithWhite:1 alpha:0.86];
    value.font = [UIFont monospacedDigitSystemFontOfSize:15 weight:UIFontWeightMedium];
    value.textAlignment = NSTextAlignmentRight;
    [value.widthAnchor constraintEqualToConstant:52].active = YES;
    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[label, slider, value]];
    row.spacing = 10;
    row.alignment = UIStackViewAlignmentCenter;
    return row;
}

- (UIView *)buildInspector {
    UIView *card = [UIView new];
    card.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.94];
    card.layer.cornerRadius = 16;
    card.layer.borderWidth = 1;
    card.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.14].CGColor;
    card.translatesAutoresizingMaskIntoConstraints = NO;

    _itemTitle = [UILabel new];
    _itemTitle.textColor = UIColor.whiteColor;
    _itemTitle.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    UIButtonConfiguration *visibility = [UIButtonConfiguration grayButtonConfiguration];
    visibility.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    visibility.buttonSize = UIButtonConfigurationSizeSmall;
    visibility.title = @"Hide";
    _visibility = [UIButton buttonWithConfiguration:visibility primaryAction:nil];
    _visibility.accessibilityIdentifier = @"nightpad.touch.visibility";
    [_visibility addTarget:self action:@selector(toggleVisibility) forControlEvents:UIControlEventTouchUpInside];
    UIStackView *header = [[UIStackView alloc] initWithArrangedSubviews:@[_itemTitle, [UIView new], _visibility]];
    header.alignment = UIStackViewAlignmentCenter;

    _sizeSlider = [UISlider new];
    _sizeSlider.minimumValue = kMinScale;
    _sizeSlider.maximumValue = kMaxScale;
    _sizeSlider.accessibilityIdentifier = @"nightpad.touch.size";
    [_sizeSlider addTarget:self action:@selector(sizeChanged) forControlEvents:UIControlEventValueChanged];
    _sizeValue = [UILabel new];
    _opacitySlider = [UISlider new];
    _opacitySlider.minimumValue = 20;
    _opacitySlider.maximumValue = 100;
    _opacitySlider.value = _opacity;
    _opacitySlider.accessibilityIdentifier = @"nightpad.touch.opacity";
    [_opacitySlider addTarget:self action:@selector(opacityChanged) forControlEvents:UIControlEventValueChanged];
    _opacityValue = [UILabel new];

    UILabel *hint = [UILabel new];
    hint.text = @"Tap a control to select it · drag to move · pinch or use Size to resize. Opacity applies to all controls.";
    hint.textColor = [UIColor colorWithWhite:1 alpha:0.55];
    hint.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    hint.numberOfLines = 0;

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[
        header,
        [self sliderRow:@"Size" slider:_sizeSlider value:_sizeValue],
        [self sliderRow:@"Opacity" slider:_opacitySlider value:_opacityValue],
        hint,
    ]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 8;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor constant:12],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-12],
    ]];
    [self updateOpacityLabel];
    return card;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateControlFrames];
}

// ---- controls

- (void)rebuildControls {
    for (UIView *view in _controlViews)
        [view removeFromSuperview];
    [_controlViews removeAllObjects];
    for (const auto &control : _layout.controls) {
        NightPadOverlayControlView *view = [[NightPadOverlayControlView alloc] initWithControl:control];
        view.userInteractionEnabled = NO;
        [_canvas addSubview:view];
        [_controlViews addObject:view];
    }
    [_canvas.layer addSublayer:_selection];   // keep the outline above the controls
    [self updateControlFrames];
}

- (void)updateControlFrames {
    const CGSize size = _canvas.bounds.size;
    if (size.width <= 0 || size.height <= 0)
        return;
    const auto resolved = _layout.ForCanvas(size.width, size.height);
    CGRect item = CGRectNull;
    for (NightPadOverlayControlView *view in _controlViews) {
        for (const auto &control : resolved.controls) {
            if (control.id != view.controlId)
                continue;
            view.frame = CGRectMake(control.x * size.width, control.y * size.height,
                                    control.width * size.width, control.height * size.height);
            view.alpha = control.visible ? _opacity / 100.0 : 0.18;
            if (_hasSelection && nightpad::SameTouchItem(_selected, control.id))
                item = CGRectUnion(item, view.frame);
        }
    }
    _selection.path = CGRectIsNull(item)
        ? nil
        : [UIBezierPath bezierPathWithRoundedRect:CGRectInset(item, -8, -8) cornerRadius:14].CGPath;
}

- (BOOL)controlAt:(CGPoint)point id:(TouchControlId *)id {
    // Topmost first, with a little slack so small buttons are easy to grab.
    for (NightPadOverlayControlView *view in _controlViews.reverseObjectEnumerator) {
        if (CGRectContainsPoint(CGRectInset(view.frame, -10, -10), point)) {
            *id = view.controlId;
            return YES;
        }
    }
    // A group is one item: the empty middle of the diamond grabs it too.
    for (NightPadOverlayControlView *view in _controlViews) {
        if (nightpad::TouchGroupFor(view.controlId) == TouchGroup::None)
            continue;
        CGRect item = CGRectNull;
        for (NightPadOverlayControlView *other in _controlViews)
            if (nightpad::SameTouchItem(view.controlId, other.controlId))
                item = CGRectUnion(item, other.frame);
        if (CGRectContainsPoint(item, point)) {
            *id = view.controlId;
            return YES;
        }
    }
    return NO;
}

- (void)select:(BOOL)selected id:(TouchControlId)id {
    _hasSelection = selected;
    _selected = id;
    _sizeSlider.enabled = selected;
    _visibility.enabled = selected;
    UIButtonConfiguration *configuration = _visibility.configuration;
    if (selected) {
        _itemTitle.text = ItemName(id);
        _sizeSlider.value = std::clamp(_layout.ItemScale(id), kMinScale, kMaxScale);
        configuration.title = _layout.ItemVisible(id) ? @"Hide" : @"Show";
    } else {
        _itemTitle.text = @"Select a control";
        configuration.title = @"Hide";
    }
    _visibility.configuration = configuration;
    [self updateSizeLabel];
    [self updateControlFrames];
}

// ---- gestures

- (void)tap:(UITapGestureRecognizer *)gesture {
    TouchControlId id;
    if ([self controlAt:[gesture locationInView:_canvas] id:&id])
        [self select:YES id:id];
    else
        [self select:NO id:_selected];
}

- (void)pan:(UIPanGestureRecognizer *)gesture {
    const CGSize size = _canvas.bounds.size;
    if (gesture.state == UIGestureRecognizerStateBegan) {
        TouchControlId id;
        if ([self controlAt:[gesture locationInView:_canvas] id:&id])
            [self select:YES id:id];
    }
    // The panel and bar fade while dragging so a control can pass under them.
    const BOOL dragging = gesture.state == UIGestureRecognizerStateBegan ||
                          gesture.state == UIGestureRecognizerStateChanged;
    _inspector.alpha = dragging ? 0.25 : 1.0;
    _bar.alpha = dragging ? 0.25 : 1.0;
    if (!_hasSelection || size.width <= 0 || size.height <= 0)
        return;
    const CGPoint delta = [gesture translationInView:_canvas];
    [gesture setTranslation:CGPointZero inView:_canvas];
    _layout.MoveItem(_selected, delta.x / size.width, delta.y / size.height);
    [self updateControlFrames];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gesture {
    TouchControlId id;
    return [self controlAt:[gesture locationInView:_canvas] id:&id];
}

- (void)pinch:(UIPinchGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        TouchControlId id;
        if ([self controlAt:[gesture locationInView:_canvas] id:&id])
            [self select:YES id:id];
    }
    if (!_hasSelection)
        return;
    [self scaleSelectedTo:_layout.ItemScale(_selected) * gesture.scale];
    gesture.scale = 1.0;
}

- (void)scaleSelectedTo:(float)target {
    const CGSize size = _canvas.bounds.size;
    const float current = _layout.ItemScale(_selected);
    if (current <= 0 || size.width <= 0 || size.height <= 0)
        return;
    target = std::clamp(target, kMinScale, kMaxScale);
    _layout.ScaleItem(_selected, target / current, size.width, size.height);
    _sizeSlider.value = std::clamp(_layout.ItemScale(_selected), kMinScale, kMaxScale);
    [self updateSizeLabel];
    [self updateControlFrames];
}

// ---- inspector

- (void)sizeChanged {
    if (_hasSelection)
        [self scaleSelectedTo:_sizeSlider.value];
}

- (void)updateSizeLabel {
    _sizeValue.text = _hasSelection
        ? [NSString stringWithFormat:@"%d%%", (int)lroundf(_layout.ItemScale(_selected) * 100.0f)]
        : @"–";
}

- (void)opacityChanged {
    _opacity = (int)lroundf(_opacitySlider.value);
    [self updateOpacityLabel];
    [self updateControlFrames];
}

- (void)updateOpacityLabel {
    _opacityValue.text = [NSString stringWithFormat:@"%d%%", _opacity];
}

- (void)toggleVisibility {
    if (!_hasSelection)
        return;
    _layout.SetItemVisible(_selected, !_layout.ItemVisible(_selected));
    [self select:YES id:_selected];
}

// ---- actions

- (void)reset {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Reset touch layout?"
        message:@"This restores the default arrangement for this device. Nothing changes until you tap Save."
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDestructive
        handler:^(UIAlertAction *action) {
            (void)action;
            self->_layout.Reset();
            self->_opacity = 70;
            self->_opacitySlider.value = 70;
            [self updateOpacityLabel];
            [self rebuildControls];
            [self select:self->_hasSelection id:self->_selected];
        }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)done {
    std::string error;
    if (!_layout.Save(_savePath.fileSystemRepresentation, &error)) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Layout Not Saved"
            message:[NSString stringWithUTF8String:error.c_str()] preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    _saved = YES;
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.onClose) self.onClose();
    }];
}

- (void)cancel {
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.onClose) self.onClose();
    }];
}

@end
