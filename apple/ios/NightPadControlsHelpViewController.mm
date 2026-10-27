#import "NightPadControlsHelpViewController.h"

@interface NightPadControlsHelpViewController ()
@end

@implementation NightPadControlsHelpViewController

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
    heading.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    heading.adjustsFontForContentSizeCategory = YES;
    heading.translatesAutoresizingMaskIntoConstraints = NO;
    heading.accessibilityTraits = UIAccessibilityTraitHeader;
    [card addSubview:heading];

    UIStackView *stack = [UIStackView new];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 8;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:stack];

    for (NSArray<NSString *> *row in rows) {
        UILabel *line = [UILabel new];
        line.numberOfLines = 0;
        line.adjustsFontForContentSizeCategory = YES;
        line.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        line.textColor = [UIColor colorWithWhite:1 alpha:0.82];
        line.text = [NSString stringWithFormat:@"%@  —  %@", row[0], row[1]];
        line.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", row[0], row[1]];
        [stack addArrangedSubview:line];
    }

    [NSLayoutConstraint activateConstraints:@[
        [heading.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18],
        [heading.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18],
        [heading.topAnchor constraintEqualToAnchor:card.topAnchor constant:16],
        [stack.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:heading.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:heading.bottomAnchor constant:10],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16],
    ]];
    return card;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Controls";
    self.view.backgroundColor = UIColor.blackColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];

    UILabel *intro = [UILabel new];
    intro.text = @"NightPad sends Xbox controls, so the game's eight control schemes and its inversion, "
                 @"aim and crouch preferences stay in charge. A physical controller uses the same mapping as "
                 @"the touch layout.";
    intro.numberOfLines = 0;
    intro.adjustsFontForContentSizeCategory = YES;
    intro.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
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
        @[ @"White (LB)", @"Alternate fire" ],
        @[ @"Black (RB)", @"Next gadget" ],
        @[ @"D-pad", @"Weapon and gadget selection" ],
        @[ @"Back", @"Night vision" ],
        @[ @"Start", @"Original game pause" ],
    ]]];
    [stack addArrangedSubview:[self cardWithTitle:@"Driving and turrets" rows:@[
        @[ @"Left stick", @"Steer" ],
        @[ @"Right stick", @"Camera" ],
        @[ @"RT", @"Gas" ],
        @[ @"LT", @"Brake" ],
        @[ @"B", @"Handbrake" ],
        @[ @"A", @"Fire secondary" ],
        @[ @"X", @"Fire gadget" ],
        @[ @"Y", @"Change camera" ],
        @[ @"White / Black", @"Secondary up and down" ],
        @[ @"D-pad left / right", @"Secondary up and down" ],
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
