#import "NightPadTouchLayoutViewController.h"

#include "../shared/NightPadControlPalette.h"

@interface NightPadLayoutControlView : UIView
@property(nonatomic, assign) nightpad::TouchControlId controlId;
@end

@implementation NightPadLayoutControlView
@end

@interface NightPadTouchLayoutViewController () <UIContextMenuInteractionDelegate>
@end

@implementation NightPadTouchLayoutViewController {
    nightpad::TouchLayout _layout;
    NSURL *_savePath;
    UIView *_canvas;
    NSMutableArray<NightPadLayoutControlView *> *_controlViews;
}

- (instancetype)initWithLayout:(nightpad::TouchLayout)layout savePath:(NSURL *)savePath {
    if ((self = [super initWithNibName:nil bundle:nil])) {
        _layout = std::move(layout);
        _savePath = [savePath copy];
        _controlViews = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Touch Layout";
    self.view.backgroundColor = UIColor.blackColor;
    // Use the gameplay canvas itself, with editing chrome over its empty top
    // centre. A shorter preview used to clamp/rescale the saved layout merely
    // by opening the editor and made its rectangles differ from live controls.
    _canvas = [UIView new];
    _canvas.backgroundColor = [UIColor colorWithWhite:0.055 alpha:1];
    _canvas.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_canvas];

    UIButton *cancel = [UIButton buttonWithType:UIButtonTypeSystem];
    [cancel setTitle:@"Cancel" forState:UIControlStateNormal];
    cancel.accessibilityIdentifier = @"nightpad.touch.cancel";
    [cancel addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    UIButton *save = [UIButton buttonWithType:UIButtonTypeSystem];
    save.configuration = [UIButtonConfiguration filledButtonConfiguration];
    [save setTitle:@"Save" forState:UIControlStateNormal];
    save.accessibilityIdentifier = @"nightpad.touch.save";
    [save addTarget:self action:@selector(done) forControlEvents:UIControlEventTouchUpInside];
    UIButton *reset = [UIButton buttonWithType:UIButtonTypeSystem];
    [reset setTitle:@"Reset" forState:UIControlStateNormal];
    reset.accessibilityIdentifier = @"nightpad.touch.reset";
    [reset addTarget:self action:@selector(reset) forControlEvents:UIControlEventTouchUpInside];
    UILabel *title = [UILabel new];
    title.text = @"Touch Layout";
    title.textColor = UIColor.whiteColor;
    title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    title.adjustsFontForContentSizeCategory = YES;
    title.textAlignment = NSTextAlignmentCenter;
    UIView *leftSpace = [UIView new], *rightSpace = [UIView new];
    UIStackView *bar = [[UIStackView alloc] initWithArrangedSubviews:
        @[cancel, leftSpace, title, rightSpace, reset, save]];
    bar.axis = UILayoutConstraintAxisHorizontal;
    bar.spacing = 12;
    bar.alignment = UIStackViewAlignmentCenter;
    bar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:bar];
    UILabel *hint = [UILabel new];
    hint.text = @"Drag to move · pinch to resize\nHold a control for visibility and opacity";
    hint.textAlignment = NSTextAlignmentCenter;
    hint.textColor = [UIColor colorWithWhite:1 alpha:0.72];
    hint.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleFootnote]
        scaledFontForFont:[UIFont systemFontOfSize:12] maximumPointSize:17];
    hint.adjustsFontForContentSizeCategory = YES;
    hint.numberOfLines = 2;
    hint.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:hint];
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [_canvas.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:8],
        [_canvas.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-8],
        [_canvas.topAnchor constraintEqualToAnchor:safe.topAnchor constant:8],
        [_canvas.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-8],
        [bar.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:8],
        [bar.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-8],
        [bar.topAnchor constraintEqualToAnchor:safe.topAnchor constant:4],
        [bar.heightAnchor constraintEqualToConstant:44],
        [leftSpace.widthAnchor constraintEqualToAnchor:rightSpace.widthAnchor],
        [cancel.widthAnchor constraintGreaterThanOrEqualToConstant:64],
        [cancel.heightAnchor constraintEqualToConstant:44],
        [reset.widthAnchor constraintGreaterThanOrEqualToConstant:56],
        [reset.heightAnchor constraintEqualToConstant:44],
        [save.widthAnchor constraintGreaterThanOrEqualToConstant:64],
        [save.heightAnchor constraintEqualToConstant:44],
        [hint.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor],
        [hint.widthAnchor constraintLessThanOrEqualToAnchor:safe.widthAnchor multiplier:0.5],
        [hint.topAnchor constraintEqualToAnchor:bar.bottomAnchor constant:4],
    ]];
    [self rebuildControls];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateControlFrames];
}

- (nightpad::TouchControl *)controlForId:(nightpad::TouchControlId)id {
    for (auto &control : _layout.controls)
        if (control.id == id)
            return &control;
    return nullptr;
}

- (CGRect)frameForControl:(nightpad::TouchControl *)control {
    if (control == nullptr || _canvas.bounds.size.width <= 0 || _canvas.bounds.size.height <= 0)
        return CGRectZero;
    const auto resolved = _layout.ForCanvas(_canvas.bounds.size.width, _canvas.bounds.size.height);
    for (const auto &item : resolved.controls) {
        if (item.id == control->id)
            return CGRectMake(item.x * _canvas.bounds.size.width, item.y * _canvas.bounds.size.height,
                              item.width * _canvas.bounds.size.width, item.height * _canvas.bounds.size.height);
    }
    return CGRectZero;
}

- (void)updateControlFrames {
    for (NightPadLayoutControlView *view in _controlViews) {
        view.frame = [self frameForControl:[self controlForId:view.controlId]];
        using nightpad::TouchControlId;
        const auto id = view.controlId;
        const BOOL round = id == TouchControlId::LeftStick || id == TouchControlId::RightStick ||
            id == TouchControlId::A || id == TouchControlId::B || id == TouchControlId::X ||
            id == TouchControlId::Y || id == TouchControlId::White || id == TouchControlId::Black;
        view.layer.cornerRadius = round ? MIN(view.bounds.size.width, view.bounds.size.height) * 0.5 : 12;
    }
}

- (UIColor *)colourFor:(nightpad::TouchControlId)id {
    const nightpad::ControlColour colour = nightpad::ColourForControl(id);
    return [UIColor colorWithRed:colour.red green:colour.green blue:colour.blue alpha:1];
}

- (NSString *)labelFor:(nightpad::TouchControlId)id {
    using nightpad::TouchControlId;
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
        case TouchControlId::White: return @"WHITE";
        case TouchControlId::Black: return @"BLACK";
        case TouchControlId::Start: return @"START";
        case TouchControlId::Back: return @"BACK";
    }
    return @"";
}

- (void)rebuildControls {
    for (UIView *view in _controlViews)
        [view removeFromSuperview];
    [_controlViews removeAllObjects];
    for (const auto &control : _layout.controls) {
        NightPadLayoutControlView *view = [NightPadLayoutControlView new];
        view.controlId = control.id;
        view.backgroundColor = [[self colourFor:control.id] colorWithAlphaComponent:control.opacity];
        view.layer.cornerRadius = 14;
        view.layer.borderWidth = 1;
        view.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.35].CGColor;
        view.clipsToBounds = YES;
        view.accessibilityLabel = [self labelFor:control.id];
        view.accessibilityIdentifier = [@"nightpad.touch." stringByAppendingString:[NSString stringWithUTF8String:nightpad::TouchControlName(control.id)]];
        view.isAccessibilityElement = YES;
        UILabel *label = [UILabel new];
        label.text = [self labelFor:control.id];
        label.textColor = nightpad::UsesDarkLabel(control.id)
            ? [UIColor colorWithWhite:0.06 alpha:1.0] : UIColor.whiteColor;
        label.textAlignment = NSTextAlignmentCenter;
        UIFont *baseFont = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightBold];
        label.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleHeadline]
            scaledFontForFont:baseFont maximumPointSize:22];
        label.adjustsFontForContentSizeCategory = YES;
        label.adjustsFontSizeToFitWidth = YES;
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [view addSubview:label];
        [NSLayoutConstraint activateConstraints:@[
            [label.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:2],
            [label.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-2],
            [label.centerYAnchor constraintEqualToAnchor:view.centerYAnchor],
        ]];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        [view addGestureRecognizer:pan];
        UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
        [view addGestureRecognizer:pinch];
        [view addInteraction:[[UIContextMenuInteraction alloc] initWithDelegate:self]];
        [_canvas addSubview:view];
        [_controlViews addObject:view];
        [self applyVisibilityAppearance:view];
    }
    NSArray<NightPadLayoutControlView *> *ordered = [_controlViews sortedArrayUsingComparator:^NSComparisonResult(
        NightPadLayoutControlView *first, NightPadLayoutControlView *second) {
        const int left = nightpad::AccessibilityOrderForControl(first.controlId);
        const int right = nightpad::AccessibilityOrderForControl(second.controlId);
        return left < right ? NSOrderedAscending : (left > right ? NSOrderedDescending : NSOrderedSame);
    }];
    _canvas.accessibilityElements = ordered;
    [self.view setNeedsLayout];
}

- (void)applyVisibilityAppearance:(NightPadLayoutControlView *)view {
    auto *control = [self controlForId:view.controlId];
    if (control == nullptr)
        return;
    view.backgroundColor = [[self colourFor:view.controlId] colorWithAlphaComponent:control->opacity];
    const BOOL hidden = !control->visible;
    view.alpha = hidden ? 0.35 : 1.0;
    view.layer.borderWidth = hidden ? 2.0 : 1.0;
    view.layer.borderColor = [UIColor colorWithWhite:1 alpha:(hidden ? 0.85 : 0.35)].CGColor;
    view.accessibilityValue = hidden ? @"Hidden" : nil;
}

- (UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction
                        configurationForMenuAtLocation:(CGPoint)location {
    (void)location;
    NightPadLayoutControlView *view = (NightPadLayoutControlView *)interaction.view;
    auto *control = [self controlForId:view.controlId];
    if (control == nullptr)
        return nil;
    const BOOL hidden = !control->visible;
    __weak NightPadTouchLayoutViewController *weakSelf = self;
    UIAction *toggle = [UIAction actionWithTitle:(hidden ? @"Show Control" : @"Hide Control")
                                           image:[UIImage systemImageNamed:(hidden ? @"eye" : @"eye.slash")]
                                      identifier:nil
                                         handler:^(__kindof UIAction *selected) {
        (void)selected;
        NightPadTouchLayoutViewController *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        auto *target = [strongSelf controlForId:view.controlId];
        if (target == nullptr)
            return;
        target->visible = !target->visible;
        [strongSelf applyVisibilityAppearance:view];
    }];
    // Opacity is part of the layout model and the file format but had no
    // control; a fainter stick keeps the view behind it readable.
    NSMutableArray<UIAction *> *opacities = [NSMutableArray array];
    for (float value : { 0.3f, 0.5f, 0.7f, 1.0f }) {
        NSString *title = [NSString stringWithFormat:@"%d%%", (int)lroundf(value * 100.0f)];
        UIAction *action = [UIAction actionWithTitle:title
                                              image:nil
                                         identifier:nil
                                            handler:^(__kindof UIAction *selected) {
            (void)selected;
            NightPadTouchLayoutViewController *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            auto *target = [strongSelf controlForId:view.controlId];
            if (target == nullptr)
                return;
            target->opacity = value;
            [strongSelf applyVisibilityAppearance:view];
        }];
        if (fabsf(control->opacity - value) < 0.01f)
            action.state = UIMenuElementStateOn;
        [opacities addObject:action];
    }
    UIMenu *opacity = [UIMenu menuWithTitle:@"Opacity" children:opacities];
    return [UIContextMenuConfiguration configurationWithIdentifier:nil
                                                   previewProvider:nil
                                                    actionProvider:^UIMenu *(NSArray<UIMenuElement *> *suggested) {
        (void)suggested;
        return [UIMenu menuWithTitle:@"" children:@[ toggle, opacity ]];
    }];
}

- (void)pan:(UIPanGestureRecognizer *)gesture {
    NightPadLayoutControlView *view = (NightPadLayoutControlView *)gesture.view;
    auto *control = [self controlForId:view.controlId];
    if (control == nullptr || _canvas.bounds.size.width <= 0 || _canvas.bounds.size.height <= 0)
        return;
    const CGPoint translation = [gesture translationInView:_canvas];
    control->x += translation.x / _canvas.bounds.size.width;
    control->y += translation.y / _canvas.bounds.size.height;
    [gesture setTranslation:CGPointZero inView:_canvas];
    [self clampAndReload];
}

- (void)pinch:(UIPinchGestureRecognizer *)gesture {
    NightPadLayoutControlView *view = (NightPadLayoutControlView *)gesture.view;
    auto *control = [self controlForId:view.controlId];
    if (control == nullptr)
        return;
    control->width *= gesture.scale;
    control->height *= gesture.scale;
    gesture.scale = 1.0;
    [self clampAndReload];
}

- (void)clampAndReload {
    _layout.Clamp(_canvas.bounds.size.width, _canvas.bounds.size.height, 44.0f);
    [self updateControlFrames];
}

- (void)reset {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Reset touch layout?"
        message:@"This restores the authored default for this device. Your saved layout is replaced when you tap Save."
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDestructive
        handler:^(UIAlertAction *action) {
            (void)action;
            self->_layout.Reset();
            [self rebuildControls];
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
