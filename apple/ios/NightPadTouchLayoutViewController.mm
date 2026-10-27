#import "NightPadTouchLayoutViewController.h"

@interface NightPadLayoutControlView : UIView
@property(nonatomic, assign) nightpad::TouchControlId controlId;
@end

@implementation NightPadLayoutControlView
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
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
        initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(done)];
    self.navigationItem.rightBarButtonItem.accessibilityIdentifier = @"nightpad.touch.save";

    UILabel *hint = [UILabel new];
    hint.text = @"Drag to move, pinch to resize. Controls stay inside the safe area and at least 44 points.";
    hint.textColor = [UIColor colorWithWhite:1 alpha:0.72];
    hint.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    hint.adjustsFontForContentSizeCategory = YES;
    hint.numberOfLines = 0;
    hint.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:hint];
    _canvas = [UIView new];
    _canvas.backgroundColor = [UIColor colorWithWhite:0.08 alpha:1];
    _canvas.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_canvas];
    UIButton *reset = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButtonConfiguration *resetConfiguration = [UIButtonConfiguration tintedButtonConfiguration];
    resetConfiguration.title = @"Reset Layout";
    resetConfiguration.image = [UIImage systemImageNamed:@"arrow.counterclockwise"];
    resetConfiguration.imagePadding = 8;
    reset.configuration = resetConfiguration;
    reset.accessibilityIdentifier = @"nightpad.touch.reset";
    reset.translatesAutoresizingMaskIntoConstraints = NO;
    [reset addTarget:self action:@selector(reset) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:reset];
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [hint.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
        [hint.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        [hint.topAnchor constraintEqualToAnchor:safe.topAnchor constant:8],
        [_canvas.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:8],
        [_canvas.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-8],
        [_canvas.topAnchor constraintEqualToAnchor:hint.bottomAnchor constant:8],
        [_canvas.bottomAnchor constraintEqualToAnchor:reset.topAnchor constant:-8],
        [reset.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [reset.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-4],
    ]];
    [self rebuildControls];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _layout.Clamp(_canvas.bounds.size.width, _canvas.bounds.size.height, 44.0f);
    for (NightPadLayoutControlView *view in _controlViews) {
        view.frame = [self frameForControl:[self controlForId:view.controlId]];
    }
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
    return CGRectMake(control->x * _canvas.bounds.size.width, control->y * _canvas.bounds.size.height,
                      control->width * _canvas.bounds.size.width, control->height * _canvas.bounds.size.height);
}

- (UIColor *)colourFor:(nightpad::TouchControlId)id {
    using nightpad::TouchControlId;
    switch (id) {
        case TouchControlId::A: return [UIColor colorWithRed:0.25 green:0.7 blue:0.35 alpha:1];
        case TouchControlId::B: return [UIColor colorWithRed:0.85 green:0.25 blue:0.25 alpha:1];
        case TouchControlId::X: return [UIColor colorWithRed:0.25 green:0.45 blue:0.9 alpha:1];
        case TouchControlId::Y: return [UIColor colorWithRed:0.9 green:0.75 blue:0.2 alpha:1];
        case TouchControlId::LeftStick:
        case TouchControlId::RightStick: return [UIColor colorWithWhite:0.35 alpha:1];
        case TouchControlId::Dpad: return [UIColor colorWithWhite:0.42 alpha:1];
        default: return [UIColor colorWithWhite:0.28 alpha:1];
    }
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
        label.textColor = UIColor.whiteColor;
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
        [_canvas addSubview:view];
        [_controlViews addObject:view];
    }
    [self.view setNeedsLayout];
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
    for (NightPadLayoutControlView *view in _controlViews) {
        view.frame = [self frameForControl:[self controlForId:view.controlId]];
    }
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
