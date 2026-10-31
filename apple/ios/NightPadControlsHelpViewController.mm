#import "NightPadControlsHelpViewController.h"

@interface NightPadControlsHelpViewController ()
@end

@implementation NightPadControlsHelpViewController

// Face buttons keep the overlay's Xbox colours; everything else is graphite.
static UIColor *BadgeColour(NSString *control) {
    if ([control isEqualToString:@"A"]) return [UIColor colorWithRed:0.10 green:0.62 blue:0.30 alpha:1];
    if ([control isEqualToString:@"B"]) return [UIColor colorWithRed:0.86 green:0.18 blue:0.20 alpha:1];
    if ([control isEqualToString:@"X"]) return [UIColor colorWithRed:0.12 green:0.46 blue:0.92 alpha:1];
    if ([control isEqualToString:@"Y"]) return [UIColor colorWithRed:0.86 green:0.68 blue:0.08 alpha:1];
    if ([control isEqualToString:@"White"]) return [UIColor colorWithWhite:0.9 alpha:1];
    if ([control isEqualToString:@"Black"]) return [UIColor colorWithWhite:0.02 alpha:1];
    return [UIColor colorWithWhite:0.22 alpha:1];
}

- (UIView *)rowWithControl:(NSString *)control action:(NSString *)action {
    UILabel *badgeText = [UILabel new];
    badgeText.text = control;
    badgeText.textColor = [control isEqualToString:@"White"] ? UIColor.blackColor : UIColor.whiteColor;
    badgeText.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    badgeText.font = [UIFont systemFontOfSize:badgeText.font.pointSize weight:UIFontWeightSemibold];
    badgeText.translatesAutoresizingMaskIntoConstraints = NO;
    UIView *badge = [UIView new];
    badge.backgroundColor = BadgeColour(control);
    badge.layer.cornerRadius = 8;
    badge.layer.borderWidth = 1;
    badge.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.18].CGColor;
    badge.translatesAutoresizingMaskIntoConstraints = NO;
    [badge addSubview:badgeText];
    UIView *column = [UIView new];
    column.translatesAutoresizingMaskIntoConstraints = NO;
    [column addSubview:badge];

    UILabel *label = [UILabel new];
    label.text = action;
    label.numberOfLines = 0;
    label.adjustsFontForContentSizeCategory = YES;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    label.textColor = [UIColor colorWithWhite:1 alpha:0.88];

    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[column, label]];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.spacing = 14;
    row.alignment = UIStackViewAlignmentCenter;
    row.isAccessibilityElement = YES;
    row.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", control, action];
    [NSLayoutConstraint activateConstraints:@[
        [column.widthAnchor constraintEqualToConstant:150],
        [badge.leadingAnchor constraintEqualToAnchor:column.leadingAnchor],
        [badge.trailingAnchor constraintLessThanOrEqualToAnchor:column.trailingAnchor],
        [badge.topAnchor constraintEqualToAnchor:column.topAnchor],
        [badge.bottomAnchor constraintEqualToAnchor:column.bottomAnchor],
        [badgeText.leadingAnchor constraintEqualToAnchor:badge.leadingAnchor constant:10],
        [badgeText.trailingAnchor constraintEqualToAnchor:badge.trailingAnchor constant:-10],
        [badgeText.topAnchor constraintEqualToAnchor:badge.topAnchor constant:4],
        [badgeText.bottomAnchor constraintEqualToAnchor:badge.bottomAnchor constant:-4],
    ]];
    return row;
}

- (UIView *)cardWithTitle:(NSString *)title rows:(NSArray<NSArray<NSString *> *> *)rows {
    UIView *card = [UIView new];
    card.backgroundColor = [UIColor colorWithWhite:0.09 alpha:1];
    card.layer.cornerRadius = 16;
    card.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.16].CGColor;
    card.layer.borderWidth = 1;
    card.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *heading = [UILabel new];
    heading.text = title;
    heading.textColor = UIColor.whiteColor;
    heading.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3];
    heading.font = [UIFont systemFontOfSize:heading.font.pointSize weight:UIFontWeightBold];
    heading.adjustsFontForContentSizeCategory = YES;
    heading.translatesAutoresizingMaskIntoConstraints = NO;
    heading.accessibilityTraits = UIAccessibilityTraitHeader;
    [card addSubview:heading];

    UIStackView *stack = [UIStackView new];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 10;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:stack];

    for (NSArray<NSString *> *row in rows)
        [stack addArrangedSubview:[self rowWithControl:row[0] action:row[1]]];

    [NSLayoutConstraint activateConstraints:@[
        [heading.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18],
        [heading.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18],
        [heading.topAnchor constraintEqualToAnchor:card.topAnchor constant:16],
        [stack.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:heading.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:heading.bottomAnchor constant:14],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16],
    ]];
    return card;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Control Guide";
    self.view.backgroundColor = UIColor.blackColor;
    // The guide is always dark, so the navigation title must be light.
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    self.navigationController.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];

    UILabel *intro = [UILabel new];
    intro.text = @"NightPad sends Xbox controls, so the game's eight control schemes and its inversion, "
                 @"aim and crouch preferences stay in charge. A physical controller uses the same mapping as "
                 @"the touch layout. The game's Controller Setup offers Nightfire, Moonraker, Octopussy, "
                 @"Goldfinger, Dr. No, Thunderball, GoldenEye and Classic Bond.";
    intro.numberOfLines = 0;
    intro.adjustsFontForContentSizeCategory = YES;
    intro.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    intro.textColor = [UIColor colorWithWhite:1 alpha:0.7];

    UIStackView *stack = [UIStackView new];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 14;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [stack addArrangedSubview:intro];
    [stack addArrangedSubview:[self cardWithTitle:@"On foot" rows:@[
        @[ @"Left stick", @"Move" ],
        @[ @"Right stick", @"Look and aim" ],
        @[ @"RT", @"Fire" ],
        @[ @"LT", @"Scope zoom" ],
        @[ @"Y", @"Jump" ],
        @[ @"A", @"Crouch" ],
        @[ @"X", @"Reload / context action" ],
        @[ @"White", @"Alternate fire" ],
        @[ @"Black", @"Next gadget" ],
        @[ @"D-pad", @"Weapon and gadget selection" ],
        @[ @"Back", @"Night vision" ],
        @[ @"Start", @"Original game pause" ],
    ]]];
    [stack addArrangedSubview:[self cardWithTitle:@"Driving" rows:@[
        @[ @"Left stick", @"Steer" ],
        @[ @"Right stick", @"Camera" ],
        @[ @"RT", @"Gas" ],
        @[ @"LT", @"Brake" ],
        @[ @"B", @"Handbrake" ],
        @[ @"A", @"Fire secondary" ],
        @[ @"X", @"Fire gadget" ],
        @[ @"Y", @"Change camera" ],
        @[ @"White / Black", @"Secondary weapon up and down" ],
        @[ @"D-pad left / right", @"Secondary up and down" ],
    ]]];
    [stack addArrangedSubview:[self cardWithTitle:@"Mounted views (varies by mount)" rows:@[
        @[ @"Both sticks", @"Camera" ],
        @[ @"RT", @"Fire" ],
        @[ @"LT", @"Zoom" ],
        @[ @"Y", @"Camera spin (B on some mounts)" ],
        @[ @"A", @"Reload (X on one mount)" ],
        @[ @"D-pad / face buttons", @"Cycle secondary weapon" ],
        @[ @"D-pad up / down", @"Camera zoom in and out" ],
    ]]];
    [stack addArrangedSubview:[self cardWithTitle:@"Menus" rows:@[
        @[ @"D-pad", @"Move selection" ],
        @[ @"A", @"Accept" ],
        @[ @"B", @"Back" ],
        @[ @"Start", @"Original game pause" ],
    ]]];

    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scroll];
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
        [stack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor constant:-40],
    ]];
}

- (void)done {
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.onClose)
            self.onClose();
    }];
}

@end
