#import <Foundation/Foundation.h>

#include "../shared/NightPadInput.h"

// The single physical-controller authority on iOS: Apple's GameController
// framework. SDL's own gamepads stay disabled while this is active, so a
// controller never reaches the engine twice. Controllers take stable player
// slots (a sole controller reclaims player 1) and map to XInput's shape with
// LB/RB on White/Black, analog triggers and original Start/Back.
@interface NightPadControllerAuthority : NSObject

// Called on the main thread whenever a controller connects, disconnects or
// changes slots. The owner should release that port in the input mixer.
@property(nonatomic, copy) void (^controllersChanged)(void);
@property(nonatomic, readonly) BOOL hasController;
@property(nonatomic, readonly) int controllerCount;

- (void)start;
- (void)stop;
- (void)reconcile;
- (nightpad::PadState)padForPort:(int)port present:(BOOL *)present;
- (void)setRumbleLeft:(uint16_t)left right:(uint16_t)right port:(int)port;
- (void)stopRumbleForPort:(int)port;
// Player preference; off stops rumble at once.
- (void)setRumbleAllowed:(BOOL)allowed;

@end
