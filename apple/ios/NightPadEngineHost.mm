#import "NightPadEngineHost.h"

#include "../shared/NightPadEngineBridge.h"

#include <string>
#include <unistd.h>

@implementation NightPadEngineHost {
    NSString *_launchState;
}

+ (BOOL)isLinked {
#if NIGHTPAD_HAS_ENGINE
    return YES;
#else
    return NO;
#endif
}

static int AcceptLaunchRequest(NightPadEngineId engine, const char *image, const void *page, unsigned bytes) {
    (void)engine;
    (void)page;
    (void)bytes;
    NSLog(@"[NightPad] engine launch request: %s", image != nullptr ? image : "(null)");
    return 0;  // The coordinator does not hand off until the shell owns the target session.
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
    NSString *settings = [NSString stringWithFormat:
        @"[Settings]\nDiscPath=%@\nRenderWidth=640\nRenderHeight=480\nRegion=NTSC\nFPS=60\n", gameData];
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
    return YES;
}

- (BOOL)startAction {
#if NIGHTPAD_HAS_ENGINE
    NightPadActionEngineSetLaunchRequestCallback(AcceptLaunchRequest);
    char program[] = "NightPad";
    char *argv[] = { program, nullptr };
    return NightPadActionEngineStart(1, argv) != 0;
#else
    return NO;
#endif
}

- (BOOL)pollWindow {
#if NIGHTPAD_HAS_ENGINE
    return NightPadActionEnginePollWindow() != 0;
#else
    return NO;
#endif
}

- (void)setPaused:(BOOL)paused {
#if NIGHTPAD_HAS_ENGINE
    NightPadActionEngineSetPaused(paused ? 1 : 0);
#else
    (void)paused;
#endif
}

- (void)setInputSuspended:(BOOL)suspended {
#if NIGHTPAD_HAS_ENGINE
    NightPadActionEngineSetInputSuspended(suspended ? 1 : 0);
#else
    (void)suspended;
#endif
}

- (void)setHostPadsEnabled:(BOOL)enabled {
#if NIGHTPAD_HAS_ENGINE
    NightPadActionEngineSetHostPadsEnabled(enabled ? 1 : 0);
#else
    (void)enabled;
#endif
}

- (void)setPad:(int)port state:(const nightpad::PadState &)state {
#if NIGHTPAD_HAS_ENGINE
    NightPadActionEngineSetHostPad(port, state.buttons, state.leftX, state.leftY, state.rightX, state.rightY,
                                   state.leftTrigger, state.rightTrigger, state.connected ? 1 : 0);
#else
    (void)port;
    (void)state;
#endif
}

- (void)setRumbleHandler:(void (*)(int, unsigned, unsigned))handler {
#if NIGHTPAD_HAS_ENGINE
    NightPadActionEngineSetRumbleHandler(handler);
#else
    (void)handler;
#endif
}

- (void)requestStop {
#if NIGHTPAD_HAS_ENGINE
    NightPadActionEngineRequestStop();
#endif
}

- (int)joinWithTimeout:(unsigned)milliseconds {
#if NIGHTPAD_HAS_ENGINE
    return NightPadActionEngineJoin(milliseconds);
#else
    return 1;
#endif
}

- (void)closeWindow {
#if NIGHTPAD_HAS_ENGINE
    NightPadActionEngineCloseWindow();
#endif
}

@end
