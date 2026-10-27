#import "NightPadShellViewController.h"
#import "NightPadEngineHost.h"

#include "../shared/NightPadGameDataImport.h"

#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
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
    BOOL _uiPausedEngine;
    BOOL _uiInputSuspended;
    BOOL _gameplayMode;
    NSTimer *_engineTimer;

    UILabel *_title;
    UILabel *_status;
    NightPadMenuButton *_menuButton;
    UIView *_menuPanel;
    UIView *_dataPanel;
    UIView *_pausePanel;
    UIView *_aboutPanel;
    UIProgressView *_progress;
    UILabel *_progressLabel;
    UIButton *_importButton;
    UIButton *_discardButton;
    UIButton *_startButton;
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
    _menuButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_menuButton addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_menuButton];

    [self buildMenuPanel];
    [self buildDataPanel];
    [self buildPausePanel];
    [self buildAboutPanel];

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
    [self refreshDataState];
    // Deterministic shell screenshots and UI smoke tests.
    if ([NSProcessInfo.processInfo.arguments containsObject:@"--open-menu"])
        [self toggleMenu];
    else if ([NSProcessInfo.processInfo.arguments containsObject:@"--open-data"])
        [self openDataPanel];
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

- (void)buildMenuPanel {
    _menuPanel = [self cardWithFrame:CGRectZero];
    [self.view addSubview:_menuPanel];
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [_menuPanel addSubview:stack];
    _startButton = [self panelButton:@"Start Game" action:@selector(startGame)];
    _startButton.enabled = NO;
    [stack addArrangedSubview:_startButton];
    [stack addArrangedSubview:[self panelButton:@"Game Data & Saves" action:@selector(openDataPanel)]];
    [stack addArrangedSubview:[self panelButton:@"App Pause" action:@selector(showPausePanel)]];
    [stack addArrangedSubview:[self panelButton:@"About NightPad" action:@selector(openAboutPanel)]];
    [stack addArrangedSubview:[self panelButton:@"Diagnostics" action:@selector(openDiagnostics)]];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:_menuPanel.leadingAnchor constant:8],
        [stack.trailingAnchor constraintEqualToAnchor:_menuPanel.trailingAnchor constant:-8],
        [stack.topAnchor constraintEqualToAnchor:_menuPanel.topAnchor constant:8],
        [stack.bottomAnchor constraintEqualToAnchor:_menuPanel.bottomAnchor constant:-8],
        [_menuPanel.trailingAnchor constraintEqualToAnchor:_menuButton.trailingAnchor],
        [_menuPanel.topAnchor constraintEqualToAnchor:_menuButton.bottomAnchor constant:8],
        [_menuPanel.widthAnchor constraintGreaterThanOrEqualToConstant:250],
    ]];
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

- (void)buildAboutPanel {
    _aboutPanel = [self cardWithFrame:CGRectZero];
    [self.view addSubview:_aboutPanel];
    UILabel *label = [UILabel new];
    label.text = @"NightPad\n\nA native Apple port of 007: Nightfire.\n\nEngine: NightfireResearch/nightfire-cxbx\nInterface donors: GalaxyPad and SunPad.\n\nSource and notices are included in the app bundle and project repository.";
    label.textColor = UIColor.whiteColor;
    label.numberOfLines = 0;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [_aboutPanel addSubview:label];
    UIButton *close = [self panelButton:@"Close" action:@selector(dismissPanels)];
    close.translatesAutoresizingMaskIntoConstraints = NO;
    [_aboutPanel addSubview:close];
    [NSLayoutConstraint activateConstraints:@[
        [_aboutPanel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_aboutPanel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [_aboutPanel.widthAnchor constraintEqualToConstant:500],
        [label.leadingAnchor constraintEqualToAnchor:_aboutPanel.leadingAnchor constant:24],
        [label.trailingAnchor constraintEqualToAnchor:_aboutPanel.trailingAnchor constant:-24],
        [label.topAnchor constraintEqualToAnchor:_aboutPanel.topAnchor constant:22],
        [close.leadingAnchor constraintEqualToAnchor:label.leadingAnchor],
        [close.topAnchor constraintEqualToAnchor:label.bottomAnchor constant:14],
        [close.bottomAnchor constraintEqualToAnchor:_aboutPanel.bottomAnchor constant:-14],
    ]];
}

- (void)toggleMenu {
    BOOL show = _menuPanel.hidden;
    [self closePanels];
    _menuPanel.hidden = !show;
    if (show) {
        [self beginNativeUI];
        [self.view bringSubviewToFront:_menuPanel];
    } else {
        [self endNativeUI];
    }
}

- (void)closePanels {
    _menuPanel.hidden = YES;
    _dataPanel.hidden = YES;
    _pausePanel.hidden = YES;
    _aboutPanel.hidden = YES;
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

- (void)openAboutPanel {
    [self beginNativeUI];
    [self closePanels];
    _aboutPanel.hidden = NO;
    [self.view bringSubviewToFront:_aboutPanel];
}

- (void)dismissPanels {
    [self closePanels];
    [self endNativeUI];
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
    if (![_engineHost prepareWithGameData:gameData launchState:launchState error:&error] ||
        ![_engineHost startAction]) {
        [self showError:error.length ? error : @"The engine could not start."];
        return;
    }
    [self closePanels];
    [self endNativeUI];
    _engineRunning = YES;
    _enginePaused = NO;
    _gameplayMode = YES;
    [self updateGameplaySurface];
    _engineTimer = [NSTimer timerWithTimeInterval:1.0 / 60.0 target:self selector:@selector(pollEngine) userInfo:nil repeats:YES];
    [NSRunLoop.mainRunLoop addTimer:_engineTimer forMode:NSRunLoopCommonModes];
    UIButtonConfiguration *runningConfiguration = _startButton.configuration;
    runningConfiguration.title = @"Stop Game";
    _startButton.configuration = runningConfiguration;
    _importButton.enabled = NO;
}

- (void)pollEngine {
    if (!_engineRunning || ![_engineHost pollWindow]) {
        [self stopGame];
    }
}

- (void)stopGame {
    if (!_engineRunning) return;
    _engineRunning = NO;
    [self endNativeUI];
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
    _startButton.enabled = (_state == DataState::Ready && [NightPadEngineHost isLinked]) || _engineRunning;
    UIButtonConfiguration *startConfiguration = _startButton.configuration;
    startConfiguration.title = _engineRunning ? @"Stop Game" : @"Start Game";
    _startButton.configuration = startConfiguration;
    _importButton.enabled = !_engineRunning && !_importing;
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
    [self closePanels];
    NSString *path = [NSString stringWithUTF8String:_paths.diagnostics.c_str()];
    UIActivityViewController *share = [[UIActivityViewController alloc] initWithActivityItems:@[path] applicationActivities:nil];
    share.popoverPresentationController.sourceView = _menuButton;
    share.popoverPresentationController.sourceRect = _menuButton.bounds;
    [self presentViewController:share animated:YES completion:nil];
}

- (void)showError:(NSString *)message {
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
