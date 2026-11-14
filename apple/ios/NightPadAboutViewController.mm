#import "NightPadAboutViewController.h"

// Matches the Control Guide: dark page sheet, Done on the right, grouped cards.
@implementation NightPadAboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"About NightPad";
    self.view.backgroundColor = UIColor.blackColor;
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    self.navigationController.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];
    self.navigationItem.rightBarButtonItem.accessibilityIdentifier = @"nightpad.about.close";

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
        [stack.leadingAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.trailingAnchor constant:-20],
        [stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:16],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-20],
    ]];

    [stack addArrangedSubview:[self header]];
    [stack addArrangedSubview:[self label:
        @"The original Xbox 007: Nightfire on iPhone and iPad, running its reconstructed action and driving "
        @"engines natively with touch and controller support. You supply your own game data."
        style:UIFontTextStyleBody alpha:0.86]];
    [stack addArrangedSubview:[self cardWithTitle:@"NightPad" rows:@[
        [self link:@"Project on GitHub" icon:@"chevron.left.forwardslash.chevron.right"
               url:@"https://github.com/chrissotraidis/nightpad"],
        [self link:@"Report an Issue" icon:@"exclamationmark.bubble"
               url:@"https://github.com/chrissotraidis/nightpad/issues"],
    ]]];
    [stack addArrangedSubview:[self cardWithTitle:@"Built On" rows:@[
        [self link:@"Nightfire engine reconstruction" icon:@"cpu"
               url:@"https://github.com/NightfireResearch/nightfire-cxbx"],
        [self link:@"GalaxyPad interface" icon:@"square.on.square"
               url:@"https://github.com/chrissotraidis/galaxypad"],
        [self link:@"SunPad input" icon:@"gamecontroller"
               url:@"https://github.com/chrissotraidis/sunpad"],
    ]]];
    [stack addArrangedSubview:[self label:
        @"NightPad is an independent project and is not affiliated with or endorsed by the game's publishers or "
        @"rights holders. No game data is bundled with the app. Upstream source and third-party notices remain "
        @"with their projects and are reproduced in the NightPad repository."
        style:UIFontTextStyleFootnote alpha:0.55]];
}

- (UIView *)header {
    UIImageView *image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LauncherBackdrop"]];
    image.contentMode = UIViewContentModeScaleAspectFill;
    image.clipsToBounds = YES;
    image.layer.cornerRadius = 16;
    image.translatesAutoresizingMaskIntoConstraints = NO;
    [image.heightAnchor constraintEqualToConstant:150].active = YES;

    UILabel *title = [UILabel new];
    title.text = @"NIGHTPAD";
    title.textColor = UIColor.whiteColor;
    title.font = [UIFont monospacedSystemFontOfSize:30 weight:UIFontWeightHeavy];
    NSString *version = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"0.2.1";
    NSString *build = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"2";
    UILabel *subtitle = [UILabel new];
    subtitle.text = [NSString stringWithFormat:@"Version %@ (%@)", version, build];
    subtitle.textColor = [UIColor colorWithWhite:1 alpha:0.75];
    subtitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    UIStackView *text = [[UIStackView alloc] initWithArrangedSubviews:@[title, subtitle]];
    text.axis = UILayoutConstraintAxisVertical;
    text.spacing = 2;
    text.translatesAutoresizingMaskIntoConstraints = NO;
    [image addSubview:text];
    [NSLayoutConstraint activateConstraints:@[
        [text.leadingAnchor constraintEqualToAnchor:image.leadingAnchor constant:20],
        [text.centerYAnchor constraintEqualToAnchor:image.centerYAnchor],
    ]];
    return image;
}

- (UILabel *)label:(NSString *)text style:(UIFontTextStyle)style alpha:(CGFloat)alpha {
    UILabel *label = [UILabel new];
    label.text = text;
    label.numberOfLines = 0;
    label.font = [UIFont preferredFontForTextStyle:style];
    label.adjustsFontForContentSizeCategory = YES;
    label.textColor = [UIColor colorWithWhite:1 alpha:alpha];
    return label;
}

- (UIView *)cardWithTitle:(NSString *)title rows:(NSArray<UIView *> *)rows {
    UIView *card = [UIView new];
    card.backgroundColor = [UIColor colorWithWhite:0.09 alpha:1];
    card.layer.cornerRadius = 16;
    card.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.16].CGColor;
    card.layer.borderWidth = 1;
    UILabel *heading = [UILabel new];
    heading.text = title;
    heading.textColor = UIColor.whiteColor;
    heading.font = [UIFont systemFontOfSize:[UIFont preferredFontForTextStyle:UIFontTextStyleTitle3].pointSize
                                     weight:UIFontWeightBold];
    heading.accessibilityTraits = UIAccessibilityTraitHeader;
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:[@[heading] arrayByAddingObjectsFromArray:rows]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 6;
    stack.alignment = UIStackViewAlignmentLeading;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18],
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor constant:16],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-12],
    ]];
    return card;
}

- (UIButton *)link:(NSString *)title icon:(NSString *)icon url:(NSString *)url {
    UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
    configuration.title = title;
    configuration.image = [UIImage systemImageNamed:icon];
    configuration.imagePadding = 10;
    configuration.contentInsets = NSDirectionalEdgeInsetsMake(8, 0, 8, 0);
    UIButton *button = [UIButton buttonWithConfiguration:configuration primaryAction:nil];
    button.accessibilityIdentifier = [@"nightpad.about.link." stringByAppendingString:title];
    button.accessibilityHint = url;
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
