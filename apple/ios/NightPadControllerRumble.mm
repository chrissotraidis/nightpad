#import "NightPadControllerRumble.h"

#import <CoreHaptics/CoreHaptics.h>
#import <GameController/GameController.h>

#include <algorithm>
#include <atomic>

namespace {

constexpr int kPorts = 4;

struct Channel {
    CHHapticEngine *engine = nil;
    id<CHHapticAdvancedPatternPlayer> player = nil;
    bool ready = false;
    int sent = -1;
    int requested = 0;
};

struct PortRumble {
    GCController *__weak controller = nil;
    Channel left;
    Channel right;
    bool dual = false;
    bool playing = false;
};

}  // namespace

@implementation NightPadControllerRumble {
    dispatch_queue_t _queue;
    PortRumble _ports[kPorts];
    std::atomic<bool> _allowed;
}

- (instancetype)init {
    if ((self = [super init])) {
        _queue = dispatch_queue_create("local.nightpad.controller-rumble", DISPATCH_QUEUE_SERIAL);
        _allowed.store(true);
    }
    return self;
}

- (BOOL)allowed {
    return _allowed.load();
}

- (void)setAllowed:(BOOL)allowed {
    _allowed.store(allowed);
    if (!allowed)
        [self stopAll];
}

- (void)useController:(GCController *)controller forPort:(int)port {
    if (port < 0 || port >= kPorts)
        return;
    _ports[port].controller = controller;
    __weak NightPadControllerRumble *weakSelf = self;
    dispatch_async(_queue, ^{
        NightPadControllerRumble *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        [strongSelf teardownOnQueue:port];
        if (controller == nil || controller.haptics == nil)
            return;
        PortRumble &state = strongSelf->_ports[port];
        GCDeviceHaptics *haptics = controller.haptics;
        state.left.engine = [haptics createEngineWithLocality:GCHapticsLocalityLeftHandle];
        state.right.engine = [haptics createEngineWithLocality:GCHapticsLocalityRightHandle];
        state.dual = state.left.engine != nil && state.right.engine != nil;
        if (!state.dual) {
            state.left.engine = [haptics createEngineWithLocality:GCHapticsLocalityDefault];
            state.right.engine = nil;
        }
        [strongSelf prepareChannel:state.left];
        [strongSelf prepareChannel:state.right];
    });
}

- (void)prepareChannel:(Channel &)channel {
    if (channel.engine == nil)
        return;
    channel.engine.playsHapticsOnly = YES;
    NSError *error = nil;
    if (![channel.engine startAndReturnError:&error])
        return;
    CHHapticEvent *event = [[CHHapticEvent alloc]
        initWithEventType:CHHapticEventTypeHapticContinuous
               parameters:@[
                   [[CHHapticEventParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticIntensity value:0.0f],
                   [[CHHapticEventParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticSharpness value:0.3f],
               ]
             relativeTime:0.0
                 duration:GCHapticDurationInfinite];
    CHHapticPattern *pattern = [[CHHapticPattern alloc] initWithEvents:@[ event ] parameters:@[] error:&error];
    if (pattern == nil)
        return;
    channel.player = [channel.engine createAdvancedPlayerWithPattern:pattern error:&error];
    channel.ready = channel.player != nil;
    channel.sent = -1;
}

- (void)teardownOnQueue:(int)port {
    PortRumble &state = _ports[port];
    Channel *channels[] = { &state.left, &state.right };
    for (Channel *channel : channels) {
        channel->engine.stoppedHandler = ^(CHHapticEngineStoppedReason reason) { (void)reason; };
        channel->engine.resetHandler = ^{};
        [channel->player stopAtTime:CHHapticTimeImmediate error:nil];
        [channel->engine stopWithCompletionHandler:nil];
        channel->player = nil;
        channel->engine = nil;
        channel->ready = false;
        channel->sent = -1;
        channel->requested = 0;
    }
    state.dual = false;
    state.playing = false;
}

- (void)setLeft:(uint16_t)left right:(uint16_t)right forPort:(int)port {
    if (port < 0 || port >= kPorts)
        return;
    PortRumble &state = _ports[port];
    if (!state.dual)
        state.left.requested = std::max(left, right);
    else {
        state.left.requested = left;
        state.right.requested = right;
    }
    if (![self allowed]) {
        state.left.requested = state.right.requested = 0;
    }
    __weak NightPadControllerRumble *weakSelf = self;
    dispatch_async(_queue, ^{ [weakSelf applyOnQueue:port]; });
}

- (void)applyOnQueue:(int)port {
    PortRumble &state = _ports[port];
    const bool wanted = state.left.requested > 0 || state.right.requested > 0;
    if (wanted != state.playing) {
        NSError *error = nil;
        Channel *channels[] = { &state.left, &state.right };
        for (Channel *channel : channels) {
            if (!channel->ready)
                continue;
            if (wanted)
                [channel->player startAtTime:CHHapticTimeImmediate error:&error];
            else
                [channel->player stopAtTime:CHHapticTimeImmediate error:&error];
            channel->sent = -1;
        }
        state.playing = wanted;
    }
    if (!wanted)
        return;
    Channel *channels[] = { &state.left, &state.right };
    for (Channel *channel : channels) {
        if (!channel->ready || channel->requested == channel->sent)
            continue;
        CHHapticDynamicParameter *parameter = [[CHHapticDynamicParameter alloc]
            initWithParameterID:CHHapticDynamicParameterIDHapticIntensityControl
                          value:std::clamp(channel->requested / 255.0f, 0.0f, 1.0f)
                   relativeTime:0.0];
        NSError *error = nil;
        if ([channel->player sendParameters:@[ parameter ] atTime:CHHapticTimeImmediate error:&error])
            channel->sent = channel->requested;
    }
}

- (void)stopPort:(int)port {
    if (port < 0 || port >= kPorts)
        return;
    _ports[port].left.requested = 0;
    _ports[port].right.requested = 0;
    __weak NightPadControllerRumble *weakSelf = self;
    dispatch_async(_queue, ^{ [weakSelf applyOnQueue:port]; });
}

- (void)stopAll {
    for (int port = 0; port < kPorts; ++port)
        [self stopPort:port];
}

@end
