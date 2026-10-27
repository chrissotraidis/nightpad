#ifndef NIGHTPAD_CONTROLLER_SLOTS_H_
#define NIGHTPAD_CONTROLLER_SLOTS_H_

#include <cstddef>
#include <cstdint>
#include <vector>

namespace nightpad {

struct ControllerSlotChange {
    uintptr_t instance = 0;
    std::size_t slot = 0;
};

struct ControllerReconcileResult {
    std::vector<ControllerSlotChange> removed;
    std::vector<ControllerSlotChange> assigned;
};

// Session-local player slots for Apple's GameController objects. GCController's
// own list remains the connection authority; an object's address is only a
// process-local identity for matching and logging. A returning controller takes
// the first free slot, so a sole controller reclaims player 1, while a
// controller that stays connected keeps its slot through foreground resume.
class ControllerSlots {
public:
    static constexpr std::size_t kMaxPlayers = 4;

    ControllerReconcileResult Reconcile(const std::vector<uintptr_t> &current_instances);
    int SlotFor(uintptr_t instance) const;
    uintptr_t InstanceIn(std::size_t slot) const { return slot < slots_.size() ? slots_[slot] : 0; }
    void Clear();

private:
    std::vector<uintptr_t> slots_ = std::vector<uintptr_t>(kMaxPlayers, 0);
};

}  // namespace nightpad

#endif  // NIGHTPAD_CONTROLLER_SLOTS_H_
