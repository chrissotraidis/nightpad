#import "NightPadShellViewController.h"
#import "NightPadEngineHost.h"
#import "NightPadDiagnosticsViewController.h"
#import "NightPadAboutViewController.h"
#import "NightPadTouchLayoutViewController.h"
#import "NightPadControlsHelpViewController.h"
#import "NightPadGameInput.h"
#import "NightPadTouchControlsView.h"

#include "../shared/NightPadGameDataImport.h"
#include "../shared/NightPadBackgroundPolicy.h"
#include "../shared/NightPadDiagnostics.h"
#include "../shared/NightPadSettings.h"
#include "../shared/NightPadTouchPolicy.h"
#include "../shared/NightPadTouchLayout.h"

#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#include <mach/mach.h>
#include <mach/task_info.h>
#include <memory>

using nightpad::DataState;
using nightpad::GameDataImporter;
using nightpad::Paths;

@interface NightPadMenuButton : UIButton
@property(nonatomic, copy) void (^visibilityChanged)(BOOL visible);
@end

@interface NightPadPassThroughView : UIView
@end

@implementation NightPadPassThroughView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    return hit == self ? nil : hit;
}
@end

@implementation NightPadMenuButton
- (void)contextMenuInteraction:(UIContextMenuInteraction *)interaction
    willDisplayMenuForConfiguration:(UIContextMenuConfiguration *)configuration
    animator:(id<UIContextMenuInteractionAnimating>)animator {
    if (self.visibilityChanged) self.visibilityChanged(YES);
    [super contextMenuInteraction:interaction willDisplayMenuForConfiguration:configuration animator:animator];
}
- (void)contextMenuInteraction:(UIContextMenuInteraction *)interaction
    willEndForConfiguration:(UIContextMenuConfiguration *)configuration
    animator:(id<UIContextMenuInteractionAnimating>)animator {
    [super contextMenuInteraction:interaction willEndForConfiguration:configuration animator:animator];
    // GalaxyPad's pinned fix: reconcile as dismissal starts, since the iPad
    // animator completion is not guaranteed for primary-action menus.
    if (self.visibilityChanged) self.visibilityChanged(NO);
}
- (CGRect)imageRectForContentRect:(CGRect)contentRect {
    return CGRectInset(contentRect, 12, 12);
}
@end

@interface NightPadShellViewController () <UIDocumentPickerDelegate, UIAdaptivePresentationControllerDelegate>
- (void)presentAfterMenu:(UIViewController *)controller attempt:(NSInteger)tries;
@end

@implementation NightPadShellViewController {
    Paths _paths;
    std::unique_ptr<GameDataImporter> _importer;
    NSString *_identity;
    DataState _state;
    BOOL _importing;
    NightPadEngineHost *_engineHost;
    BOOL _engineRunning;
    BOOL _enginePaused;
    BOOL _switchingEngine;
    BOOL _engineTeardown;
    BOOL _stopWhenBooted;
    BOOL _forceStopNow;
    BOOL _applicationActive;
    BOOL _nativeMenuVisible;
    BOOL _menuNeedsRefresh;
    BOOL _nativeSurfaceVisible;
    unsigned _alertPauseCount;
    BOOL _traceNativeUI;
    NSTimeInterval _lastUiTrace;
    NSTimeInterval _stopQueuedAt;
    BOOL _uiPausedEngine;
    BOOL _uiInputSuspended;
    BOOL _pendingDiagnostics;
    BOOL _pendingAbout;
    BOOL _pendingFixtureImport;
    BOOL _pickingSaveFiles;
    BOOL _pendingTouchLayout;
    BOOL _pendingControlsHelp;
    BOOL _pendingSaveFixture;
    BOOL _pendingPausePanel;
    BOOL _pendingGameplayPreview;
    nightpad::AppSettings _settings;
    BOOL _gameplayMode;
    NSTimer *_engineTimer;

    UILabel *_title;
    UILabel *_status;
    NightPadMenuButton *_menuButton;
    UIView *_dataPanel;
    UIView *_pausePanel;
    UIProgressView *_progress;
    UILabel *_progressLabel;
    UILabel *_dataStatus;
    UIButton *_importButton;
    UIButton *_cancelImportButton;
    UIButton *_discardButton;
    NightPadTouchControlsView *_touchControls;
    NightPadGameInput *_gameInput;
    NSMutableArray<NSString *> *_sessionLog;
    NSString *_lastError;
}

static uint32_t ShellThreadCount(void) {
    thread_act_array_t threads = nullptr;
    mach_msg_type_number_t count = 0;
    if (task_threads(mach_task_self(), &threads, &count) != KERN_SUCCESS)
        return 0;
    for (mach_msg_type_number_t i = 0; i < count; ++i)
        mach_port_deallocate(mach_task_self(), threads[i]);
    vm_deallocate(mach_task_self(), reinterpret_cast<vm_address_t>(threads), count * sizeof(thread_t));
    return count;
}

static uint64_t ShellResidentBytes(void) {
    task_vm_info_data_t info = {};
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    if (task_info(mach_task_self(), TASK_VM_INFO, reinterpret_cast<task_info_t>(&info), &count) != KERN_SUCCESS)
        return 0;
    return info.phys_footprint;
}

- (void)loadView {
    self.view = [[NightPadPassThroughView alloc] initWithFrame:UIScreen.mainScreen.bounds];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    _engineHost = [NightPadEngineHost new];
    _applicationActive = UIApplication.sharedApplication.applicationState == UIApplicationStateActive;
    _traceNativeUI = [NSProcessInfo.processInfo.arguments containsObject:@"--log-native-ui"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowBecameKey:)
        name:UIWindowDidBecomeKeyNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:)
        name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:)
        name:UIApplicationDidBecomeActiveNotification object:nil];

    _title = [UILabel new];
    _title.text = @"NIGHTPAD";
    _title.textColor = UIColor.whiteColor;
    _title.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleLargeTitle]
        scaledFontForFont:[UIFont monospacedSystemFontOfSize:30 weight:UIFontWeightBold]];
    _title.adjustsFontForContentSizeCategory = YES;
    _title.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_title];

    _status = [UILabel new];
    _status.textColor = [UIColor colorWithWhite:1 alpha:0.78];
    _status.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _status.adjustsFontForContentSizeCategory = YES;
    _status.numberOfLines = 0;
    _status.textAlignment = NSTextAlignmentCenter;
    _status.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_status];

    _menuButton = [NightPadMenuButton buttonWithType:UIButtonTypeCustom];
    // SunPad's three-dot button: a 40-point capsule with a plain ellipsis on a
    // dark translucent plate, built through a button configuration so the menu
    // presentation keeps the same circular shape instead of gaining the system
    // button chrome.
    UIImageSymbolConfiguration *symbol =
        [UIImageSymbolConfiguration configurationWithPointSize:19.0 weight:UIImageSymbolWeightBold];
    UIImage *ellipsis = [UIImage systemImageNamed:@"ellipsis" withConfiguration:symbol];
    [_menuButton setImage:ellipsis forState:UIControlStateNormal];
    _menuButton.accessibilityLabel = @"Menu";
    _menuButton.accessibilityIdentifier = @"nightpad.menu";
    _menuButton.showsMenuAsPrimaryAction = YES;
    __weak NightPadShellViewController *weakMenuSelf = self;
    _menuButton.visibilityChanged = ^(BOOL visible) {
        NightPadShellViewController *owner = weakMenuSelf;
        if (owner == nil) return;
        owner->_nativeMenuVisible = visible;
        [owner reconcileNativeUI];
        if (!visible && owner->_menuNeedsRefresh) {
            owner->_menuNeedsRefresh = NO;
            [owner refreshMenu];
        }
    };
    if (@available(iOS 15.0, *))
        _menuButton.changesSelectionAsPrimaryAction = NO;

    UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
    configuration.image = ellipsis;
    configuration.baseForegroundColor = UIColor.whiteColor;
    configuration.contentInsets = NSDirectionalEdgeInsetsZero;
    configuration.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    UIBackgroundConfiguration *background = [UIBackgroundConfiguration clearConfiguration];
    background.backgroundColor = [UIColor colorWithWhite:0.06 alpha:0.72];
    background.cornerRadius = 20.0;
    background.strokeColor = [UIColor colorWithWhite:1.0 alpha:0.30];
    background.strokeWidth = 1.0;
    configuration.background = background;
    _menuButton.automaticallyUpdatesConfiguration = NO;
    _menuButton.configuration = configuration;
    _menuButton.tintColor = UIColor.whiteColor;
    _menuButton.backgroundColor = UIColor.clearColor;
    _menuButton.layer.borderWidth = 0.0;
    _menuButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_menuButton];

    [self buildDataPanel];
    [self buildPausePanel];

    [NSLayoutConstraint activateConstraints:@[
        [_title.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_title.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:36],
        [_status.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_status.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [_status.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:30],
        [_status.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-30],
        [_menuButton.widthAnchor constraintEqualToConstant:44],
        [_menuButton.heightAnchor constraintEqualToConstant:44],
        [_menuButton.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-12],
        [_menuButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:12],
    ]];

    std::string pathError;
    _paths = Paths::ForContainer(NSHomeDirectory().UTF8String);
    if (!_paths.CreateDirectories(&pathError))
        [self showError:[NSString stringWithUTF8String:pathError.c_str()]];
    std::string settingsError;
    if (!_settings.Load(_paths.appSupport / "settings.txt", &settingsError) &&
        settingsError != "The settings file is missing.")
        [self showError:[NSString stringWithFormat:@"Saved settings ignored: %s", settingsError.c_str()]];
    [self refreshDataState];
    // Trees left by earlier runs are unreachable once a launch has happened.
    // Deleting gigabytes must not block the first frame, so it runs in the
    // background; a fresh importer has nothing active to protect.
    if (_state == DataState::Ready && _identity.length > 0) {
        nightpad::Paths paths = _paths;
        std::string keep(_identity.UTF8String);
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            nightpad::GameDataImporter importer(paths);
            importer.CleanupAbandonedStages(nullptr);
            importer.RetainOnlyIdentity(keep, nullptr);
        });
    }
    [self refreshMenu];
    // Deterministic shell screenshots and UI smoke tests.
    if ([NSProcessInfo.processInfo.arguments containsObject:@"--show-touch-controls"])
        _settings.touchControlsAlwaysVisible = true;
    if ([NSProcessInfo.processInfo.arguments containsObject:@"--open-data"])
        [self openDataPanel];
    else if ([NSProcessInfo.processInfo.arguments containsObject:@"--open-diagnostics"])
        _pendingDiagnostics = YES;
    else if ([NSProcessInfo.processInfo.arguments containsObject:@"--open-about"])
        _pendingAbout = YES;
    else if ([NSProcessInfo.processInfo.arguments containsObject:@"--import-fixture"])
        _pendingFixtureImport = YES;
    else if ([NSProcessInfo.processInfo.arguments containsObject:@"--open-touch-layout"])
        _pendingTouchLayout = YES;
    else if ([NSProcessInfo.processInfo.arguments containsObject:@"--preview-gameplay"])
        _pendingGameplayPreview = YES;
    else if ([NSProcessInfo.processInfo.arguments containsObject:@"--open-control-help"])
        _pendingControlsHelp = YES;
    else if ([NSProcessInfo.processInfo.arguments containsObject:@"--restore-saves-fixture"])
        _pendingSaveFixture = YES;
    else if ([NSProcessInfo.processInfo.arguments containsObject:@"--open-pause"])
        _pendingPausePanel = YES;
    [self logSessionEvent:@"app launch"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (_pendingDiagnostics) {
        _pendingDiagnostics = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            [self openDiagnostics];
        });
    }
    if (_pendingAbout) {
        _pendingAbout = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            [self openAbout];
        });
    }
    if (_pendingFixtureImport) {
        _pendingFixtureImport = NO;
        NSString *documents = [NSString stringWithUTF8String:_paths.documents.string().c_str()];
        NSURL *fixture = [[NSURL fileURLWithPath:documents isDirectory:YES]
            URLByAppendingPathComponent:@"ImportFixture" isDirectory:YES];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            [self importPreparedFolder:fixture];
        });
    }
    if (_pendingTouchLayout) {
        _pendingTouchLayout = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            [self openTouchLayout];
        });
    }
    if (_pendingGameplayPreview) {
        _pendingGameplayPreview = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            self->_gameplayMode = YES;
            [self updateGameplaySurface];
            [self installTouchControls];
        });
    }
    if (_pendingControlsHelp) {
        _pendingControlsHelp = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            [self openControlsHelp];
        });
    }
    if (_pendingSaveFixture) {
        _pendingSaveFixture = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            [self restoreSavesFromFixture];
        });
    }
    if (_pendingPausePanel) {
        _pendingPausePanel = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            [self showPausePanel];
        });
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)prefersStatusBarHidden { return YES; }
- (BOOL)prefersHomeIndicatorAutoHidden { return YES; }

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_engineTimer invalidate];
}

- (void)windowBecameKey:(NSNotification *)note {
    (void)note;
    if (!_gameplayMode || self.view.window == nil) return;
    self.view.window.windowLevel = UIWindowLevelNormal + 2;
    [self.view.window makeKeyAndVisible];
}

- (void)appWillResignActive:(NSNotification *)note {
    (void)note;
    _applicationActive = NO;
    [self reconcileNativeUI];
}

- (void)appDidBecomeActive:(NSNotification *)note {
    (void)note;
    _applicationActive = YES;
    [self reconcileNativeUI];
}

- (UIButton *)panelButton:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
    configuration.title = title;
    configuration.baseForegroundColor = UIColor.whiteColor;
    configuration.contentInsets = NSDirectionalEdgeInsetsMake(10, 16, 10, 16);
    button.configuration = configuration;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIView *)cardWithFrame:(CGRect)frame {
    UIView *card = [[UIView alloc] initWithFrame:frame];
    card.backgroundColor = [UIColor colorWithWhite:0.06 alpha:0.97];
    card.layer.cornerRadius = 18;
    card.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.22].CGColor;
    card.layer.borderWidth = 1;
    card.hidden = YES;
    card.translatesAutoresizingMaskIntoConstraints = NO;
    return card;
}

- (void)presentAfterMenu:(UIViewController *)controller {
    // UIMenu is still dismissing while its action runs; presenting in the same
    // turn is ignored. A launch-time error can run before the view is in a
    // window, where a presentation is dropped too, so retry briefly.
    [self presentAfterMenu:controller attempt:8];
}

- (void)presentAfterMenu:(UIViewController *)controller attempt:(NSInteger)tries {
    __weak NightPadShellViewController *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 150 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        NightPadShellViewController *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        if (strongSelf.view.window == nil && tries > 0) {
            [strongSelf presentAfterMenu:controller attempt:tries - 1];
            return;
        }
        // A sheet waits for whatever is up, but an alert may stack: a second
        // startup error must not be lost behind the first.
        UIViewController *presenter = strongSelf;
        while (presenter.presentedViewController != nil && !presenter.presentedViewController.isBeingDismissed)
            presenter = presenter.presentedViewController;
        if (presenter != strongSelf && ![controller isKindOfClass:[UIAlertController class]])
            return;
        [presenter presentViewController:controller animated:YES completion:^{
            // A sheet swiped away never calls its own close handler; without
            // this the shell would stay in its paused state.
            if ([controller isKindOfClass:[UINavigationController class]])
                controller.presentationController.delegate = strongSelf;
        }];
    });
}

- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController {
    (void)presentationController;
    [self logSessionEvent:@"sheet dismissed"];
    // Interactive dismissal discards unsaved editor changes, as Cancel does.
    if (_touchControls != nil)
        [_touchControls setTouchLayout:[self loadTouchLayout]];
    [self endNativeUI];
    [self refreshMenu];
}

- (void)refreshMenu {
    if (_menuButton == nil)
        return;
    if (_nativeMenuVisible) {
        _menuNeedsRefresh = YES;
        return;
    }
    _menuButton.menu = [self buildMenu];
}

- (UIAction *)menuAction:(NSString *)title
                   image:(NSString *)imageName
                disabled:(BOOL)disabled
                 handler:(void (^)(void))handler {
    __weak NightPadShellViewController *weakSelf = self;
    UIAction *action = [UIAction actionWithTitle:title
                                           image:imageName.length ? [UIImage systemImageNamed:imageName] : nil
                                      identifier:nil
                                         handler:^(__kindof UIAction *selected) {
        (void)selected;
        if (weakSelf != nil && handler != nil)
            handler();
    }];
    if (disabled)
        action.attributes = UIMenuElementAttributesDisabled;
    return action;
}

- (UIMenu *)buildMenu {
    __weak NightPadShellViewController *weakSelf = self;
    const BOOL canStart = _engineRunning || ([NightPadEngineHost isLinked] && _state == DataState::Ready);
    NSString *startTitle = _stopWhenBooted ? @"Stopping After Load…"
        : (_engineRunning ? @"Stop Game" : @"Start Game");
    UIAction *start = [self menuAction:startTitle
                                 image:(_engineRunning ? @"stop.fill" : @"play.fill")
                              disabled:(!canStart || _stopWhenBooted)
                               handler:^{ [weakSelf startGame]; }];
    UIAction *pause = [self menuAction:@"App Pause" image:@"pause.fill" disabled:!_engineRunning
                               handler:^{ [weakSelf showPausePanel]; }];
    // GalaxyPad keeps start/stop in the root menu instead of hiding it behind
    // another submenu. App Pause lives with the rest of the in-session controls.
    UIMenu *game = [UIMenu menuWithTitle:@""
                                   image:nil
                               identifier:nil
                                  options:UIMenuOptionsDisplayInline
                                 children:@[ start ]];

    UIAction *layout = [self menuAction:@"Touch Layout…" image:@"hand.draw" disabled:NO
                                handler:^{ [weakSelf openTouchLayout]; }];
    UIAction *help = [self menuAction:@"Control Help…" image:@"questionmark.circle" disabled:NO
                              handler:^{ [weakSelf openControlsHelp]; }];
    UIAction *show = [self menuAction:@"Show Touch Controls"
                                image:(_settings.touchControlsAlwaysVisible ? @"checkmark.circle.fill" : @"circle")
                             disabled:!_engineRunning
                              handler:^{ [weakSelf toggleTouchControls]; }];
    show.state = _settings.touchControlsAlwaysVisible ? UIMenuElementStateOn : UIMenuElementStateOff;
    UIAction *autoHide = [self menuAction:@"Auto-Hide Touch With Controller" image:@"gamecontroller"
                                 disabled:NO
                                  handler:^{ [weakSelf toggleAutoHideTouch]; }];
    autoHide.state = _settings.hideTouchControlsWithController ? UIMenuElementStateOn : UIMenuElementStateOff;
    UIAction *rumble = [self menuAction:@"Controller Rumble" image:@"waveform" disabled:NO
                                handler:^{ [weakSelf toggleRumble]; }];
    rumble.state = _settings.rumble ? UIMenuElementStateOn : UIMenuElementStateOff;
    const int controllers = _gameInput.controllers.controllerCount;
    NSString *controllerTitle = controllers == 0 ? @"No controller connected"
                                                 : [NSString stringWithFormat:@"%d controller%@ connected",
                                                          controllers, controllers == 1 ? @"" : @"s"];
    UIAction *controllerStatus = [self menuAction:controllerTitle image:@"gamecontroller" disabled:YES handler:nil];
    NSMutableArray<UIAction *> *controlActions =
        [NSMutableArray arrayWithObjects:layout, pause, show, autoHide, rumble, nil];
    if (controllers > 0)
        [controlActions addObject:controllerStatus];
    UIMenu *controls = [UIMenu menuWithTitle:@"Controls"
                                       image:[UIImage systemImageNamed:@"gamecontroller"]
                                  identifier:nil
                                     options:0
                                    children:controlActions];

    NSArray<NSString *> *scaleTitles = @[
        @"Original (640×480)", @"2× (1280×960)", @"3× (1920×1440)", @"4× (2560×1920)"
    ];
    NSMutableArray<UIAction *> *resolutionActions = [NSMutableArray array];
    for (int scale = 1; scale <= 4; ++scale) {
        UIAction *action = [self menuAction:scaleTitles[scale - 1] image:nil disabled:NO handler:^{
            [weakSelf setRenderScale:scale];
        }];
        action.state = (_settings.renderScale == scale) ? UIMenuElementStateOn : UIMenuElementStateOff;
        [resolutionActions addObject:action];
    }
    UIMenu *resolution = [UIMenu menuWithTitle:@"Render Resolution"
                                         image:[UIImage systemImageNamed:@"rectangle.expand.vertical"]
                                    identifier:nil
                                       options:0
                                      children:resolutionActions];

    UIAction *aaOff = [self menuAction:@"Off" image:nil disabled:NO handler:^{ [weakSelf setAntiAliasing:NO]; }];
    aaOff.state = _settings.antiAliasing ? UIMenuElementStateOff : UIMenuElementStateOn;
    UIAction *aaOn = [self menuAction:@"FXAA" image:nil disabled:NO handler:^{ [weakSelf setAntiAliasing:YES]; }];
    aaOn.state = _settings.antiAliasing ? UIMenuElementStateOn : UIMenuElementStateOff;
    UIMenu *antiAliasing = [UIMenu menuWithTitle:@"Anti-Aliasing"
                                           image:[UIImage systemImageNamed:@"sparkles"]
                                      identifier:nil
                                         options:0
                                        children:@[ aaOff, aaOn ]];

    UIAction *wideOff = [self menuAction:@"Original 4:3" image:nil disabled:NO
                                 handler:^{ [weakSelf setWidescreen:NO]; }];
    wideOff.state = _settings.widescreen ? UIMenuElementStateOff : UIMenuElementStateOn;
    UIAction *wideOn = [self menuAction:@"Widescreen 16:9" image:nil disabled:NO
                                handler:^{ [weakSelf setWidescreen:YES]; }];
    wideOn.state = _settings.widescreen ? UIMenuElementStateOn : UIMenuElementStateOff;
    UIMenu *aspect = [UIMenu menuWithTitle:@"Aspect Ratio"
                                     image:[UIImage systemImageNamed:@"rectangle"]
                                identifier:nil
                                   options:0
                                  children:@[ wideOff, wideOn ]];

    NSMutableArray<UIAction *> *fovActions = [NSMutableArray array];
    for (int fov : { 60, 70, 80 }) {
        NSString *title = fov == 60 ? @"60° (Original)" : [NSString stringWithFormat:@"%d°", fov];
        UIAction *action = [self menuAction:title image:nil disabled:NO handler:^{ [weakSelf setFov:fov]; }];
        action.state = (_settings.fov == fov) ? UIMenuElementStateOn : UIMenuElementStateOff;
        [fovActions addObject:action];
    }
    UIMenu *fieldOfView = [UIMenu menuWithTitle:@"Field of View"
                                          image:[UIImage systemImageNamed:@"camera"]
                                     identifier:nil
                                        options:0
                                       children:fovActions];

    UIMenu *display = [UIMenu menuWithTitle:@"Display"
                                      image:[UIImage systemImageNamed:@"display"]
                                 identifier:nil
                                    options:0
                                   children:@[ resolution, antiAliasing, aspect, fieldOfView ]];

    UIAction *immortal = [self menuAction:@"Immortality" image:@"heart.fill" disabled:NO
                                  handler:^{ [weakSelf toggleImmortal]; }];
    immortal.state = _settings.assistImmortal ? UIMenuElementStateOn : UIMenuElementStateOff;
    UIAction *ammo = [self menuAction:@"Unlimited Ammo" image:@"infinity" disabled:NO
                               handler:^{ [weakSelf toggleUnlimitedAmmo]; }];
    ammo.state = _settings.assistUnlimitedAmmo ? UIMenuElementStateOn : UIMenuElementStateOff;
    UIMenu *assists = [UIMenu menuWithTitle:@"Enhancements"
                                      image:[UIImage systemImageNamed:@"shield.lefthalf.filled"]
                                 identifier:nil
                                    options:0
                                   children:@[ immortal, ammo ]];

    UIAction *data = [self menuAction:@"Manage Game Data…" image:@"internaldrive" disabled:NO
                               handler:^{ [weakSelf openDataPanel]; }];
    UIAction *importAction = [self menuAction:@"Import Prepared Game Data…" image:@"folder" disabled:_engineRunning
                                      handler:^{ [weakSelf chooseImportFolder]; }];
    UIAction *folderAction = [self menuAction:@"Import from NightPad Folder" image:@"folder.badge.plus"
                                     disabled:_engineRunning || _importing
                                      handler:^{ [weakSelf importFromAppFolder]; }];
    UIAction *removeAction = [self menuAction:@"Remove Previous Game Data" image:@"trash"
                                     disabled:!(_importer && _importer->previousDataRetained())
                                      handler:^{ [weakSelf discardPrevious]; }];
    UIAction *shareAction = [self menuAction:@"Share Saves…" image:@"square.and.arrow.up" disabled:NO
                                     handler:^{ [weakSelf shareSaves]; }];
    UIAction *restoreAction = [self menuAction:@"Import Saves…" image:@"square.and.arrow.down"
                                      disabled:_engineRunning
                                       handler:^{ [weakSelf chooseSaveFiles]; }];
    UIAction *restoreFolderAction = [self menuAction:@"Restore Saves from NightPad Folder" image:@"folder"
                                           disabled:_engineRunning
                                            handler:^{ [weakSelf restoreSavesFromAppFolder]; }];
    UIMenu *dataMenu = [UIMenu menuWithTitle:@"Data & Saves"
                                       image:[UIImage systemImageNamed:@"internaldrive"]
                                  identifier:nil
                                     options:0
                                    children:@[ data, importAction, folderAction, shareAction, restoreAction,
                                                restoreFolderAction, removeAction ]];

    UIAction *about = [self menuAction:@"About NightPad" image:@"info.circle" disabled:NO
                                handler:^{ [weakSelf openAbout]; }];
    UIAction *diagnostics = [self menuAction:@"Diagnostics" image:@"doc.text.magnifyingglass" disabled:NO
                                     handler:^{ [weakSelf openDiagnostics]; }];
    UIMenu *helpFeedback = [UIMenu menuWithTitle:@"Help & Feedback"
                                           image:[UIImage systemImageNamed:@"questionmark.circle"]
                              identifier:nil
                                 options:0
                                children:@[ help, diagnostics, about ]];

    return [UIMenu menuWithTitle:@"NightPad"
                        children:@[ game, display, controls, dataMenu, assists, helpFeedback ]];
}

- (void)buildDataPanel {
    _dataPanel = [self cardWithFrame:CGRectZero];
    [self.view addSubview:_dataPanel];
    UILabel *heading = [UILabel new];
    heading.text = @"Game Data & Saves";
    heading.textColor = UIColor.whiteColor;
    heading.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    heading.adjustsFontForContentSizeCategory = YES;
    heading.translatesAutoresizingMaskIntoConstraints = NO;
    [_dataPanel addSubview:heading];

    UILabel *detail = [UILabel new];
    detail.text = @"Import a prepared NightPad game-data folder. Saves are stored separately and are not changed.";
    detail.textColor = [UIColor colorWithWhite:1 alpha:0.72];
    detail.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    detail.adjustsFontForContentSizeCategory = YES;
    detail.numberOfLines = 0;
    detail.translatesAutoresizingMaskIntoConstraints = NO;
    [_dataPanel addSubview:detail];

    // The home status label sits behind the panel, so the panel keeps its own
    // copy of the data state.
    _dataStatus = [UILabel new];
    _dataStatus.textColor = [UIColor colorWithWhite:1 alpha:0.86];
    _dataStatus.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    _dataStatus.adjustsFontForContentSizeCategory = YES;
    _dataStatus.numberOfLines = 0;
    _dataStatus.translatesAutoresizingMaskIntoConstraints = NO;
    [_dataPanel addSubview:_dataStatus];

    _importButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButtonConfiguration *import = [UIButtonConfiguration filledButtonConfiguration];
    import.title = @"Import Prepared Game Data…";
    import.image = [UIImage systemImageNamed:@"folder"];
    import.imagePadding = 8;
    _importButton.configuration = import;
    _importButton.translatesAutoresizingMaskIntoConstraints = NO;
    _importButton.showsMenuAsPrimaryAction = YES;
    __weak NightPadShellViewController *weakSelf = self;
    _importButton.menu = [UIMenu menuWithTitle:@"Import Game Data" children:@[
        [UIAction actionWithTitle:@"Choose a Folder…" image:[UIImage systemImageNamed:@"folder"]
                       identifier:nil
                          handler:^(__kindof UIAction *selected) {
            (void)selected;
            [weakSelf chooseImportFolder];
        }],
        [UIAction actionWithTitle:@"Use NightPad Folder" image:[UIImage systemImageNamed:@"folder.badge.plus"]
                       identifier:nil
                          handler:^(__kindof UIAction *selected) {
            (void)selected;
            [weakSelf importFromAppFolder];
        }],
    ]];
    [_dataPanel addSubview:_importButton];

    _discardButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButtonConfiguration *discard = [UIButtonConfiguration tintedButtonConfiguration];
    discard.title = @"Remove Previous Game Data";
    _discardButton.configuration = discard;
    _discardButton.translatesAutoresizingMaskIntoConstraints = NO;
    _discardButton.enabled = NO;
    [_discardButton addTarget:self action:@selector(discardPrevious) forControlEvents:UIControlEventTouchUpInside];
    [_dataPanel addSubview:_discardButton];

    // The panel is "Game Data & Saves", so the save actions belong here too,
    // not only in the three-dot menu.
    UIButton *share = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButtonConfiguration *shareConfiguration = [UIButtonConfiguration tintedButtonConfiguration];
    shareConfiguration.title = @"Share Saves…";
    shareConfiguration.image = [UIImage systemImageNamed:@"square.and.arrow.up"];
    shareConfiguration.imagePadding = 6;
    share.configuration = shareConfiguration;
    share.translatesAutoresizingMaskIntoConstraints = NO;
    [share addTarget:self action:@selector(shareSaves) forControlEvents:UIControlEventTouchUpInside];
    [_dataPanel addSubview:share];
    UIButton *restore = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButtonConfiguration *restoreConfiguration = [UIButtonConfiguration tintedButtonConfiguration];
    restoreConfiguration.title = @"Restore Saves…";
    restoreConfiguration.image = [UIImage systemImageNamed:@"square.and.arrow.down"];
    restoreConfiguration.imagePadding = 6;
    restore.configuration = restoreConfiguration;
    restore.translatesAutoresizingMaskIntoConstraints = NO;
    restore.showsMenuAsPrimaryAction = YES;
    restore.menu = [UIMenu menuWithTitle:@"Restore Saves" children:@[
        [UIAction actionWithTitle:@"Choose Files…" image:[UIImage systemImageNamed:@"folder"]
                       identifier:nil
                          handler:^(__kindof UIAction *selected) {
            (void)selected;
            [weakSelf chooseSaveFiles];
        }],
        [UIAction actionWithTitle:@"Use Save Import Folder" image:[UIImage systemImageNamed:@"folder.badge.plus"]
                       identifier:nil
                          handler:^(__kindof UIAction *selected) {
            (void)selected;
            [weakSelf restoreSavesFromAppFolder];
        }],
    ]];
    [_dataPanel addSubview:restore];

    _progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _progress.translatesAutoresizingMaskIntoConstraints = NO;
    _progress.hidden = YES;
    [_dataPanel addSubview:_progress];
    _progressLabel = [UILabel new];
    _progressLabel.textColor = [UIColor colorWithWhite:1 alpha:0.78];
    _progressLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    _progressLabel.adjustsFontForContentSizeCategory = YES;
    _progressLabel.numberOfLines = 2;
    _progressLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_dataPanel addSubview:_progressLabel];

    UIButton *cancel = [self panelButton:@"Cancel Import" action:@selector(cancelImport)];
    cancel.translatesAutoresizingMaskIntoConstraints = NO;
    [_dataPanel addSubview:cancel];
    _cancelImportButton = cancel;
    UIButton *close = [self panelButton:@"Close" action:@selector(dismissPanels)];
    close.translatesAutoresizingMaskIntoConstraints = NO;
    [_dataPanel addSubview:close];

    [NSLayoutConstraint activateConstraints:@[
        [_dataPanel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_dataPanel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [_dataPanel.widthAnchor constraintEqualToConstant:500],
        [heading.leadingAnchor constraintEqualToAnchor:_dataPanel.leadingAnchor constant:20],
        [heading.topAnchor constraintEqualToAnchor:_dataPanel.topAnchor constant:18],
        [detail.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [detail.trailingAnchor constraintEqualToAnchor:_dataPanel.trailingAnchor constant:-20],
        [detail.topAnchor constraintEqualToAnchor:heading.bottomAnchor constant:6],
        [_dataStatus.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [_dataStatus.trailingAnchor constraintEqualToAnchor:detail.trailingAnchor],
        [_dataStatus.topAnchor constraintEqualToAnchor:detail.bottomAnchor constant:10],
        [_importButton.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [_importButton.topAnchor constraintEqualToAnchor:_dataStatus.bottomAnchor constant:14],
        [_discardButton.leadingAnchor constraintEqualToAnchor:_importButton.trailingAnchor constant:12],
        [_discardButton.centerYAnchor constraintEqualToAnchor:_importButton.centerYAnchor],
        [share.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [share.topAnchor constraintEqualToAnchor:_importButton.bottomAnchor constant:10],
        [restore.leadingAnchor constraintEqualToAnchor:share.trailingAnchor constant:12],
        [restore.centerYAnchor constraintEqualToAnchor:share.centerYAnchor],
        [_progress.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [_progress.trailingAnchor constraintEqualToAnchor:detail.trailingAnchor],
        [_progress.topAnchor constraintEqualToAnchor:share.bottomAnchor constant:12],
        [_progressLabel.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [_progressLabel.trailingAnchor constraintEqualToAnchor:detail.trailingAnchor],
        [_progressLabel.topAnchor constraintEqualToAnchor:_progress.bottomAnchor constant:6],
        [cancel.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [cancel.topAnchor constraintEqualToAnchor:_progressLabel.bottomAnchor constant:14],
        [cancel.bottomAnchor constraintEqualToAnchor:_dataPanel.bottomAnchor constant:-12],
        [close.trailingAnchor constraintEqualToAnchor:detail.trailingAnchor],
        [close.centerYAnchor constraintEqualToAnchor:cancel.centerYAnchor],
    ]];
}

- (void)buildPausePanel {
    _pausePanel = [self cardWithFrame:CGRectZero];
    [self.view addSubview:_pausePanel];
    UILabel *label = [UILabel new];
    label.text = @"App Paused";
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1];
    label.adjustsFontForContentSizeCategory = YES;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [_pausePanel addSubview:label];
    UILabel *detail = [UILabel new];
    detail.text = @"The engine is held at a native pause boundary. Original Xbox Start pause remains separate.";
    detail.textColor = [UIColor colorWithWhite:1 alpha:0.72];
    detail.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    detail.adjustsFontForContentSizeCategory = YES;
    detail.numberOfLines = 0;
    detail.translatesAutoresizingMaskIntoConstraints = NO;
    [_pausePanel addSubview:detail];
    UIButton *back = [self panelButton:@"Back to Game" action:@selector(resumeFromPause)];
    back.translatesAutoresizingMaskIntoConstraints = NO;
    [_pausePanel addSubview:back];
    [NSLayoutConstraint activateConstraints:@[
        [_pausePanel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_pausePanel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [_pausePanel.widthAnchor constraintEqualToConstant:460],
        [label.leadingAnchor constraintEqualToAnchor:_pausePanel.leadingAnchor constant:24],
        [label.topAnchor constraintEqualToAnchor:_pausePanel.topAnchor constant:24],
        [detail.leadingAnchor constraintEqualToAnchor:label.leadingAnchor],
        [detail.trailingAnchor constraintEqualToAnchor:_pausePanel.trailingAnchor constant:-24],
        [detail.topAnchor constraintEqualToAnchor:label.bottomAnchor constant:8],
        [back.leadingAnchor constraintEqualToAnchor:label.leadingAnchor],
        [back.topAnchor constraintEqualToAnchor:detail.bottomAnchor constant:18],
        [back.bottomAnchor constraintEqualToAnchor:_pausePanel.bottomAnchor constant:-16],
    ]];
}

- (void)closePanels {
    _dataPanel.hidden = YES;
    _pausePanel.hidden = YES;
    _status.hidden = _gameplayMode;
}

- (void)openDataPanel {
    [self beginNativeUI];
    [self closePanels];
    _dataPanel.hidden = NO;
    _status.hidden = YES;
    [self.view bringSubviewToFront:_dataPanel];
}

- (void)showPausePanel {
    [self beginNativeUI];
    [self closePanels];
    _pausePanel.hidden = NO;
    _status.hidden = YES;
    [self.view bringSubviewToFront:_pausePanel];
}

- (void)resumeFromPause {
    [self closePanels];
    [self endNativeUI];
}

- (void)openAbout {
    [self beginNativeUI];
    [self closePanels];
    NightPadAboutViewController *about = [NightPadAboutViewController new];
    __weak NightPadShellViewController *weakSelf = self;
    about.onClose = ^{ [weakSelf endNativeUI]; };
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:about];
    navigation.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentAfterMenu:navigation];
}

- (void)dismissPanels {
    [self closePanels];
    [self endNativeUI];
}

- (nightpad::TouchDeviceClass)touchDeviceClass {
    return UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad
        ? nightpad::TouchDeviceClass::Tablet : nightpad::TouchDeviceClass::Phone;
}

- (NSURL *)touchLayoutURL {
    NSString *controls = [NSString stringWithUTF8String:(_paths.appSupport / "Controls").c_str()];
    NSString *name = [NSString stringWithFormat:@"layout-%s.txt",
        nightpad::TouchDeviceName([self touchDeviceClass])];
    return [NSURL fileURLWithPath:[controls stringByAppendingPathComponent:name]];
}

- (nightpad::TouchLayout)loadTouchLayout {
    nightpad::TouchLayout layout = nightpad::TouchLayout::Defaults([self touchDeviceClass]);
    std::string loadError;
    if (!layout.Load([self touchLayoutURL].fileSystemRepresentation, &loadError) &&
        loadError != "The layout file is missing." &&
        loadError != "Unsupported touch-layout version.")
        [self showError:[NSString stringWithFormat:@"Saved touch layout ignored: %s", loadError.c_str()]];
    return layout;
}

- (void)openTouchLayout {
    [self beginNativeUI];
    [self closePanels];
    nightpad::TouchLayout layout = [self loadTouchLayout];
    NSURL *url = [self touchLayoutURL];
    NightPadTouchLayoutViewController *editor = [[NightPadTouchLayoutViewController alloc]
        initWithLayout:layout savePath:url];
    __weak NightPadShellViewController *weakSelf = self;
    editor.onClose = ^{
        NightPadShellViewController *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        if (strongSelf->_touchControls != nil)
            [strongSelf->_touchControls setTouchLayout:[strongSelf loadTouchLayout]];
        [strongSelf endNativeUI];
        [strongSelf refreshMenu];
    };
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:editor];
    navigation.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentAfterMenu:navigation];
}

- (void)openControlsHelp {
    [self beginNativeUI];
    [self closePanels];
    NightPadControlsHelpViewController *help = [NightPadControlsHelpViewController new];
    __weak NightPadShellViewController *weakSelf = self;
    help.onClose = ^{ [weakSelf endNativeUI]; };
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:help];
    navigation.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentAfterMenu:navigation];
}

- (void)installTouchControls {
    if (_touchControls != nil)
        return;
    _touchControls = [[NightPadTouchControlsView alloc] initWithFrame:self.view.bounds];
    _touchControls.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_touchControls setTouchLayout:[self loadTouchLayout]];
    [self.view insertSubview:_touchControls belowSubview:_menuButton];
    _gameInput = [[NightPadGameInput alloc] initWithEngineHost:_engineHost touchView:_touchControls];
    [_gameInput.controllers setRumbleAllowed:_settings.rumble];
    __weak NightPadShellViewController *weakSelf = self;
    _gameInput.controllerConnectionChanged = ^{
        [weakSelf updateTouchControlsVisibility];
        [weakSelf refreshMenu];
    };
    [_gameInput start];
    [self updateTouchControlsVisibility];
}

- (void)removeTouchControls {
    [_gameInput stop];
    _gameInput = nil;
    [_touchControls removeFromSuperview];
    _touchControls = nil;
}

- (void)updateTouchControlsVisibility {
    if (_touchControls == nil)
        return;
    const BOOL hide = nightpad::ShouldHideTouchControls(_gameInput.touchPlayerControllerPresent,
                                                       _settings.touchControlsAlwaysVisible,
                                                       _settings.hideTouchControlsWithController);
    [_touchControls setControlsHidden:hide animated:YES];
}

- (void)saveSettings {
    std::string error;
    if (!_settings.Save(_paths.appSupport / "settings.txt", &error))
        [self showError:[NSString stringWithFormat:@"Settings were not saved: %s", error.c_str()]];
}

- (void)toggleTouchControls {
    _settings.touchControlsAlwaysVisible = !_settings.touchControlsAlwaysVisible;
    if (_settings.touchControlsAlwaysVisible)
        [_touchControls setControlsHidden:NO animated:YES];
    else
        [self updateTouchControlsVisibility];
    [self saveSettings];
    [self refreshMenu];
}

- (void)toggleAutoHideTouch {
    _settings.hideTouchControlsWithController = !_settings.hideTouchControlsWithController;
    [self updateTouchControlsVisibility];
    [self saveSettings];
    [self refreshMenu];
}

- (void)toggleRumble {
    _settings.rumble = !_settings.rumble;
    [_gameInput.controllers setRumbleAllowed:_settings.rumble];
    [self saveSettings];
    [self refreshMenu];
}

- (void)setRenderScale:(int)scale {
    if (scale < 1 || scale > 4)
        return;
    _settings.renderScale = scale;
    [self saveSettings];
    [self refreshMenu];
    if (_engineRunning)
        [self showInfo:@"Display change queued" detail:@"The new render size applies at the next Start."];
}

- (void)setAntiAliasing:(BOOL)enabled {
    _settings.antiAliasing = enabled;
    [self saveSettings];
    [self refreshMenu];
    if (_engineRunning)
        [self showInfo:@"Display change queued" detail:@"Anti-aliasing applies at the next Start."];
}

- (void)setWidescreen:(BOOL)enabled {
    _settings.widescreen = enabled;
    [self saveSettings];
    [self refreshMenu];
    if (_engineRunning)
        [self showInfo:@"Display change queued" detail:@"Widescreen applies at the next Start."];
}

- (void)toggleImmortal {
    _settings.assistImmortal = !_settings.assistImmortal;
    [_engineHost setImmortal:_settings.assistImmortal];
    [self saveSettings];
    [self refreshMenu];
}

- (void)setFov:(int)fov {
    if (fov < 30 || fov > 120)
        return;
    _settings.fov = fov;
    [self saveSettings];
    [self refreshMenu];
    if (_engineRunning)
        [self showInfo:@"Display change queued" detail:@"Field of view applies at the next Start."];
}

- (void)toggleUnlimitedAmmo {
    _settings.assistUnlimitedAmmo = !_settings.assistUnlimitedAmmo;
    [_engineHost setUnlimitedAmmo:_settings.assistUnlimitedAmmo];
    [self saveSettings];
    [self refreshMenu];
}

- (void)beginNativeUI {
    _nativeSurfaceVisible = YES;
    [self reconcileNativeUI];
}

- (void)endNativeUI {
    _nativeSurfaceVisible = NO;
    [self reconcileNativeUI];
}

- (void)reconcileNativeUI {
    const BOOL surface = _nativeSurfaceVisible || (_dataPanel != nil && !_dataPanel.hidden) ||
                         (_pausePanel != nil && !_pausePanel.hidden);
    const BOOL hold = nightpad::ShouldHoldForNativeUI(
        {_engineRunning != NO, _nativeMenuVisible != NO, surface != NO,
         _applicationActive != NO, _alertPauseCount});
    // Neutralize first, before either pausing or releasing the game thread.
    [_gameInput setSuspended:hold];
    if (_uiInputSuspended != hold) {
        if (hold) [_touchControls releaseAllTouches];
        [_engineHost setInputSuspended:hold];
        _uiInputSuspended = hold;
    }
    if (_uiPausedEngine != hold) {
        [_engineHost setPaused:hold];
        _enginePaused = hold;
        _uiPausedEngine = hold;
        [self logSessionEvent:hold ? @"native UI pause" : @"native UI resume"];
    }
    if (_traceNativeUI)
        NSLog(@"[NightPad UI] hold=%d menu=%d surface=%d alerts=%u active=%d frames=%lu",
              hold, _nativeMenuVisible, surface, _alertPauseCount,
              _applicationActive, [_engineHost frameCount]);
}

- (void)startGame {
    if (_engineRunning) {
        [self stopGame];
        return;
    }
    if (![NightPadEngineHost isLinked]) {
        [self showInfo:@"Engine not linked" detail:@"Build the device shell to include the combined engine archive."];
        return;
    }
    if (_state != DataState::Ready || _identity.length == 0) {
        [self showInfo:@"Game data required" detail:@"Import a validated prepared game-data folder first."];
        return;
    }
    NSString *gameData = [NSString stringWithUTF8String:_paths.GameDataFor(_identity.UTF8String).c_str()];
    NSString *launchState = [NSString stringWithUTF8String:_paths.launchState.c_str()];
    NSString *error = nil;
    _engineHost.renderWidth = 640 * _settings.renderScale;
    _engineHost.renderHeight = 480 * _settings.renderScale;
    _engineHost.antiAliasing = _settings.antiAliasing;
    _engineHost.widescreen = _settings.widescreen;
    _engineHost.fov = _settings.fov;
    if (![_engineHost prepareWithGameData:gameData launchState:launchState error:&error] ||
        ![_engineHost startAction]) {
        [self showError:error.length ? error : @"The engine could not start."];
        return;
    }
    [_engineHost setImmortal:_settings.assistImmortal];
    [_engineHost setUnlimitedAmmo:_settings.assistUnlimitedAmmo];
    [self closePanels];
    [self endNativeUI];
    _stopWhenBooted = NO;
    _engineRunning = YES;
    [self logSessionEvent:@"engine start action"];
    _enginePaused = NO;
    [self reconcileNativeUI];
    _gameplayMode = YES;
    [self installTouchControls];
    [self reconcileNativeUI];
    [self updateGameplaySurface];
    [self refreshMenu];
    _engineTimer = [NSTimer timerWithTimeInterval:1.0 / 60.0 target:self selector:@selector(pollEngine) userInfo:nil repeats:YES];
    [NSRunLoop.mainRunLoop addTimer:_engineTimer forMode:NSRunLoopCommonModes];
    _importButton.enabled = NO;
    [self refreshMenu];
}

- (void)pollEngine {
    if (_traceNativeUI && _uiPausedEngine && CFAbsoluteTimeGetCurrent() - _lastUiTrace >= 2.0) {
        _lastUiTrace = CFAbsoluteTimeGetCurrent();
        unsigned long movieFrames = 0;
        int moviePaused = 0;
        BOOL movie = [_engineHost blockingMovieFrames:&movieFrames paused:&moviePaused];
        NSLog(@"[NightPad UI] held frames=%lu movie=%d movie-frames=%lu movie-paused=%d",
              [_engineHost frameCount], movie, movieFrames, moviePaused);
    }
    // A stopping engine can still need the window's main thread to pump SDL
    // events and finish a present callback. Keep that path alive until join.
    if (_engineTeardown) {
        (void)[_engineHost pollWindow];
        return;
    }
    if (!_engineRunning || _switchingEngine)
        return;
    if (_stopWhenBooted) {
        const NSTimeInterval waited = CFAbsoluteTimeGetCurrent() - _stopQueuedAt;
        if ([_engineHost frameCount] > 0 || [_engineHost blockingMovieFrames:nullptr paused:nullptr] || waited > 180) {
            _stopWhenBooted = NO;
            _forceStopNow = waited > 180;
            [self stopGame];
            return;
        }
    }
    if ([_engineHost pollWindow])
        return;
    if ([_engineHost handoffPending]) {
        [self logSessionEvent:@"handoff requested"];
        [self switchEngine];
        return;
    }
    [self stopGame];
}

- (void)switchEngine {
    if (_switchingEngine)
        return;
    _switchingEngine = YES;
    _engineTeardown = YES;
    __weak NightPadShellViewController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NightPadShellViewController *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        const int joined = [strongSelf->_engineHost joinWithTimeout:60000];
        dispatch_async(dispatch_get_main_queue(), ^{
            NightPadShellViewController *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            if (!joined) {
                strongSelf->_switchingEngine = NO;
                [strongSelf showError:@"The game did not stop for the next session."];
                return;
            }
            [strongSelf->_engineTimer invalidate];
            strongSelf->_engineTimer = nil;
            // While a game runs the shell window sits above it at UIWindowLevelNormal + 2. A new SDL window
            // opened under that window never becomes key or loads its view, which is the black surface a
            // handoff could show. Drop to the normal level while the next engine opens its window;
            // updateGameplaySurface raises the shell above it again once the target is running.
            strongSelf.view.window.windowLevel = UIWindowLevelNormal;
            [strongSelf->_engineHost closeWindow];
            // The old window's UIWindow is torn down asynchronously. Building the next SDL window in this same
            // runloop turn could leave its view controller without a loaded view (a black surface with the
            // engine still presenting), so let UIKit finish one turn first.
            dispatch_async(dispatch_get_main_queue(), ^{
                NightPadShellViewController *startSelf = weakSelf;
                if (startSelf == nil)
                    return;
                if (![startSelf->_engineHost startHandoffTarget]) {
                    startSelf->_switchingEngine = NO;
                    startSelf->_engineTeardown = NO;
                    [startSelf showError:@"The next game session could not start."];
                    [startSelf stopGame];
                    return;
                }
                startSelf->_enginePaused = NO;
                startSelf->_uiPausedEngine = NO;
                startSelf->_uiInputSuspended = NO;
                [startSelf->_gameInput engineChanged];
                [startSelf reconcileNativeUI];
                [startSelf logSessionEvent:(startSelf->_engineHost.activeEngine == NightPadEngineKindDriving
                                               ? @"engine switched to driving"
                                               : @"engine switched to action")];
                if (startSelf->_engineHost.activeEngine == NightPadEngineKindAction) {
                    [startSelf->_engineHost setImmortal:startSelf->_settings.assistImmortal];
                    [startSelf->_engineHost setUnlimitedAmmo:startSelf->_settings.assistUnlimitedAmmo];
                }
                startSelf->_switchingEngine = NO;
                startSelf->_engineTeardown = NO;
                startSelf->_engineTimer = [NSTimer timerWithTimeInterval:1.0 / 60.0
                                                                 target:startSelf
                                                               selector:@selector(pollEngine)
                                                               userInfo:nil
                                                                repeats:YES];
                [NSRunLoop.mainRunLoop addTimer:startSelf->_engineTimer forMode:NSRunLoopCommonModes];
                [startSelf updateGameplaySurface];
                [startSelf refreshMenu];
            });
        });
    });
}

- (void)stopGame {
    if (!_engineRunning) return;
    if (_switchingEngine) return;
    if (!_forceStopNow && [_engineHost frameCount] == 0 &&
        ![_engineHost blockingMovieFrames:nullptr paused:nullptr]) {
        // Cleanup before the game reaches its loop can tear down half-built
        // state. Hold the request until the first frame (or a long timeout).
        if (!_stopWhenBooted) {
            _stopWhenBooted = YES;
            _stopQueuedAt = CFAbsoluteTimeGetCurrent();
            [self refreshMenu];
        }
        return;
    }
    _stopWhenBooted = NO;
    _forceStopNow = NO;
    [self logSessionEvent:@"engine stop requested"];
    _engineRunning = NO;
    _engineTeardown = YES;
    [_engineHost requestStop];
    [self endNativeUI];
    [self removeTouchControls];
    __weak NightPadShellViewController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NightPadShellViewController *strongSelf = weakSelf;
        if (strongSelf == nil) return;
        int joined = [strongSelf->_engineHost joinWithTimeout:60000];
        dispatch_async(dispatch_get_main_queue(), ^{
            NightPadShellViewController *strongSelf = weakSelf;
            if (strongSelf == nil) return;
            if (!joined) {
                [strongSelf logSessionEvent:@"engine stop timed out"];
                [strongSelf showError:@"The engine is taking longer than expected to stop."];
                return;
            }
            [strongSelf->_engineTimer invalidate];
            strongSelf->_engineTimer = nil;
            strongSelf->_engineTeardown = NO;
            [strongSelf->_engineHost closeWindow];
            [strongSelf logSessionEvent:@"engine stopped"];
            strongSelf->_gameplayMode = NO;
            [strongSelf updateGameplaySurface];
            [strongSelf refreshDataState];
        });
    });
}

- (void)updateGameplaySurface {
    self.view.backgroundColor = _gameplayMode ? UIColor.clearColor : UIColor.blackColor;
    _title.hidden = _gameplayMode;
    _status.hidden = _gameplayMode;
    _menuButton.hidden = NO;
    if (self.view.window != nil)
        self.view.window.windowLevel = _gameplayMode ? UIWindowLevelNormal + 2 : UIWindowLevelNormal;
    [self.view bringSubviewToFront:_menuButton];
}

- (void)refreshDataState {
    if (!_importer)
        _importer = std::make_unique<GameDataImporter>(_paths);
    std::string identity, error;
    _state = _importer->CurrentState(&identity, &error);
    _identity = identity.empty() ? nil : [NSString stringWithUTF8String:identity.c_str()];
    _importButton.enabled = !_engineRunning && !_importing;
    [self refreshMenu];
    if (_state == DataState::Ready)
        _status.text = [NSString stringWithFormat:@"Game data ready\n%@", _identity];
    else if (_state == DataState::RecoverableError)
        _status.text = [NSString stringWithFormat:@"Game data needs attention: %s", error.c_str()];
    else
        _status.text = @"Game data missing\nOpen the three-dot menu to import a prepared game-data folder.";
    if (_state == DataState::Ready)
        _dataStatus.text = [NSString stringWithFormat:@"Ready · %@", _identity];
    else if (_state == DataState::RecoverableError)
        _dataStatus.text = @"Needs attention";
    else
        _dataStatus.text = @"No game data imported";
    _discardButton.enabled = _importer->previousDataRetained();
    _progress.hidden = !_importing;
    _progressLabel.hidden = !_importing;
    _cancelImportButton.hidden = !_importing;
}

- (void)chooseImportFolder {
    if (_importing) return;
    if (_engineRunning) {
        [self showInfo:@"Stop the game first" detail:@"Game data can only change while the engine is stopped."];
        return;
    }
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc]
        initForOpeningContentTypes:@[UTTypeFolder] asCopy:NO];
    picker.delegate = self;
    picker.allowsMultipleSelection = NO;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    (void)controller;
    if (_pickingSaveFiles) {
        _pickingSaveFiles = NO;
        [self restoreSaves:urls];
        return;
    }
    NSURL *url = urls.firstObject;
    if (url == nil) return;
    [self openDataPanel];
    [self importPreparedFolder:url];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    (void)controller;
    _pickingSaveFiles = NO;
}

- (void)chooseSaveFiles {
    if (_engineRunning) {
        [self showInfo:@"Stop the game first" detail:@"Saves can only be restored while the engine is stopped."];
        return;
    }
    _pickingSaveFiles = YES;
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc]
        initForOpeningContentTypes:@[ UTTypeData ] asCopy:NO];
    picker.delegate = self;
    picker.allowsMultipleSelection = YES;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)restoreSavesFromFixture {
    [self restoreSavesFromFolderNamed:@"SaveFixture" promptTitle:@"No save fixture"
                                detail:@"Put save files in Documents/SaveFixture to test restore."];
}

// Saves copied into a folder in Documents can be restored with one tap, the
// same way game data is imported without the picker.
- (void)restoreSavesFromAppFolder {
    [self restoreSavesFromFolderNamed:@"Save Import" promptTitle:@"No save folder"
                                detail:@"Copy save files into NightPad's Documents/Save Import in Files, then choose this again."];
}

- (void)restoreSavesFromFolderNamed:(NSString *)name promptTitle:(NSString *)title detail:(NSString *)detail {
    if (_engineRunning) {
        [self showInfo:@"Stop the game first" detail:@"Saves can only be restored while the engine is stopped."];
        return;
    }
    // The document picker's remote UI is not scriptable, so the save-restore
    // path can also take its inputs from a folder in Documents.
    NSString *documents = [NSString stringWithUTF8String:_paths.documents.string().c_str()];
    NSURL *folder = [[NSURL fileURLWithPath:documents isDirectory:YES]
        URLByAppendingPathComponent:name isDirectory:YES];
    NSArray<NSString *> *names = [NSFileManager.defaultManager contentsOfDirectoryAtPath:folder.path error:nil];
    NSMutableArray<NSURL *> *urls = [NSMutableArray array];
    for (NSString *file in names) {
        if ([file hasPrefix:@"."])
            continue;
        [urls addObject:[folder URLByAppendingPathComponent:file]];
    }
    if (urls.count == 0) {
        [self showInfo:title detail:detail];
        return;
    }
    [self restoreSaves:urls];
}

- (void)restoreSaves:(NSArray<NSURL *> *)urls {
    if (urls.count == 0)
        return;
    NSString *directory = [NSString stringWithUTF8String:_paths.saves.c_str()];
    NSMutableArray<NSString *> *collisions = [NSMutableArray array];
    for (NSURL *url in urls) {
        NSString *destination = [directory stringByAppendingPathComponent:url.lastPathComponent];
        if ([NSFileManager.defaultManager fileExistsAtPath:destination])
            [collisions addObject:url.lastPathComponent];
    }
    if (collisions.count == 0) {
        [self copySaves:urls];
        return;
    }
    __weak NightPadShellViewController *weakSelf = self;
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Replace existing saves?"
                         message:[NSString stringWithFormat:@"%lu save%@ already exist%@. Importing will replace %@.",
                                                            (unsigned long)collisions.count,
                                                            collisions.count == 1 ? @"" : @"s",
                                                            collisions.count == 1 ? @"s" : @"",
                                                            collisions.count == 1 ? @"it" : @"them"]
                  preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Replace" style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
        (void)action;
        [weakSelf copySaves:urls];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)copySaves:(NSArray<NSURL *> *)urls {
    NSString *directory = [NSString stringWithUTF8String:_paths.saves.c_str()];
    [NSFileManager.defaultManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    NSError *error = nil;
    NSUInteger copied = 0;
    for (NSURL *url in urls) {
        const BOOL scoped = [url startAccessingSecurityScopedResource];
        NSString *destination = [directory stringByAppendingPathComponent:url.lastPathComponent];
        // Atomic, so an interrupted restore leaves the previous save intact
        // rather than a deleted or half-written slot.
        NSData *contents = [NSData dataWithContentsOfURL:url options:0 error:&error];
        if (contents != nil && [contents writeToFile:destination options:NSDataWritingAtomic error:&error])
            ++copied;
        if (scoped)
            [url stopAccessingSecurityScopedResource];
    }
    if (copied == 0) {
        [self showError:error.localizedDescription ?: @"The saves could not be imported."];
        return;
    }
    [self logSessionEvent:@"saves imported"];
    [self showInfo:@"Saves imported"
           detail:[NSString stringWithFormat:@"%lu file%@ restored to Saves.", (unsigned long)copied,
                                             copied == 1 ? @"" : @"s"]];
}

- (void)importFromAppFolder {
    // The folder picker's remote UI cannot be scripted, and copying a prepared
    // tree through Files and then re-picking it is clumsy on a tablet. A folder
    // inside the app's Documents can be imported with one tap, like SunPad's
    // "Import from SunPad Folder".
    NSString *documents = [NSString stringWithUTF8String:_paths.documents.string().c_str()];
    NSURL *folder = [[NSURL fileURLWithPath:documents isDirectory:YES]
        URLByAppendingPathComponent:@"NightPad Import" isDirectory:YES];
    BOOL isDirectory = NO;
    if (![NSFileManager.defaultManager fileExistsAtPath:folder.path isDirectory:&isDirectory] || !isDirectory) {
        [self showInfo:@"No import folder"
                 detail:@"Copy a prepared game-data folder named \"NightPad Import\" into NightPad's Documents "
                        @"in Files, then choose this again."];
        return;
    }
    // The progress bar lives in the data panel; an import started from the menu
    // must show it.
    [self openDataPanel];
    [self importPreparedFolder:folder];
}

- (void)importPreparedFolder:(NSURL *)url {
    BOOL scoped = [url startAccessingSecurityScopedResource];
    _importing = YES;
    _progress.hidden = NO;
    _progressLabel.hidden = NO;
    _cancelImportButton.hidden = NO;
    _progress.progress = 0;
    _progressLabel.text = @"Preparing import…";
    _importButton.enabled = NO;
    __weak NightPadShellViewController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NightPadShellViewController *strongSelf = weakSelf;
        if (strongSelf == nil) return;
        std::string error;
        const bool prepared = strongSelf->_importer->Prepare(url.fileSystemRepresentation, [weakSelf](const char *status, double fraction) {
            NSString *text = [NSString stringWithUTF8String:status];
            dispatch_async(dispatch_get_main_queue(), ^{
                NightPadShellViewController *strongSelf = weakSelf;
                if (strongSelf == nil) return;
                strongSelf->_progress.progress = fraction;
                strongSelf->_progressLabel.text = text;
            });
        }, &error);
        if (scoped) [url stopAccessingSecurityScopedResource];
        dispatch_async(dispatch_get_main_queue(), ^{
            NightPadShellViewController *strongSelf = weakSelf;
            if (strongSelf == nil) return;
            strongSelf->_importing = NO;
            strongSelf->_importButton.enabled = YES;
            strongSelf->_progress.hidden = YES;
            strongSelf->_progressLabel.hidden = YES;
            if (!prepared) {
                NSString *message = error.empty() ? @"Import failed." : [NSString stringWithUTF8String:error.c_str()];
                if ([message isEqualToString:@"Import cancelled."]) {
                    [strongSelf logSessionEvent:@"import cancelled"];
                    [strongSelf showInfo:@"Import cancelled" detail:@"No game data was changed."];
                    [strongSelf refreshDataState];
                    return;
                }
                [strongSelf showError:message];
                [strongSelf refreshDataState];
                return;
            }
            std::string activationError;
            if (!strongSelf->_importer->Activate(true, &activationError)) {
                NSString *message = activationError.empty() ? @"Activation failed; previous data is unchanged."
                                                            : [NSString stringWithUTF8String:activationError.c_str()];
                [strongSelf showError:message];
                [strongSelf refreshDataState];
                return;
            }
            [strongSelf refreshDataState];
            strongSelf->_discardButton.enabled = strongSelf->_importer->previousDataRetained();
            [strongSelf showInfo:@"Game data imported" detail:@"The previous saves remain untouched."];
            [strongSelf logSessionEvent:@"game data imported"];
        });
    });
}

- (void)cancelImport {
    if (_importing && _importer)
        _importer->Cancel();
}

- (void)discardPrevious {
    std::string error;
    if (_importer && _importer->DiscardStage(&error)) {
        _discardButton.enabled = NO;
        [self refreshDataState];
    } else {
        [self showError:error.empty() ? @"Previous data could not be removed." : [NSString stringWithUTF8String:error.c_str()]];
    }
}

- (void)shareSaves {
    NSString *directory = [NSString stringWithUTF8String:_paths.saves.c_str()];
    NSArray<NSString *> *names = [NSFileManager.defaultManager contentsOfDirectoryAtPath:directory error:nil];
    NSMutableArray<NSURL *> *urls = [NSMutableArray array];
    for (NSString *name in names) {
        if ([name hasPrefix:@"."])
            continue;
        NSString *path = [directory stringByAppendingPathComponent:name];
        BOOL isDirectory = NO;
        if ([NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDirectory] && !isDirectory)
            [urls addObject:[NSURL fileURLWithPath:path]];
    }
    if (urls.count == 0) {
        [self showInfo:@"No saves yet" detail:@"Saves appear here after the game writes one."];
        return;
    }
    [self beginNativeUI];
    __weak NightPadShellViewController *weakSelf = self;
    UIActivityViewController *share = [[UIActivityViewController alloc] initWithActivityItems:urls
                                                                      applicationActivities:nil];
    share.completionWithItemsHandler = ^(UIActivityType type, BOOL completed, NSArray *items, NSError *error) {
        (void)type;
        (void)completed;
        (void)items;
        (void)error;
        [weakSelf endNativeUI];
    };
    UIPopoverPresentationController *popover = share.popoverPresentationController;
    popover.sourceView = _menuButton;
    popover.sourceRect = _menuButton.bounds;
    [self presentAfterMenu:share];
    [self logSessionEvent:@"saves shared"];
}

- (void)openDiagnostics {
    [self beginNativeUI];
    [self closePanels];
    const char *state = "Missing";
    switch (_state) {
        case DataState::Ready: state = "Ready"; break;
        case DataState::RecoverableError: state = "RecoverableError"; break;
        case DataState::Invalid: state = "Invalid"; break;
        case DataState::Importing: state = "Importing"; break;
        case DataState::Launching: state = "Launching"; break;
        case DataState::Running: state = "Running"; break;
        case DataState::Missing: state = "Missing"; break;
    }
    nightpad::DiagnosticContext context;
    context.appVersion = [[NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] UTF8String] ?: "";
    context.buildConfiguration =
#if DEBUG
        "diagnostic/debug";
#else
        "performance/release";
#endif
    NSISO8601DateFormatter *iso = [NSISO8601DateFormatter new];
    context.generatedAt = [[iso stringFromDate:[NSDate date]] UTF8String] ?: "";
    context.dataState = state;
    context.dataIdentity = _identity.UTF8String ?: "";
    context.engineState = !_engineRunning ? "stopped"
        : (_enginePaused ? "paused"
        : (_engineHost.activeEngine == NightPadEngineKindDriving ? "running (driving)" : "running (action)"));
    context.lastError = _lastError.UTF8String ?: "";
    for (NSString *event in _sessionLog)
        context.sessionEvents.push_back(event.UTF8String ?: "");
    context.renderSize = [[NSString stringWithFormat:@"%dx%d", 640 * _settings.renderScale,
                                    480 * _settings.renderScale] UTF8String];
    context.displayOptions = [[NSString stringWithFormat:@"aa=%@ widescreen=%@",
                                        _settings.antiAliasing ? @"on" : @"off",
                                        _settings.widescreen ? @"on" : @"off"] UTF8String];
    context.assists = [[NSString stringWithFormat:@"immortality=%@ unlimited_ammo=%@",
                                                 _settings.assistImmortal ? @"on" : @"off",
                                                 _settings.assistUnlimitedAmmo ? @"on" : @"off"] UTF8String];
    context.home = NSHomeDirectory().UTF8String ?: "";
    context.paths = _paths;
    context.threadCount = ShellThreadCount();
    context.residentBytes = ShellResidentBytes();
    const std::string report = nightpad::BuildDiagnosticReport(context);
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyyMMdd-HHmmss";
    NSString *name = [NSString stringWithFormat:@"NightPad-diagnostics-%@.txt", [formatter stringFromDate:NSDate.date]];
    NSString *directory = [NSString stringWithUTF8String:_paths.diagnostics.c_str()];
    [NSFileManager.defaultManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *path = [directory stringByAppendingPathComponent:name];
    NSError *writeError = nil;
    NSString *text = [NSString stringWithUTF8String:report.c_str()];
    if (![text writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&writeError]) {
        [self endNativeUI];
        [self showError:writeError.localizedDescription ?: @"The local diagnostic report could not be saved."];
        return;
    }
    NightPadDiagnosticsViewController *review = [[NightPadDiagnosticsViewController alloc]
        initWithReport:text reportURL:[NSURL fileURLWithPath:path]];
    __weak NightPadShellViewController *weakSelf = self;
    review.onClose = ^{ [weakSelf endNativeUI]; };
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:review];
    navigation.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentAfterMenu:navigation];
}

- (void)showError:(NSString *)message {
    _lastError = [message copy];
    [self logSessionEvent:@"error shown"];
    __weak NightPadShellViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        NightPadShellViewController *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        [strongSelf showInfo:@"NightPad" detail:message];
    });
}

- (void)logSessionEvent:(NSString *)event {
    if (_sessionLog == nil)
        _sessionLog = [NSMutableArray array];
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"HH:mm:ss";
    [_sessionLog addObject:[NSString stringWithFormat:@"%@ %@", [formatter stringFromDate:NSDate.date], event]];
    while (_sessionLog.count > 40)
        [_sessionLog removeObjectAtIndex:0];
}

- (void)showInfo:(NSString *)title detail:(NSString *)detail {
    ++_alertPauseCount;
    [self reconcileNativeUI];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
        message:detail preferredStyle:UIAlertControllerStyleAlert];
    __weak NightPadShellViewController *weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(__kindof UIAlertAction *action) {
        (void)action;
        NightPadShellViewController *owner = weakSelf;
        if (owner == nil) return;
        if (owner->_alertPauseCount != 0) --owner->_alertPauseCount;
        [owner reconcileNativeUI];
    }]];
    [self presentAfterMenu:alert];
}

@end
