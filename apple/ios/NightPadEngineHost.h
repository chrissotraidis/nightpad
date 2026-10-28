#import <Foundation/Foundation.h>

#include "../shared/NightPadInput.h"

typedef NS_ENUM(NSInteger, NightPadEngineKind) {
    NightPadEngineKindAction = 0,
    NightPadEngineKindDriving = 1,
};

// Owns the combined engine bridge for the native shell. The engine session is
// only started after game data is validated and the coordinator is stopped.
@interface NightPadEngineHost : NSObject
// Scene render size and display options written to settings.ini when a
// session is prepared. They take effect for the next engine start.
@property(nonatomic) int renderWidth;
@property(nonatomic) int renderHeight;
@property(nonatomic) BOOL antiAliasing;
@property(nonatomic) BOOL widescreen;
@property(nonatomic) int fov;

+ (BOOL)isLinked;
- (BOOL)prepareWithGameData:(NSString *)gameData
                 launchState:(NSString *)launchState
                       error:(NSString **)error;
- (BOOL)startAction;
- (BOOL)startDriving;
@property(nonatomic, readonly) NightPadEngineKind activeEngine;
// Set when the running game handed off to another XBE. Start it once the
// current engine has joined and its window is closed.
@property(nonatomic, readonly) BOOL handoffPending;
- (BOOL)startHandoffTarget;
- (void)clearHandoff;
// Frames advanced by the active engine. Zero means it is still booting.
- (unsigned long)frameCount;
- (BOOL)blockingMovieFrames:(unsigned long *)frames paused:(int *)paused;
// Optional action-only assists; the action loop re-applies them each frame.
- (void)setImmortal:(BOOL)enabled;
- (void)setUnlimitedAmmo:(BOOL)enabled;
- (void)setPaused:(BOOL)paused;
- (void)setInputSuspended:(BOOL)suspended;
// The app is the pad authority once this is enabled: the engine reads only the states published below.
- (void)setHostPadsEnabled:(BOOL)enabled;
- (void)setPad:(int)port state:(const nightpad::PadState &)state;
- (void)setRumbleHandler:(void (*)(int port, unsigned leftMotor, unsigned rightMotor))handler;
- (BOOL)pollWindow;
- (void)requestStop;
- (int)joinWithTimeout:(unsigned)milliseconds;
- (void)closeWindow;
@end
