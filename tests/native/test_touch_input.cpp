#include "../../apple/shared/NightPadTouchInput.h"

#include <iostream>
#include <vector>

using nightpad::PadState;
using nightpad::TouchControl;
using nightpad::TouchControlId;
using nightpad::TouchDeviceClass;
using nightpad::TouchLayout;
using nightpad::TouchPoint;

static int failures = 0;
static void Check(bool value, const char *what) {
    if (!value) {
        std::cerr << "FAIL: " << what << "\n";
        ++failures;
    }
}

static const TouchControl &Control(const TouchLayout &layout, TouchControlId id) {
    for (const auto &control : layout.controls)
        if (control.id == id)
            return control;
    static TouchControl missing{};
    return missing;
}

static TouchPoint At(const TouchLayout &layout, TouchControlId id, float fx, float fy, int finger = 1) {
    const auto &control = Control(layout, id);
    return {finger, control.x + control.width * fx, control.y + control.height * fy};
}

static PadState With(const TouchLayout &layout, std::vector<TouchPoint> points) {
    return nightpad::TouchPadState(layout, points.data(), points.size());
}

int main() {
    const TouchLayout phone = TouchLayout::Defaults(TouchDeviceClass::Phone);
    const TouchLayout tablet = TouchLayout::Defaults(TouchDeviceClass::Tablet);

    PadState idle = With(phone, {});
    Check(idle.buttons == 0 && idle.leftX == 0 && idle.leftY == 0 && idle.rightX == 0 && idle.rightY == 0 &&
              idle.leftTrigger == 0 && idle.rightTrigger == 0,
          "no fingers is neutral");
    Check(idle.connected, "touch is an always-present source");

    // Sticks: full deflection at the edge, Y up positive.
    PadState right = With(phone, { At(phone, TouchControlId::LeftStick, 1.0f, 0.5f) });
    Check(right.leftX > 32000 && right.leftY == 0, "left stick right is full X");
    PadState upLeft = With(phone, { At(phone, TouchControlId::LeftStick, 0.0f, 0.0f) });
    Check(upLeft.leftX < -20000 && upLeft.leftY > 20000, "left stick up-left is negative X and positive Y");
    PadState centre = With(phone, { At(phone, TouchControlId::LeftStick, 0.5f, 0.5f) });
    Check(centre.leftX == 0 && centre.leftY == 0, "stick centre is inside the dead zone");

    // Four fingers: move, look, fire and full trigger at the same time.
    PadState combat = With(phone, {
        At(phone, TouchControlId::LeftStick, 0.85f, 0.5f, 1),
        At(phone, TouchControlId::RightStick, 0.2f, 0.15f, 2),
        At(phone, TouchControlId::A, 0.5f, 0.5f, 3),
        At(phone, TouchControlId::RightTrigger, 0.5f, 1.0f, 4),
    });
    Check(combat.leftX > 20000, "simultaneous move");
    Check(combat.rightX < 0 && combat.rightY > 0, "simultaneous look");
    Check((combat.buttons & nightpad::kA) != 0, "simultaneous fire");
    Check(combat.rightTrigger > 240, "simultaneous full trigger");
    // Triggers stay analog: no digital button bit is set for them.
    Check(combat.buttons == nightpad::kA, "only the pressed face button sets a digital bit");

    // D-pad is eight-way with a centre dead zone.
    PadState dpadDiag = With(phone, { At(phone, TouchControlId::Dpad, 0.95f, 0.05f) });
    Check((dpadDiag.buttons & (nightpad::kDpadUp | nightpad::kDpadRight)) ==
              (nightpad::kDpadUp | nightpad::kDpadRight),
          "d-pad diagonal");
    PadState dpadCentre = With(phone, { At(phone, TouchControlId::Dpad, 0.5f, 0.5f) });
    Check((dpadCentre.buttons & (nightpad::kDpadUp | nightpad::kDpadDown | nightpad::kDpadLeft |
                                 nightpad::kDpadRight)) == 0,
          "d-pad centre is neutral");

    // Analog trigger ramps with depth and releases on lift.
    PadState light = With(phone, { At(phone, TouchControlId::LeftTrigger, 0.5f, 0.05f) });
    PadState deep = With(phone, { At(phone, TouchControlId::LeftTrigger, 0.5f, 1.0f) });
    Check(light.leftTrigger >= 20 && light.leftTrigger < 90, "trigger light press is low");
    Check(deep.leftTrigger > 240, "trigger bottom edge is full");
    Check(deep.leftTrigger > light.leftTrigger, "trigger ramps with depth");
    Check(With(phone, {}).leftTrigger == 0, "trigger releases with the finger");

    // Shoulders and system buttons map to their Xbox names.
    PadState shoulders = With(phone, { At(phone, TouchControlId::White, 0.5f, 0.5f, 1),
                                       At(phone, TouchControlId::Black, 0.5f, 0.5f, 2),
                                       At(phone, TouchControlId::Start, 0.5f, 0.5f, 3),
                                       At(phone, TouchControlId::Back, 0.5f, 0.5f, 4) });
    Check((shoulders.buttons & (nightpad::kWhite | nightpad::kBlack | nightpad::kStart | nightpad::kBack)) ==
              (nightpad::kWhite | nightpad::kBlack | nightpad::kStart | nightpad::kBack),
          "LB/RB and Start/Back bits");

    // Newest finger owns a control when two share it.
    PadState newest = With(phone, { At(phone, TouchControlId::LeftStick, 0.0f, 0.5f, 1),
                                    At(phone, TouchControlId::LeftStick, 1.0f, 0.5f, 7) });
    Check(newest.leftX > 32000, "newest finger wins inside one control");

    // Hidden controls take no input; tablet geometry works the same.
    TouchLayout hidden = phone;
    for (auto &control : hidden.controls)
        if (control.id == TouchControlId::B)
            control.visible = false;
    Check((With(hidden, { At(phone, TouchControlId::B, 0.5f, 0.5f) }).buttons & nightpad::kB) == 0,
          "hidden control is inert");
    PadState tabletStick = With(tablet, { At(tablet, TouchControlId::RightStick, 0.5f, 0.0f) });
    Check(tabletStick.rightY > 20000, "tablet right stick up");

    // Five simultaneous touches, the stress case from the goal packet.
    PadState five = With(phone, {
        At(phone, TouchControlId::LeftStick, 0.9f, 0.5f, 1),
        At(phone, TouchControlId::RightStick, 0.5f, 0.1f, 2),
        At(phone, TouchControlId::A, 0.5f, 0.5f, 3),
        At(phone, TouchControlId::X, 0.5f, 0.5f, 4),
        At(phone, TouchControlId::LeftTrigger, 0.5f, 1.0f, 5),
    });
    Check(five.leftX > 20000 && five.rightY > 20000 && (five.buttons & nightpad::kA) &&
              (five.buttons & nightpad::kX) && five.leftTrigger > 240,
          "five simultaneous touches");

    // Capture: a thumb that started on a stick keeps it past the stick's edge.
    auto index = [&](const TouchLayout &layout, TouchControlId id) {
        for (std::size_t c = 0; c < layout.controls.size(); ++c)
            if (layout.controls[c].id == id)
                return static_cast<int>(c);
        return -1;
    };
    const auto &left = Control(phone, TouchControlId::LeftStick);
    TouchPoint drifted{1, left.x + left.width * 1.6f, left.y + left.height * 0.5f,
                       index(phone, TouchControlId::LeftStick)};
    PadState held = With(phone, { drifted });
    Check(held.leftX > 32000, "a captured stick keeps full deflection outside its edge");
    TouchPoint uncaptured = drifted;
    uncaptured.control = -1;
    Check(With(phone, { uncaptured }).leftX == 0, "without capture the same point is outside the stick");

    // Floating centre: landing off-centre is neutral; movement is measured from the landing point.
    TouchPoint landed = At(phone, TouchControlId::RightStick, 0.85f, 0.5f);
    landed.control = index(phone, TouchControlId::RightStick);
    landed.originX = landed.x;
    landed.originY = landed.y;
    Check(With(phone, { landed }).rightX == 0, "a stick is neutral where the thumb lands");
    TouchPoint moved = landed;
    moved.x -= Control(phone, TouchControlId::RightStick).width * 0.5f;
    Check(With(phone, { moved }).rightX < -32000, "deflection is measured from the landing point");

    // A finger that began on a button cannot take a stick over by sliding onto it.
    TouchPoint slid = At(phone, TouchControlId::LeftStick, 0.9f, 0.5f);
    slid.control = index(phone, TouchControlId::A);
    Check(With(phone, { slid }).leftX == 0, "a slide from a button does not move the stick");

    // A captured trigger pulled past its bottom edge stays at full travel.
    TouchPoint pulled = At(phone, TouchControlId::RightTrigger, 0.5f, 3.0f);
    pulled.control = index(phone, TouchControlId::RightTrigger);
    Check(With(phone, { pulled }).rightTrigger == 255, "captured trigger saturates past its edge");
    Check(nightpad::TouchControlAt(phone, left.x + left.width * 0.5f, left.y + left.height * 0.5f) ==
              index(phone, TouchControlId::LeftStick),
          "control lookup by point");

    std::cout << (failures == 0 ? "touch input: PASS" : "touch input: FAIL") << "\n";
    return failures == 0 ? 0 : 1;
}
