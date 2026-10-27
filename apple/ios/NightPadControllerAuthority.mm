#import "NightPadControllerAuthority.h"
#import "NightPadControllerRumble.h"

#include "../shared/NightPadControllerSlots.h"

#import <GameController/GameController.h>

#include <cmath>
#include <vector>

using nightpad::ControllerSlots;
using nightpad::InputMixer;
using nightpad::PadState;

namespace {

int16_t AxisValue(float value) {
    if (!std::isfinite(value))
        return 0;
    return static_cast<int16_t>(std::lround(std::clamp(value, -1.0f, 1.0f) * 32767.0f));
}

uint8_t TriggerValue(float value) {
    if (!std::isfinite(value))
        return 0;
    return static_cast<uint8_t>(std::lround(std::clamp(value, 0.0f, 1.0f) * 255.0f));
}

PadState PadFromExtended(GCExtendedGamepad *pad) {
    PadState state;
    state.connected = true;
    if (pad.dpad.up.pressed) state.buttons |= nightpad::kDpadUp;
    if (pad.dpad.down.pressed) state.buttons |= nightpad::kDpadDown;
    if (pad.dpad.left.pressed) state.buttons |= nightpad::kDpadLeft;
    if (pad.dpad.right.pressed) state.buttons |= nightpad::kDpadRight;
    if (pad.buttonA.pressed) state.buttons |= nightpad::kA;
    if (pad.buttonB.pressed) state.buttons |= nightpad::kB;
    if (pad.buttonX.pressed) state.buttons |= nightpad::kX;
    if (pad.buttonY.pressed) state.buttons |= nightpad::kY;
    // Modern LB/RB carry the original black/white buttons.
    if (pad.leftShoulder.pressed) state.buttons |= nightpad::kWhite;
    if (pad.rightShoulder.pressed) state.buttons |= nightpad::kBlack;
    if (pad.buttonMenu.pressed) state.buttons |= nightpad::kStart;
    if (pad.buttonOptions.pressed) state.buttons |= nightpad::kBack;
    if (pad.leftThumbstickButton.pressed) state.buttons |= nightpad::kLeftThumb;
    if (pad.rightThumbstickButton.pressed) state.buttons |= nightpad::kRightThumb;
    state.leftX = AxisValue(pad.leftThumbstick.xAxis.value);
    state.leftY = AxisValue(pad.leftThumbstick.yAxis.value);  // GameController Y is up-positive, as XInput's.
    state.rightX = AxisValue(pad.rightThumbstick.xAxis.value);
    state.rightY = AxisValue(pad.rightThumbstick.yAxis.value);
    state.leftTrigger = TriggerValue(pad.leftTrigger.value);
    state.rightTrigger = TriggerValue(pad.rightTrigger.value);
    return state;
}

PadState PadFromMicro(GCMicroGamepad *pad) {
    PadState state;
    state.connected = true;
    if (pad.dpad.up.pressed) state.buttons |= nightpad::kDpadUp;
    if (pad.dpad.down.pressed) state.buttons |= nightpad::kDpadDown;
    if (pad.dpad.left.pressed) state.buttons |= nightpad::kDpadLeft;
    if (pad.dpad.right.pressed) state.buttons |= nightpad::kDpadRight;
    if (pad.buttonA.pressed) state.buttons |= nightpad::kA;
    if (pad.buttonX.pressed) state.buttons |= nightpad::kB;
    if (pad.buttonMenu.pressed) state.buttons |= nightpad::kStart;
    state.leftX = AxisValue(pad.dpad.xAxis.value);
    state.leftY = AxisValue(pad.dpad.yAxis.value);
    return state;
}

PadState PadFromController(GCController *controller) {
    if (controller.extendedGamepad != nil)
        return PadFromExtended(controller.extendedGamepad);
    if (controller.microGamepad != nil)
        return PadFromMicro(controller.microGamepad);
    PadState state;
    state.connected = true;
    return state;
}

}  // namespace

@implementation NightPadControllerAuthority {
    ControllerSlots _slots;
    NightPadControllerRumble *_rumble;
    NSMutableArray<GCController *> *_controllers;
    BOOL _started;
    BOOL _discovering;
}

- (instancetype)init {
    if ((self = [super init])) {
        _rumble = [NightPadControllerRumble new];
        _controllers = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc {
    [self stop];
}

- (void)start {
    if (_started)
        return;
    _started = YES;
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center addObserver:self selector:@selector(controllerChanged:) name:GCControllerDidConnectNotification object:nil];
    [center addObserver:self selector:@selector(controllerChanged:) name:GCControllerDidDisconnectNotification object:nil];
    GCController.shouldMonitorBackgroundEvents = YES;
    [self reconcile];
}

- (void)stop {
    if (!_started)
        return;
    _started = NO;
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [GCController stopWirelessControllerDiscovery];
    _discovering = NO;
    [_rumble stopAll];
}

- (void)controllerChanged:(NSNotification *)note {
    (void)note;
    [self reconcile];
}

- (BOOL)hasController {
    return _controllers.count > 0;
}

- (int)controllerCount {
    return static_cast<int>(_controllers.count);
}

- (void)reconcile {
    NSArray<GCController *> *current = [GCController.controllers copy];
    std::vector<uintptr_t> instances;
    instances.reserve(current.count);
    for (GCController *controller in current)
        instances.push_back(reinterpret_cast<uintptr_t>((__bridge void *)controller));

    auto result = _slots.Reconcile(instances);
    for (const auto &removed : result.removed) {
        [_rumble stopPort:static_cast<int>(removed.slot)];
        [_rumble useController:nil forPort:static_cast<int>(removed.slot)];
    }
    if (result.removed.size() > 0 || result.assigned.size() > 0)
        _controllers = [current mutableCopy];
    for (const auto &assigned : result.assigned) {
        GCController *controller = nil;
        for (GCController *candidate in current)
            if (reinterpret_cast<uintptr_t>((__bridge void *)candidate) == assigned.instance)
                controller = candidate;
        [_rumble useController:controller forPort:static_cast<int>(assigned.slot)];
    }

    [self updateDiscovery];
    if ((result.removed.size() > 0 || result.assigned.size() > 0) && self.controllersChanged)
        self.controllersChanged();
}

- (void)updateDiscovery {
    if (_controllers.count > 0) {
        if (_discovering) {
            [GCController stopWirelessControllerDiscovery];
            _discovering = NO;
        }
        return;
    }
    if (_discovering)
        return;
    _discovering = YES;
    __weak NightPadControllerAuthority *weakSelf = self;
    [GCController startWirelessControllerDiscoveryWithCompletionHandler:^{
        NightPadControllerAuthority *strongSelf = weakSelf;
        if (strongSelf != nil)
            strongSelf->_discovering = NO;
    }];
}

- (GCController *)controllerForPort:(int)port {
    if (port < 0 || port >= static_cast<int>(ControllerSlots::kMaxPlayers))
        return nil;
    const uintptr_t wanted = _slots.InstanceIn(static_cast<std::size_t>(port));
    if (wanted == 0)
        return nil;
    for (GCController *controller in _controllers)
        if (reinterpret_cast<uintptr_t>((__bridge void *)controller) == wanted)
            return controller;
    return nil;
}

- (PadState)padForPort:(int)port present:(BOOL *)present {
    GCController *controller = [self controllerForPort:port];
    if (present != nullptr)
        *present = controller != nil;
    if (controller == nil)
        return PadState{};
    return PadFromController(controller);
}

- (void)setRumbleLeft:(uint16_t)left right:(uint16_t)right port:(int)port {
    [_rumble setLeft:left right:right forPort:port];
}

- (void)stopRumbleForPort:(int)port {
    [_rumble stopPort:port];
}

- (void)setRumbleAllowed:(BOOL)allowed {
    _rumble.allowed = allowed;
}

@end
