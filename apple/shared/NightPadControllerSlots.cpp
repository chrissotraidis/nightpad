#include "NightPadControllerSlots.h"

#include <algorithm>

namespace nightpad {

ControllerReconcileResult ControllerSlots::Reconcile(const std::vector<uintptr_t> &current_instances) {
    std::vector<uintptr_t> current;
    current.reserve(current_instances.size());
    for (uintptr_t instance : current_instances) {
        if (instance != 0 && std::find(current.begin(), current.end(), instance) == current.end())
            current.push_back(instance);
    }

    ControllerReconcileResult result;
    for (std::size_t slot = 0; slot < slots_.size(); ++slot) {
        const uintptr_t instance = slots_[slot];
        if (instance != 0 && std::find(current.begin(), current.end(), instance) == current.end()) {
            result.removed.push_back({instance, slot});
            slots_[slot] = 0;
        }
    }

    for (uintptr_t instance : current) {
        if (SlotFor(instance) >= 0)
            continue;
        auto freeSlot = std::find(slots_.begin(), slots_.end(), 0);
        if (freeSlot == slots_.end())
            continue;
        const std::size_t slot = static_cast<std::size_t>(freeSlot - slots_.begin());
        slots_[slot] = instance;
        result.assigned.push_back({instance, slot});
    }
    return result;
}

int ControllerSlots::SlotFor(uintptr_t instance) const {
    if (instance == 0)
        return -1;
    for (std::size_t slot = 0; slot < slots_.size(); ++slot)
        if (slots_[slot] == instance)
            return static_cast<int>(slot);
    return -1;
}

void ControllerSlots::Clear() {
    std::fill(slots_.begin(), slots_.end(), 0);
}

}  // namespace nightpad
