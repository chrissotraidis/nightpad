#import <Foundation/Foundation.h>

#import "NightPadControllerAuthority.h"
#import "NightPadEngineHost.h"
#import "NightPadTouchControlsView.h"

// Owns the single input path during play: touch and one physical controller
// authority merge through NightPadInput's four ports, and each port is published
// to the engine. Rumble from the engine returns to the controller that owns the
// port, so ports never cross.
@interface NightPadGameInput : NSObject

- (instancetype)initWithEngineHost:(NightPadEngineHost *)host touchView:(NightPadTouchControlsView *)touchView;

@property(nonatomic, readonly) NightPadControllerAuthority *controllers;
@property(nonatomic, readonly) BOOL controllerConnected;
@property(nonatomic, copy) void (^controllerConnectionChanged)(void);

- (void)start;
- (void)stop;
// Native UI in front: stop publishing, drop fingers and rumble, but keep the
// controller slot assignment so it is unchanged when play resumes.
- (void)setSuspended:(BOOL)suspended;

@end
