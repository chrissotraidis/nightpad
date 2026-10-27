#import "NightPadAboutViewController.h"

@implementation NightPadAboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"About NightPad";
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];
    self.navigationItem.leftBarButtonItem.accessibilityIdentifier = @"nightpad.about.close";

    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scroll];
    UIStackView *stack = [UIStackView new];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 14;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:stack];
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [scroll.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],
        [scroll.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor constant:-20],
        [stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:16],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-20],
        [stack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor constant:-40],
    ]];

    UILabel *title = [UILabel new];
    title.text = @"NightPad";
    title.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleLargeTitle]
        scaledFontForFont:[UIFont monospacedSystemFontOfSize:30 weight:UIFontWeightBold]];
    title.adjustsFontForContentSizeCategory = YES;
    [stack addArrangedSubview:title];
    NSString *version = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"0.1.0";
    [stack addArrangedSubview:[self label:[NSString stringWithFormat:@"Version %@", version] style:UIFontTextStyleFootnote]];
    [stack addArrangedSubview:[self label:
        @"A native Apple port of 007: Nightfire, built around the original Xbox engine and data."
        style:UIFontTextStyleBody]];
    [stack addArrangedSubview:[self label:@"Source and interface donors" style:UIFontTextStyleHeadline]];
    [stack addArrangedSubview:[self link:@"Nightfire engine source" url:@"https://github.com/NightfireResearch/nightfire-cxbx"]];
    [stack addArrangedSubview:[self link:@"GalaxyPad interface donor" url:@"https://github.com/chrissotraidis/galaxypad"]];
    [stack addArrangedSubview:[self link:@"SunPad interface donor" url:@"https://github.com/chrissotraidis/sunpad"]];
    [stack addArrangedSubview:[self label:
        @"NightPad is an independent project and is not affiliated with or endorsed by the game's publishers or rights holders. "
        @"The original game data is supplied by the player; it is not bundled in this app. "
        @"Upstream source and third-party notices remain with their respective projects and are reproduced in the project repository."
        style:UIFontTextStyleFootnote]];
}

- (UILabel *)label:(NSString *)text style:(UIFontTextStyle)style {
    UILabel *label = [UILabel new];
    label.text = text;
    label.numberOfLines = 0;
    label.font = [UIFont preferredFontForTextStyle:style];
    label.adjustsFontForContentSizeCategory = YES;
    label.textColor = style == UIFontTextStyleFootnote ? UIColor.secondaryLabelColor : UIColor.labelColor;
    return label;
}

- (UIButton *)link:(NSString *)title url:(NSString *)url {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
    configuration.title = title;
    configuration.image = [UIImage systemImageNamed:@"arrow.up.right.square"];
    configuration.imagePadding = 8;
    configuration.contentInsets = NSDirectionalEdgeInsetsZero;
    button.configuration = configuration;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button.accessibilityIdentifier = [@"nightpad.about.link." stringByAppendingString:title];
    [button addAction:[UIAction actionWithHandler:^(__kindof UIAction *action) {
        (void)action;
        NSURL *target = [NSURL URLWithString:url];
        if (target) [UIApplication.sharedApplication openURL:target options:@{} completionHandler:nil];
    }] forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.onClose) self.onClose();
    }];
}

@end
