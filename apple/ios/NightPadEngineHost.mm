#import "NightPadEngineHost.h"

#include "../shared/NightPadEngineBridge.h"
#include "../shared/NightPadEngineSettings.h"
#include "../shared/NightPadPaths.h"
#include "../shared/NightPadSaves.h"

#include <string>
#include <unistd.h>

static __weak NightPadEngineHost *gHost;

@interface NightPadEngineHost ()
- (void)recordHandoff:(const char *)image;
- (BOOL)startActionPreservingLaunchData:(BOOL)preserve;
@end

@implementation NightPadEngineHost {
    NSString *_launchState;
    NSString *_handoffImage;
    NightPadEngineKind _engine;
}

- (instancetype)init {
    if ((self = [super init])) {
        _renderWidth = 640;
        _renderHeight = 480;
        _antiAliasing = YES;
        _widescreen = NO;
        _fov = 60;
    }
    return self;
}

+ (BOOL)isLinked {
#if NIGHTPAD_HAS_ENGINE
    return YES;
#else
    return NO;
#endif
}

static int AcceptLaunchRequest(NightPadEngineId engine, const char *image, const void *page, unsigned bytes) {
    (void)page;
    (void)bytes;
    NSLog(@"[NightPad] engine launch request: %s", image != nullptr ? image : "(null)");
    NightPadEngineHost *host = gHost;
    if (host == nil)
        return 0;
    [host recordHandoff:image];
    // The game thread must end so the shell can join it and start the target.
    if (engine == NIGHTPAD_ENGINE_ACTION)
        NightPadActionEngineRequestStop();
    else
        NightPadDrivingEngineRequestStop();
    return 1;
}

- (BOOL)prepareWithGameData:(NSString *)gameData launchState:(NSString *)launchState error:(NSString **)error {
    if (gameData.length == 0 || launchState.length == 0) {
        if (error != nullptr) *error = @"Game data and launch-state paths are required.";
        return NO;
    }
    NSFileManager *files = NSFileManager.defaultManager;
    NSError *fileError = nil;
    if (![files createDirectoryAtPath:launchState withIntermediateDirectories:YES attributes:nil error:&fileError]) {
        if (error != nullptr) *error = fileError.localizedDescription ?: @"Could not create the launch-state directory.";
        return NO;
    }
    nightpad::EngineDisplaySettings display;
    display.renderWidth = _renderWidth > 0 ? _renderWidth : 640;
    display.renderHeight = _renderHeight > 0 ? _renderHeight : 480;
    display.antiAliasing = _antiAliasing;
    display.widescreen = _widescreen;
    display.fov = _fov > 0 ? _fov : 60;
    NSString *settings = [NSString stringWithUTF8String:
        nightpad::BuildEngineSettings(gameData.UTF8String, display).c_str()];
    NSString *path = [launchState stringByAppendingPathComponent:@"settings.ini"];
    if (![settings writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&fileError]) {
        if (error != nullptr) *error = fileError.localizedDescription ?: @"Could not write settings.ini.";
        return NO;
    }
    _launchState = [launchState copy];
    if (chdir(launchState.fileSystemRepresentation) != 0) {
        if (error != nullptr) *error = @"Could not enter the launch-state directory.";
        return NO;
    }
    // The game writes saves to a relative "saves" folder. Point that at the
    // app's durable Saves directory so a new import or launch-state reset can
    // never strand a campaign.
    const nightpad::Paths paths = nightpad::Paths::ForContainer(NSHomeDirectory().UTF8String);
    std::string linkError;
    if (!nightpad::EnsureSavesLink(launchState.fileSystemRepresentation, paths.saves, &linkError)) {
        if (error != nullptr) *error = [NSString stringWithUTF8String:linkError.c_str()];
        return NO;
    }
    return YES;
}

- (BOOL)startAction {
    return [self startActionPreservingLaunchData:NO];
}

- (BOOL)startActionPreservingLaunchData:(BOOL)preserve {
#if NIGHTPAD_HAS_ENGINE
    if (!preserve && _launchState.length != 0) {
        NSString *launchFile = [_launchState stringByAppendingPathComponent:@"psiLaunch.bin"];
        unlink(launchFile.fileSystemRepresentation);
    }
    NightPadActionEngineSetLaunchRequestCallback(AcceptLaunchRequest);
    char program[] = "NightPad";
    char *argv[] = { program, nullptr };
    if (!NightPadActionEngineStart(1, argv))
        return NO;
    _engine = NightPadEngineKindAction;
    _handoffImage = nil;
    gHost = self;
    NightPadActionEngineSetPaused(0);
    NightPadActionEngineSetInputSuspended(0);
    return YES;
#else
    return NO;
#endif
}

- (BOOL)startDriving {
#if NIGHTPAD_HAS_ENGINE
    NightPadDrivingEngineSetLaunchRequestCallback(AcceptLaunchRequest);
    char program[] = "NightPad";
    char *argv[] = { program, nullptr };
    if (!NightPadDrivingEngineStart(1, argv))
        return NO;
    _engine = NightPadEngineKindDriving;
    _handoffImage = nil;
    gHost = self;
    NightPadDrivingEngineSetPaused(0);
    NightPadDrivingEngineSetInputSuspended(0);
    return YES;
#else
    return NO;
#endif
}

- (NightPadEngineKind)activeEngine {
    return _engine;
}

- (BOOL)handoffPending {
    return _handoffImage.length > 0;
}

- (void)recordHandoff:(const char *)image {
    _handoffImage = image != nullptr ? [NSString stringWithUTF8String:image] : @"";
}

- (void)clearHandoff {
    _handoffImage = nil;
}

- (unsigned long)frameCount {
#if NIGHTPAD_HAS_ENGINE
    return _engine == NightPadEngineKindDriving ? NightPadDrivingEngineFrameCount()
                                                : NightPadActionEngineFrameCount();
#else
    return 0;
#endif
}

- (void)setImmortal:(BOOL)enabled {
#if NIGHTPAD_HAS_ENGINE
    if (_engine == NightPadEngineKindAction)
        NightPadActionEngineSetAssistImmortal(enabled ? 1 : 0);
#else
    (void)enabled;
#endif
}

- (void)setUnlimitedAmmo:(BOOL)enabled {
#if NIGHTPAD_HAS_ENGINE
    if (_engine == NightPadEngineKindAction)
        NightPadActionEngineSetAssistUnlimitedAmmo(enabled ? 1 : 0);
#else
    (void)enabled;
#endif
}

- (BOOL)startHandoffTarget {
    NSString *target = [_handoffImage lowercaseString];
    if (target.length == 0)
        return NO;
    const BOOL toDriving = [target containsString:@"driving.xbe"];
    _handoffImage = nil;
    return toDriving ? [self startDriving] : [self startActionPreservingLaunchData:YES];
}

- (BOOL)pollWindow {
#if NIGHTPAD_HAS_ENGINE
    return (_engine == NightPadEngineKindDriving ? NightPadDrivingEnginePollWindow()
                                                 : NightPadActionEnginePollWindow()) != 0;
#else
    return NO;
#endif
}

- (void)setPaused:(BOOL)paused {
#if NIGHTPAD_HAS_ENGINE
    if (_engine == NightPadEngineKindDriving)
        NightPadDrivingEngineSetPaused(paused ? 1 : 0);
    else
        NightPadActionEngineSetPaused(paused ? 1 : 0);
#else
    (void)paused;
#endif
}

- (void)setInputSuspended:(BOOL)suspended {
#if NIGHTPAD_HAS_ENGINE
    if (_engine == NightPadEngineKindDriving)
        NightPadDrivingEngineSetInputSuspended(suspended ? 1 : 0);
    else
        NightPadActionEngineSetInputSuspended(suspended ? 1 : 0);
#else
    (void)suspended;
#endif
}

- (void)setHostPadsEnabled:(BOOL)enabled {
#if NIGHTPAD_HAS_ENGINE
    if (_engine == NightPadEngineKindDriving)
        NightPadDrivingEngineSetHostPadsEnabled(enabled ? 1 : 0);
    else
        NightPadActionEngineSetHostPadsEnabled(enabled ? 1 : 0);
#else
    (void)enabled;
#endif
}

- (void)setPad:(int)port state:(const nightpad::PadState &)state {
#if NIGHTPAD_HAS_ENGINE
    if (_engine == NightPadEngineKindDriving)
        NightPadDrivingEngineSetHostPad(port, state.buttons, state.leftX, state.leftY, state.rightX, state.rightY,
                                        state.leftTrigger, state.rightTrigger, state.connected ? 1 : 0);
    else
        NightPadActionEngineSetHostPad(port, state.buttons, state.leftX, state.leftY, state.rightX, state.rightY,
                                       state.leftTrigger, state.rightTrigger, state.connected ? 1 : 0);
#else
    (void)port;
    (void)state;
#endif
}

- (void)setRumbleHandler:(void (*)(int, unsigned, unsigned))handler {
#if NIGHTPAD_HAS_ENGINE
    if (_engine == NightPadEngineKindDriving)
        NightPadDrivingEngineSetRumbleHandler(handler);
    else
        NightPadActionEngineSetRumbleHandler(handler);
#else
    (void)handler;
#endif
}

- (void)requestStop {
#if NIGHTPAD_HAS_ENGINE
    if (_engine == NightPadEngineKindDriving)
        NightPadDrivingEngineRequestStop();
    else
        NightPadActionEngineRequestStop();
#endif
}

- (int)joinWithTimeout:(unsigned)milliseconds {
#if NIGHTPAD_HAS_ENGINE
    return _engine == NightPadEngineKindDriving ? NightPadDrivingEngineJoin(milliseconds)
                                                : NightPadActionEngineJoin(milliseconds);
#else
    return 1;
#endif
}

- (void)closeWindow {
#if NIGHTPAD_HAS_ENGINE
    if (_engine == NightPadEngineKindDriving)
        NightPadDrivingEngineCloseWindow();
    else
        NightPadActionEngineCloseWindow();
#endif
}

@end
