#import <Foundation/Foundation.h>

// Owns the combined engine bridge for the native shell. The engine session is
// only started after game data is validated and the coordinator is stopped.
@interface NightPadEngineHost : NSObject
+ (BOOL)isLinked;
- (BOOL)prepareWithGameData:(NSString *)gameData
                 launchState:(NSString *)launchState
                       error:(NSString **)error;
- (BOOL)startAction;
- (void)requestStop;
- (int)joinWithTimeout:(unsigned)milliseconds;
- (void)closeWindow;
@end
