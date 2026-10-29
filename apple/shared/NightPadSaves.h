#ifndef NIGHTPAD_SAVES_H_
#define NIGHTPAD_SAVES_H_

#include <filesystem>
#include <string>

namespace nightpad {

// The game writes saves into a relative "saves" folder under its launch
// directory. Point that folder at NightPad's durable saves directory so a new
// game-data import or a rebuilt launch state cannot strand a campaign.
//
// Returns false when a real "saves" directory already exists in the launch
// state: its contents belong to the player and must be moved deliberately
// rather than replaced.
bool EnsureSavesLink(const std::filesystem::path &launchState, const std::filesystem::path &saves,
                     std::string *error);

}  // namespace nightpad

#endif  // NIGHTPAD_SAVES_H_
