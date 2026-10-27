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
// Whether the controller that owns the touch player's port is present. Only
// this one may hide the touch overlay.
@property(nonatomic, readonly) BOOL touchPlayerControllerPresent;
@property(nonatomic, copy) void (^controllerConnectionChanged)(void);

- (void)start;
- (void)stop;
// Native UI in front: stop publishing, drop fingers and rumble, but keep the
// controller slot assignment so it is unchanged when play resumes.
- (void)setSuspended:(BOOL)suspended;
// The host switched to another engine: re-enable the pad path on it.
- (void)engineChanged;

@end
