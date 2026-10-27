#include "../../apple/shared/NightPadControllerSlots.h"

#include <iostream>

using nightpad::ControllerSlots;

static int failures = 0;
static void Check(bool value, const char *what) {
    if (!value) {
        std::cerr << "FAIL: " << what << "\n";
        ++failures;
    }
}

int main() {
    ControllerSlots slots;

    auto first = slots.Reconcile({0x1000});
    Check(first.assigned.size() == 1 && first.assigned[0].slot == 0, "first controller takes player 1");
    Check(slots.SlotFor(0x1000) == 0, "first controller keeps its slot");

    auto second = slots.Reconcile({0x1000, 0x2000});
    Check(second.assigned.size() == 1 && second.assigned[0].slot == 1, "second controller takes player 2");
    Check(slots.SlotFor(0x1000) == 0 && slots.SlotFor(0x2000) == 1, "both slots stable");

    // Foreground resume with the same enumeration must not reshuffle.
    auto same = slots.Reconcile({0x1000, 0x2000});
    Check(same.assigned.empty() && same.removed.empty(), "unchanged enumeration is stable");

    // Losing player two leaves a hole; it is not compacted under player one.
    auto lost = slots.Reconcile({0x1000});
    Check(lost.removed.size() == 1 && lost.removed[0].slot == 1 && lost.removed[0].instance == 0x2000,
          "removed controller reports its slot");
    Check(slots.SlotFor(0x2000) == -1 && slots.SlotFor(0x1000) == 0, "surviving slot is untouched");

    // A new controller fills the free slot rather than stealing player one.
    auto rejoin = slots.Reconcile({0x1000, 0x3000});
    Check(rejoin.assigned.size() == 1 && rejoin.assigned[0].slot == 1, "new controller fills the free slot");

    // A sole returning controller reclaims player one after everyone left.
    slots.Reconcile({});
    Check(slots.InstanceIn(0) == 0 && slots.SlotFor(0x1000) == -1, "all slots released");
    auto sole = slots.Reconcile({0x4000});
    Check(sole.assigned.size() == 1 && sole.assigned[0].slot == 0, "sole controller reclaims player 1");

    // Duplicates and capacity limits.
    auto dupes = slots.Reconcile({0x4000, 0x4000, 0x5000, 0x6000, 0x7000, 0x8000});
    Check(dupes.assigned.size() == 3, "duplicates ignored and capacity capped at four");
    Check(slots.InstanceIn(3) == 0x7000, "fourth slot assigned");
    Check(slots.SlotFor(0x8000) == -1, "fifth controller has no slot");

    slots.Clear();
    Check(slots.InstanceIn(0) == 0 && slots.InstanceIn(3) == 0, "clear releases every slot");

    std::cout << (failures == 0 ? "controller slots: PASS" : "controller slots: FAIL") << "\n";
    return failures == 0 ? 0 : 1;
}
