#import "NightPadShellViewController.h"
#import "NightPadEngineHost.h"
#import "NightPadDiagnosticsViewController.h"
#import "NightPadAboutViewController.h"
#import "NightPadTouchLayoutViewController.h"
#import "NightPadControlsHelpViewController.h"
#import "NightPadGameInput.h"
#import "NightPadTouchControlsView.h"

#include "../shared/NightPadGameDataImport.h"
#include "../shared/NightPadDiagnostics.h"
#include "../shared/NightPadSettings.h"
#include "../shared/NightPadTouchLayout.h"

#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#include <mach/mach.h>
#include <mach/task_info.h>
#include <memory>

using nightpad::DataState;
using nightpad::GameDataImporter;
using nightpad::Paths;

@interface NightPadMenuButton : UIButton
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
- (CGRect)imageRectForContentRect:(CGRect)contentRect {
    return CGRectInset(contentRect, 12, 12);
}
@end

@interface NightPadShellViewController () <UIDocumentPickerDelegate>
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
    BOOL _stopWhenBooted;
    BOOL _forceStopNow;
    NSTimeInterval _stopQueuedAt;
    BOOL _uiPausedEngine;
    BOOL _uiInputSuspended;
    BOOL _pendingDiagnostics;
    BOOL _pendingAbout;
    BOOL _pendingFixtureImport;
    BOOL _pendingTouchLayout;
    BOOL _pendingControlsHelp;
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
    UIButton *_importButton;
    UIButton *_discardButton;
    NightPadTouchControlsView *_touchControls;
    NightPadGameInput *_gameInput;
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowBecameKey:)
        name:UIWindowDidBecomeKeyNotification object:nil];

    _title = [UILabel new];
    _title.text = @"NIGHTPAD";
    _title.textColor = UIColor.whiteColor;
    _title.font = [UIFont monospacedSystemFontOfSize:30 weight:UIFontWeightBold];
    _title.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_title];

    _status = [UILabel new];
    _status.textColor = [UIColor colorWithWhite:1 alpha:0.78];
    _status.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _status.numberOfLines = 0;
    _status.textAlignment = NSTextAlignmentCenter;
    _status.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_status];

    _menuButton = [NightPadMenuButton buttonWithType:UIButtonTypeCustom];
    [_menuButton setImage:[UIImage systemImageNamed:@"ellipsis"] forState:UIControlStateNormal];
    _menuButton.tintColor = UIColor.whiteColor;
    _menuButton.backgroundColor = [UIColor colorWithWhite:0.06 alpha:0.76];
    _menuButton.layer.cornerRadius = 22;
    _menuButton.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.32].CGColor;
    _menuButton.layer.borderWidth = 1;
    _menuButton.accessibilityLabel = @"Menu";
    _menuButton.accessibilityIdentifier = @"nightpad.menu";
    _menuButton.showsMenuAsPrimaryAction = YES;
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
        [_menuButton.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-18],
        [_menuButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:18],
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

- (void)refreshMenu {
    if (_menuButton == nil)
        return;
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
    UIMenu *game = [UIMenu menuWithTitle:@"Game"
                                   image:[UIImage systemImageNamed:@"gamecontroller"]
                               identifier:nil
                                  options:0
                                 children:@[ start, pause ]];

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
    UIMenu *controls = [UIMenu menuWithTitle:@"Controls"
                                       image:[UIImage systemImageNamed:@"hand.draw"]
                                  identifier:nil
                                     options:0
                                    children:@[ layout, help, show, autoHide, rumble, controllerStatus ]];

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

    UIMenu *display = [UIMenu menuWithTitle:@"Display"
                                      image:[UIImage systemImageNamed:@"display"]
                                 identifier:nil
                                    options:0
                                   children:@[ resolution, antiAliasing, aspect ]];

    UIAction *immortal = [self menuAction:@"Immortality" image:@"heart.fill" disabled:NO
                                  handler:^{ [weakSelf toggleImmortal]; }];
    immortal.state = _settings.assistImmortal ? UIMenuElementStateOn : UIMenuElementStateOff;
    UIAction *ammo = [self menuAction:@"Unlimited Ammo" image:@"infinity" disabled:NO
                               handler:^{ [weakSelf toggleUnlimitedAmmo]; }];
    ammo.state = _settings.assistUnlimitedAmmo ? UIMenuElementStateOn : UIMenuElementStateOff;
    UIAction *assistNote = [self menuAction:@"Action missions only; excluded from acceptance runs"
                                      image:nil disabled:YES handler:nil];
    UIMenu *assists = [UIMenu menuWithTitle:@"Assists"
                                      image:[UIImage systemImageNamed:@"shield.lefthalf.filled"]
                                 identifier:nil
                                    options:0
                                   children:@[ immortal, ammo, assistNote ]];

    UIAction *data = [self menuAction:@"Game Data & Saves" image:@"internaldrive" disabled:NO
                               handler:^{ [weakSelf openDataPanel]; }];
    UIAction *importAction = [self menuAction:@"Import Prepared Game Data…" image:@"folder" disabled:_engineRunning
                                      handler:^{ [weakSelf chooseImportFolder]; }];
    UIAction *removeAction = [self menuAction:@"Remove Previous Game Data" image:@"trash"
                                     disabled:!(_importer && _importer->previousDataRetained())
                                      handler:^{ [weakSelf discardPrevious]; }];
    UIMenu *dataMenu = [UIMenu menuWithTitle:@"Game Data & Saves"
                                       image:[UIImage systemImageNamed:@"internaldrive"]
                                  identifier:nil
                                     options:0
                                    children:@[ data, importAction, removeAction ]];

    UIAction *about = [self menuAction:@"About NightPad" image:@"info.circle" disabled:NO
                                handler:^{ [weakSelf openAbout]; }];
    UIAction *diagnostics = [self menuAction:@"Diagnostics" image:@"doc.text.magnifyingglass" disabled:NO
                                     handler:^{ [weakSelf openDiagnostics]; }];
    UIMenu *info = [UIMenu menuWithTitle:@"Info"
                                   image:[UIImage systemImageNamed:@"info.circle"]
                              identifier:nil
                                 options:0
                                children:@[ about, diagnostics ]];

    return [UIMenu menuWithTitle:@"NightPad" children:@[ game, controls, display, assists, dataMenu, info ]];
}

- (void)buildDataPanel {
    _dataPanel = [self cardWithFrame:CGRectZero];
    [self.view addSubview:_dataPanel];
    UILabel *heading = [UILabel new];
    heading.text = @"Game Data & Saves";
    heading.textColor = UIColor.whiteColor;
    heading.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    heading.translatesAutoresizingMaskIntoConstraints = NO;
    [_dataPanel addSubview:heading];

    UILabel *detail = [UILabel new];
    detail.text = @"Import a prepared NightPad game-data folder. Saves are stored separately and are not changed.";
    detail.textColor = [UIColor colorWithWhite:1 alpha:0.72];
    detail.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    detail.numberOfLines = 0;
    detail.translatesAutoresizingMaskIntoConstraints = NO;
    [_dataPanel addSubview:detail];

    _importButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButtonConfiguration *import = [UIButtonConfiguration filledButtonConfiguration];
    import.title = @"Import Prepared Game Data…";
    import.image = [UIImage systemImageNamed:@"folder"];
    import.imagePadding = 8;
    _importButton.configuration = import;
    _importButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_importButton addTarget:self action:@selector(chooseImportFolder) forControlEvents:UIControlEventTouchUpInside];
    [_dataPanel addSubview:_importButton];

    _discardButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButtonConfiguration *discard = [UIButtonConfiguration tintedButtonConfiguration];
    discard.title = @"Remove Previous Game Data";
    _discardButton.configuration = discard;
    _discardButton.translatesAutoresizingMaskIntoConstraints = NO;
    _discardButton.enabled = NO;
    [_discardButton addTarget:self action:@selector(discardPrevious) forControlEvents:UIControlEventTouchUpInside];
    [_dataPanel addSubview:_discardButton];

    _progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _progress.translatesAutoresizingMaskIntoConstraints = NO;
    _progress.hidden = YES;
    [_dataPanel addSubview:_progress];
    _progressLabel = [UILabel new];
    _progressLabel.textColor = [UIColor colorWithWhite:1 alpha:0.78];
    _progressLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    _progressLabel.numberOfLines = 2;
    _progressLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_dataPanel addSubview:_progressLabel];

    UIButton *cancel = [self panelButton:@"Cancel Import" action:@selector(cancelImport)];
    cancel.translatesAutoresizingMaskIntoConstraints = NO;
    [_dataPanel addSubview:cancel];
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
        [_importButton.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [_importButton.topAnchor constraintEqualToAnchor:detail.bottomAnchor constant:16],
        [_discardButton.leadingAnchor constraintEqualToAnchor:_importButton.trailingAnchor constant:12],
        [_discardButton.centerYAnchor constraintEqualToAnchor:_importButton.centerYAnchor],
        [_progress.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [_progress.trailingAnchor constraintEqualToAnchor:detail.trailingAnchor],
        [_progress.topAnchor constraintEqualToAnchor:_importButton.bottomAnchor constant:16],
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
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [_pausePanel addSubview:label];
    UILabel *detail = [UILabel new];
    detail.text = @"The engine is held at a native pause boundary. Original Xbox Start pause remains separate.";
    detail.textColor = [UIColor colorWithWhite:1 alpha:0.72];
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
}

- (void)openDataPanel {
    [self beginNativeUI];
    [self closePanels];
    _dataPanel.hidden = NO;
    [self.view bringSubviewToFront:_dataPanel];
}

- (void)showPausePanel {
    [self beginNativeUI];
    [self closePanels];
    _pausePanel.hidden = NO;
    [self.view bringSubviewToFront:_pausePanel];
}

- (void)resumeFromPause {
    [self endNativeUI];
    [self closePanels];
}

- (void)openAbout {
    [self beginNativeUI];
    [self closePanels];
    NightPadAboutViewController *about = [NightPadAboutViewController new];
    __weak NightPadShellViewController *weakSelf = self;
    about.onClose = ^{ [weakSelf endNativeUI]; };
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:about];
    navigation.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:navigation animated:YES completion:nil];
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
        loadError != "The layout file is missing.")
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
    [self presentViewController:navigation animated:YES completion:nil];
}

- (void)openControlsHelp {
    [self beginNativeUI];
    [self closePanels];
    NightPadControlsHelpViewController *help = [NightPadControlsHelpViewController new];
    __weak NightPadShellViewController *weakSelf = self;
    help.onClose = ^{ [weakSelf endNativeUI]; };
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:help];
    navigation.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:navigation animated:YES completion:nil];
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
    const BOOL hide = _gameInput.controllerConnected && !_settings.touchControlsAlwaysVisible &&
                      _settings.hideTouchControlsWithController;
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

- (void)toggleUnlimitedAmmo {
    _settings.assistUnlimitedAmmo = !_settings.assistUnlimitedAmmo;
    [_engineHost setUnlimitedAmmo:_settings.assistUnlimitedAmmo];
    [self saveSettings];
    [self refreshMenu];
}

- (void)beginNativeUI {
    if (!_engineRunning)
        return;
    if (!_uiPausedEngine) {
        [_engineHost setPaused:YES];
        _enginePaused = YES;
        _uiPausedEngine = YES;
    }
    if (!_uiInputSuspended) {
        [_engineHost setInputSuspended:YES];
        _uiInputSuspended = YES;
    }
    [_gameInput setSuspended:YES];
}

- (void)endNativeUI {
    if (_uiInputSuspended) {
        [_engineHost setInputSuspended:NO];
        _uiInputSuspended = NO;
    }
    if (_uiPausedEngine) {
        [_engineHost setPaused:NO];
        _enginePaused = NO;
        _uiPausedEngine = NO;
    }
    [_gameInput setSuspended:NO];
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
    _enginePaused = NO;
    _gameplayMode = YES;
    [self installTouchControls];
    [self updateGameplaySurface];
    [self refreshMenu];
    _engineTimer = [NSTimer timerWithTimeInterval:1.0 / 60.0 target:self selector:@selector(pollEngine) userInfo:nil repeats:YES];
    [NSRunLoop.mainRunLoop addTimer:_engineTimer forMode:NSRunLoopCommonModes];
    _importButton.enabled = NO;
    [self refreshMenu];
}

- (void)pollEngine {
    if (!_engineRunning || _switchingEngine)
        return;
    if (_stopWhenBooted) {
        const NSTimeInterval waited = CFAbsoluteTimeGetCurrent() - _stopQueuedAt;
        if ([_engineHost frameCount] > 0 || waited > 180) {
            _stopWhenBooted = NO;
            _forceStopNow = waited > 180;
            [self stopGame];
            return;
        }
    }
    if ([_engineHost pollWindow])
        return;
    if ([_engineHost handoffPending]) {
        [self switchEngine];
        return;
    }
    [self stopGame];
}

- (void)switchEngine {
    if (_switchingEngine)
        return;
    _switchingEngine = YES;
    [_engineTimer invalidate];
    _engineTimer = nil;
    __weak NightPadShellViewController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NightPadShellViewController *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        const int joined = [strongSelf->_engineHost joinWithTimeout:30000];
        dispatch_async(dispatch_get_main_queue(), ^{
            NightPadShellViewController *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            [strongSelf->_engineHost closeWindow];
            if (!joined) {
                strongSelf->_switchingEngine = NO;
                [strongSelf showError:@"The game did not stop for the next session."];
                [strongSelf stopGame];
                return;
            }
            if (![strongSelf->_engineHost startHandoffTarget]) {
                strongSelf->_switchingEngine = NO;
                [strongSelf showError:@"The next game session could not start."];
                [strongSelf stopGame];
                return;
            }
            strongSelf->_enginePaused = NO;
            strongSelf->_uiPausedEngine = NO;
            strongSelf->_uiInputSuspended = NO;
            [strongSelf->_gameInput engineChanged];
            if (strongSelf->_engineHost.activeEngine == NightPadEngineKindAction) {
                [strongSelf->_engineHost setImmortal:strongSelf->_settings.assistImmortal];
                [strongSelf->_engineHost setUnlimitedAmmo:strongSelf->_settings.assistUnlimitedAmmo];
            }
            strongSelf->_switchingEngine = NO;
            strongSelf->_engineTimer = [NSTimer timerWithTimeInterval:1.0 / 60.0 target:strongSelf
                                                             selector:@selector(pollEngine)
                                                           userInfo:nil repeats:YES];
            [NSRunLoop.mainRunLoop addTimer:strongSelf->_engineTimer forMode:NSRunLoopCommonModes];
            [strongSelf updateGameplaySurface];
            [strongSelf refreshMenu];
        });
    });
}

- (void)stopGame {
    if (!_engineRunning) return;
    if (_switchingEngine) return;
    if (!_forceStopNow && [_engineHost frameCount] == 0) {
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
    _engineRunning = NO;
    [self endNativeUI];
    [self removeTouchControls];
    [_engineTimer invalidate];
    _engineTimer = nil;
    [_engineHost requestStop];
    __weak NightPadShellViewController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NightPadShellViewController *strongSelf = weakSelf;
        if (strongSelf == nil) return;
        int joined = [strongSelf->_engineHost joinWithTimeout:30000];
        dispatch_async(dispatch_get_main_queue(), ^{
            NightPadShellViewController *strongSelf = weakSelf;
            if (strongSelf == nil) return;
            [strongSelf->_engineHost closeWindow];
            strongSelf->_gameplayMode = NO;
            [strongSelf updateGameplaySurface];
            [strongSelf refreshDataState];
            if (!joined)
                [strongSelf showError:@"The engine did not stop within thirty seconds."];
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
    _discardButton.enabled = _importer->previousDataRetained();
    _progress.hidden = !_importing;
    _progressLabel.hidden = !_importing;
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
    NSURL *url = urls.firstObject;
    if (url == nil) return;
    [self importPreparedFolder:url];
}

- (void)importPreparedFolder:(NSURL *)url {
    BOOL scoped = [url startAccessingSecurityScopedResource];
    _importing = YES;
    _progress.hidden = NO;
    _progressLabel.hidden = NO;
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
    [self presentViewController:navigation animated:YES completion:nil];
}

- (void)showError:(NSString *)message {
    _lastError = [message copy];
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"NightPad"
            message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)showInfo:(NSString *)title detail:(NSString *)detail {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
        message:detail preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
