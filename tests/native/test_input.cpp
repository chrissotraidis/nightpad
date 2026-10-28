#include "../../apple/shared/NightPadInput.h"

#include <iostream>

using nightpad::InputMixer;
using nightpad::InputSource;
using nightpad::PadState;

static int failures = 0;
static void Check(bool value, const char *what) {
    if (!value) {
        std::cerr << "FAIL: " << what << "\n";
        ++failures;
    }
}

int main() {
    InputMixer mixer;
    PadState touch;
    touch.connected = true;
    touch.leftX = 32767;
    // Short tap: the edge survives two polls that see it released.
    touch.buttons = nightpad::kA;
    mixer.Set(0, InputSource::Touch, touch);
    touch.buttons = 0;
    mixer.Set(0, InputSource::Touch, touch);
    Check(mixer.Consume(0).buttons & nightpad::kA, "short tap edge survives release");
    Check((mixer.Consume(0).buttons & nightpad::kA) == 0, "edge consumed once");

    // Dead zone and trigger threshold.
    touch.leftX = 3000;
    touch.leftY = 10000;
    touch.leftTrigger = 3;
    touch.rightTrigger = 200;
    mixer.Set(0, InputSource::Touch, touch);
    PadState merged = mixer.Consume(0);
    Check(merged.leftX == 0 && merged.leftY > 0, "axis dead zone");
    Check(merged.leftTrigger == 0 && merged.rightTrigger == 200, "trigger threshold");

    // Controller joins: held buttons are withheld until release; axes still work.
    PadState controller;
    controller.connected = true;
    controller.buttons = nightpad::kY;
    controller.leftY = -32767;
    mixer.SetControllerPresent(0, true);
    mixer.Set(0, InputSource::Controller, controller);
    merged = mixer.Consume(0);
    Check((merged.buttons & nightpad::kY) == 0, "held button not accepted on acquire");
    Check(merged.leftY < 0, "controller axes accepted on acquire");
    controller.buttons = 0;
    mixer.Set(0, InputSource::Controller, controller);
    controller.buttons = nightpad::kY;
    mixer.Set(0, InputSource::Controller, controller);
    Check(mixer.Consume(0).buttons & nightpad::kY, "button accepted after release");

    // Simultaneous touch/controller merger, independent port isolation.
    touch.buttons = nightpad::kB;
    controller.buttons = nightpad::kX;
    mixer.Set(0, InputSource::Touch, touch);
    mixer.Set(0, InputSource::Controller, controller);
    merged = mixer.Consume(0);
    Check((merged.buttons & (nightpad::kA | nightpad::kB | nightpad::kX)) == (nightpad::kB | nightpad::kX),
          "sources merge on one port");
    PadState other;
    other.connected = true;
    other.buttons = nightpad::kWhite;
    mixer.Set(1, InputSource::Controller, other);
    Check((mixer.Consume(0).buttons & nightpad::kWhite) == 0, "port isolation");
    Check(mixer.Consume(1).buttons & nightpad::kWhite, "other port retained");

    // ClearPort drops held and edge state for a transition.
    mixer.ClearPort(0);
    Check(mixer.Consume(0).buttons == 0 && mixer.Consume(0).leftX == 0, "port clear");
    Check(mixer.ControllerPresent(0) == false, "controller presence cleared");

    // An interruption clears latched edges and waits for complete release,
    // including analog controls. Each source/port releases independently.
    mixer.ClearAll();
    PadState held;
    held.connected = true;
    held.buttons = nightpad::kA;
    held.leftY = 24000;
    held.rightTrigger = 255;
    mixer.Set(0, InputSource::Controller, held);
    mixer.NeutralizeUntilRelease();
    Check(mixer.Consume(0).buttons == 0, "pause clears an unconsumed edge");
    mixer.Set(0, InputSource::Controller, held);
    auto blocked = mixer.Consume(0);
    Check(blocked.connected && blocked.buttons == 0 && blocked.leftY == 0 && blocked.rightTrigger == 0,
          "resume cannot resurrect held buttons, sticks or triggers");
    held.buttons = 0;
    mixer.Set(0, InputSource::Controller, held);
    blocked = mixer.Consume(0);
    Check(blocked.leftY == 0 && blocked.rightTrigger == 0, "button release alone cannot release held analog input");
    PadState idle;
    idle.connected = true;
    mixer.Set(1, InputSource::Touch, idle);
    PadState fresh = idle;
    fresh.buttons = nightpad::kY;
    mixer.Set(1, InputSource::Touch, fresh);
    Check(mixer.Consume(1).buttons == nightpad::kY, "another neutralized port can independently accept a new press");
    mixer.Set(0, InputSource::Controller, idle);
    mixer.Set(0, InputSource::Controller, held);
    blocked = mixer.Consume(0);
    Check(blocked.leftY == held.leftY && blocked.rightTrigger == 255,
          "fresh analog input works after complete release");

    std::cout << (failures == 0 ? "input: PASS" : "input: FAIL") << "\n";
    return failures == 0 ? 0 : 1;
}
