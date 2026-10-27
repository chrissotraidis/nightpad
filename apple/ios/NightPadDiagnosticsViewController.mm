#import "NightPadDiagnosticsViewController.h"

@implementation NightPadDiagnosticsViewController {
    NSString *_report;
    NSURL *_reportURL;
    UITextView *_preview;
    BOOL _autoShared;
}

- (instancetype)initWithReport:(NSString *)report reportURL:(NSURL *)reportURL {
    if ((self = [super initWithNibName:nil bundle:nil])) {
        _report = [report copy];
        _reportURL = [reportURL copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Review Diagnostics";
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];
    self.navigationItem.leftBarButtonItem.accessibilityIdentifier = @"nightpad.diagnostics.close";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(share)];
    self.navigationItem.rightBarButtonItem.accessibilityIdentifier = @"nightpad.diagnostics.share";

    UILabel *notice = [UILabel new];
    notice.text = @"Review this draft before sharing. NightPad does not upload it or contact anyone automatically. "
                   @"Saves, game data, screenshots and input captures are not included.";
    notice.numberOfLines = 0;
    notice.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    notice.adjustsFontForContentSizeCategory = YES;
    notice.textColor = UIColor.secondaryLabelColor;
    notice.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:notice];

    _preview = [UITextView new];
    _preview.editable = NO;
    _preview.selectable = NO;
    _preview.text = _report;
    _preview.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
    _preview.adjustsFontForContentSizeCategory = YES;
    _preview.showsVerticalScrollIndicator = NO;
    _preview.accessibilityIdentifier = @"nightpad.diagnostics.preview";
    _preview.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_preview];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [notice.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
        [notice.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        [notice.topAnchor constraintEqualToAnchor:safe.topAnchor constant:12],
        [_preview.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:12],
        [_preview.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-12],
        [_preview.topAnchor constraintEqualToAnchor:notice.bottomAnchor constant:10],
        [_preview.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-12],
    ]];
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.onClose) self.onClose();
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_autoShared && [NSProcessInfo.processInfo.arguments containsObject:@"--diagnostics-share"]) {
        _autoShared = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 200 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            [self share];
        });
    }
}

- (void)share {
    UIActivityViewController *share = [[UIActivityViewController alloc]
        initWithActivityItems:@[_reportURL ?: _report] applicationActivities:nil];
    share.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
    [self presentViewController:share animated:YES completion:nil];
}

@end
