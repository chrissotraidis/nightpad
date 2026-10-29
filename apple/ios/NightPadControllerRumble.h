#import <Foundation/Foundation.h>

@class GCController;

// Plays one port's Xbox motor speeds on the controller that owns that port.
// Two channels are used where the controller exposes left/right handle
// haptics; otherwise both motors collapse into one default-locality channel at
// the stronger speed. Every call is safe from the engine thread; the main
// thread binds controllers when slots change.
@interface NightPadControllerRumble : NSObject

@property(nonatomic, assign) BOOL allowed;

- (void)useController:(nullable GCController *)controller forPort:(int)port;
- (void)setLeft:(uint16_t)left right:(uint16_t)right forPort:(int)port;
- (void)stopPort:(int)port;
- (void)stopAll;

@end
