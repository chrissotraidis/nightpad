#import <Foundation/Foundation.h>

#include "../shared/NightPadInput.h"

// Owns the combined engine bridge for the native shell. The engine session is
// only started after game data is validated and the coordinator is stopped.
@interface NightPadEngineHost : NSObject
+ (BOOL)isLinked;
- (BOOL)prepareWithGameData:(NSString *)gameData
                 launchState:(NSString *)launchState
                       error:(NSString **)error;
- (BOOL)startAction;
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
