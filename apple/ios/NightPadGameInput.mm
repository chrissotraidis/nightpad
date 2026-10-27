#import "NightPadGameInput.h"

#include "../shared/NightPadControllerSlots.h"

using nightpad::InputMixer;
using nightpad::InputSource;
using nightpad::PadState;

static __weak NightPadGameInput *gGameInput;

@interface NightPadGameInput ()
- (void)tick;
- (void)applyRumbleLeft:(unsigned)left right:(unsigned)right port:(int)port;
@end

static void NightPadRumbleFromEngine(int port, unsigned leftMotor, unsigned rightMotor) {
    NightPadGameInput *input = gGameInput;
    if (input == nil)
        return;
    [input applyRumbleLeft:leftMotor right:rightMotor port:port];
}

@implementation NightPadGameInput {
    NightPadEngineHost *_host;
    NightPadTouchControlsView *_touchView;
    NightPadControllerAuthority *_controllers;
    NSTimer *_timer;
    InputMixer _mixer;
    BOOL _running;
    BOOL _suspended;
    BOOL _logInput;
    PadState _lastLogged[InputMixer::kPorts];
}

- (instancetype)initWithEngineHost:(NightPadEngineHost *)host touchView:(NightPadTouchControlsView *)touchView {
    if ((self = [super init])) {
        _host = host;
        _touchView = touchView;
        _logInput = [NSProcessInfo.processInfo.arguments containsObject:@"--log-input"];
        _controllers = [NightPadControllerAuthority new];
        __weak NightPadGameInput *weakSelf = self;
        _controllers.controllersChanged = ^{
            NightPadGameInput *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            [strongSelf releaseControllerState];
            if (strongSelf.controllerConnectionChanged)
                strongSelf.controllerConnectionChanged();
        };
        NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
        [center addObserver:self selector:@selector(applicationBecameActive:)
                       name:UIApplicationDidBecomeActiveNotification object:nil];
        [center addObserver:self selector:@selector(applicationEnteredBackground:)
                       name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)applicationBecameActive:(NSNotification *)note {
    (void)note;
    // A controller may have connected or slept while the app was away.
    [_controllers reconcile];
    [self releaseControllerState];
    if (self.controllerConnectionChanged)
        self.controllerConnectionChanged();
}

- (void)applicationEnteredBackground:(NSNotification *)note {
    (void)note;
    for (int port = 0; port < InputMixer::kPorts; ++port) {
        [_controllers stopRumbleForPort:port];
        _mixer.ClearPort(port);
        [_host setPad:port state:PadState{}];
    }
}

- (void)engineChanged {
    if (!_running || _suspended)
        return;
    [_host setHostPadsEnabled:YES];
    [_host setRumbleHandler:NightPadRumbleFromEngine];
    [self tick];
}

- (NightPadControllerAuthority *)controllers {
    return _controllers;
}

- (BOOL)controllerConnected {
    return _controllers.hasController;
}

- (void)start {
    if (_running)
        return;
    _running = YES;
    _suspended = NO;
    gGameInput = self;
    [_controllers start];
    [_host setRumbleHandler:NightPadRumbleFromEngine];
    [_host setHostPadsEnabled:YES];
    _timer = [NSTimer timerWithTimeInterval:1.0 / 60.0 target:self selector:@selector(tick) userInfo:nil repeats:YES];
    [NSRunLoop.mainRunLoop addTimer:_timer forMode:NSRunLoopCommonModes];
    [self tick];
}

- (void)stop {
    if (!_running)
        return;
    _running = NO;
    [self setSuspended:YES];
    [_timer invalidate];
    _timer = nil;
    [_host setHostPadsEnabled:NO];
    [_host setRumbleHandler:nil];
    [_controllers stop];
    gGameInput = nil;
}

- (void)releaseControllerState {
    for (int port = 0; port < InputMixer::kPorts; ++port) {
        BOOL present = NO;
        (void)[_controllers padForPort:port present:&present];
        if (!present) {
            _mixer.SetControllerPresent(port, false);
            _mixer.Clear(port, InputSource::Controller);
            [_controllers stopRumbleForPort:port];
        }
    }
}

- (void)setSuspended:(BOOL)suspended {
    if (_suspended == suspended)
        return;
    _suspended = suspended;
    if (suspended) {
        [_touchView releaseAllTouches];
        _mixer.ClearAll();
        for (int port = 0; port < InputMixer::kPorts; ++port) {
            [_controllers stopRumbleForPort:port];
            [_host setPad:port state:PadState{}];
        }
    } else {
        [self tick];
    }
}

- (void)tick {
    if (!_running || _suspended)
        return;
    _mixer.Set(0, InputSource::Touch, [_touchView currentPad]);
    for (int port = 0; port < InputMixer::kPorts; ++port) {
        BOOL present = NO;
        PadState controller = [_controllers padForPort:port present:&present];
        _mixer.SetControllerPresent(port, present);
        if (present)
            _mixer.Set(port, InputSource::Controller, controller);
        else
            _mixer.Clear(port, InputSource::Controller);
        const PadState out = _mixer.Consume(port);
        [_host setPad:port state:out];
        if (_logInput && !(out == _lastLogged[port])) {
            NSLog(@"[NightPad] port %d buttons=0x%04x lx=%d ly=%d rx=%d ry=%d lt=%u rt=%u",
                  port, out.buttons, out.leftX, out.leftY, out.rightX, out.rightY, out.leftTrigger,
                  out.rightTrigger);
            _lastLogged[port] = out;
        }
    }
}

- (void)applyRumbleLeft:(unsigned)left right:(unsigned)right port:(int)port {
    if (_suspended)
        return;
    [_controllers setRumbleLeft:static_cast<uint16_t>(left) right:static_cast<uint16_t>(right) port:port];
}

@end
