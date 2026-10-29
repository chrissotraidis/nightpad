#include "action/ui/ui.h"
#include "action/ui/Menu.h"
#include "action/engine/LoadSave.h"
#include "action/game/Upgrade.h"
#include <array>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <string>
#include <sys/wait.h>
#include <unistd.h>

extern uint64_t Menu_SpecialCodenameCheck(byte *code);
extern uint8_t mp_explosive_scenery_unlocked;
static unsigned checks;
static void Check(bool ok, const char *what) {
    ++checks;
    if (!ok) { std::fprintf(stderr, "secret unlocks: FAIL: %s\n", what); std::exit(1); }
}
static std::string Read(const std::filesystem::path &path) {
    std::ifstream file(path, std::ios::binary);
    return {std::istreambuf_iterator<char>(file), {}};
}
static void Reset(uint missions = 3, uint32_t lo = 0, uint32_t hi = 0) {
    Menu_SetNightfireStatus(missions);
    Menu_SetBonus(lo, hi, 0, 0);
}
static void Apply(const char *code) {
    Check(Menu_SpecialCodenameCheck((byte *)code) == 1, "recognized original secret");
}
static void CheckUpgrades() {
    const std::array<uchar, 9> expected{3, 1, 1, 2, 1, 1, 1, 1, 1};
    Check(std::memcmp(Upgrades[0], expected.data(), expected.size()) == 0,
          "complete weapon/gadget upgrade levels");
    Check(Menu_GetObjectUpgradeLevel(UPGRADE_BIT_HANDGUN, 0) == 3,
          "dossier reports highest pistol upgrade");
    Check(Menu_GetObjectUpgradeLevel(UPGRADE_BIT_SNIPER, 0) == 2,
          "dossier reports both sniper upgrades");
    Check(Upgrade_Weapon(6) == 8 && Upgrade_Weapon(0x4a) == 0x4c &&
          Upgrade_MPWeapon(0, 80) == 81, "gameplay selects upgraded weapons and gadget");
}
static void CheckMenus() {
    Menu_UnlockMPSkins(0);
    for (unsigned skin = 12; skin < 29; ++skin)
        Check(ITEM_ENABLED(mp_characters[skin]) && ITEM_ENABLED(mp_characters_small[skin]),
              "reward character opens in player and bot selectors");
    Menu_UnlockMPSettings();
    for (unsigned scenario : {4, 6, 7, 9, 10, 12})
        Check(ITEM_ENABLED(mp_scenario[scenario]), "reward scenario opens in setup menu");
    Check(!mp_explosive_scenery_unlocked, "scenario set does not grant separate scenery modifier");
}
static void Save(const char *name) {
    LS_FlushStates();
    uint state = 0;
    for (unsigned i = 0; i < 32 && state != LS_STATE_DONE && state != LS_STATE_FAILED; ++i)
        state = LS_Save((char *)name, 0, SAVE_ALL);
    Check(state == LS_STATE_DONE, "production whole-profile save completes");
}
static void Load(const char *name) {
    LS_FlushStates();
    uint state = 0;
    for (unsigned i = 0; i < 32 && state != LS_STATE_DONE && state != LS_STATE_FAILED; ++i)
        state = LS_Load((char *)name, 0, SAVE_ALL);
    Check(state == LS_STATE_DONE, "production whole-profile load completes");
}
int main(int argc, char **argv) {
    const auto executable = std::filesystem::absolute(argv[0]);
    if (argc == 3 && std::strcmp(argv[1], "--reload") == 0) {
        Check(chdir(argv[2]) == 0, "fresh process enters isolated save root");
        Reset();
        Load("UNLOCKS");
        Check(Menu_GetNightfireStatus() == 0xfff, "all missions survive process relaunch");
        Check((Menu_GetBonus(0) >> 32) == 0x3fffefc0,
              "character and scenario rewards survive process relaunch");
        CheckUpgrades();
        CheckMenus();
        std::printf("secret unlocks: fresh-process load PASS (%u checks)\n", checks);
        return 0;
    }
    char root[] = "/tmp/nightpad-secret-unlocks.XXXXXX";
    Check(mkdtemp(root) && chdir(root) == 0, "isolated disposable save root");
    std::filesystem::create_directory("saves");
    Reset();
    Save("OTHER");
    const auto unrelated = Read("saves/OTHER.dat");
    Menu_SetBonus(1, 0x80, 1, 0);
    const uint64_t playerOne = Menu_GetBonus(1);

    // Invalid input must preserve progress, reward ownership and upgrades.
    Reset(0x103, 1, 0x80);
    const auto unchangedBonus = Menu_GetBonus(0);
    std::array<uchar, 9> unchangedUpgrades;
    std::memcpy(unchangedUpgrades.data(), Upgrades[0], unchangedUpgrades.size());
    for (const char *invalid : {"", "INVALID", "passport", "PASSPORT ", "PART"}) {
        Check(Menu_SpecialCodenameCheck((byte *)invalid) == 0, "invalid input rejected");
        Check(Menu_GetNightfireStatus() == 0x103 && Menu_GetBonus(0) == unchangedBonus &&
              std::memcmp(Upgrades[0], unchangedUpgrades.data(), unchangedUpgrades.size()) == 0,
              "invalid secret has no side effects");
    }
    Apply("PASSPORT");
    Check(Menu_GetNightfireStatus() == 0xfff && Menu_GetBonus(0) == unchangedBonus,
          "all-mission family preserves rewards");
    Reset();
    Apply("POWDER");
    Check(Menu_GetNightfireStatus() == 7, "mission toggle opens one additional mission");
    Apply("POWDER");
    Check(Menu_GetNightfireStatus() == 3, "second mission toggle restores original mask");
    Reset(4);
    Apply("POWDER");
    Check(Menu_GetNightfireStatus() == 3, "closing final mission restores initial choices");

    Reset(3, 1, 0x40000000);
    Apply("PARTY");
    Check(Menu_GetBonus(0) == 0x40ffefc000000001ull,
          "character set preserves existing scenario and upgrade rewards");
    Apply("GAMEROOM");
    Check(Menu_GetBonus(0) == 0x7fffefc000000001ull, "scenario set combines with character set");
    const auto rewardSet = Menu_GetBonus(0);
    Apply("PARTY"); Apply("GAMEROOM");
    Check(Menu_GetBonus(0) == rewardSet, "reward-set family is idempotent");
    Reset(3, 1, 0x80);
    Apply("BOWLER");
    Check(Menu_GetBonus(0) == 0xc000000001ull, "single character toggles without losing other rewards");
    Menu_UnlockMPSkins(0);
    Check(ITEM_ENABLED(mp_characters[BOT_ODDJOB]) &&
          ITEM_ENABLED(mp_characters_small[BOT_ODDJOB]), "single character opens both selectors");
    Apply("BOWLER");
    Check(Menu_GetBonus(0) == 0x8000000001ull, "single character toggles back");
    Menu_UnlockMPSkins(0);
    Check(!ITEM_ENABLED(mp_characters[BOT_ODDJOB]) &&
          !ITEM_ENABLED(mp_characters_small[BOT_ODDJOB]), "removed reward closes both selectors");
    Apply("TARGET"); Apply("TARGET");
    Check(Menu_GetBonus(0) == 0x8000000001ull, "single scenario toggles back");
    Apply("BOOM");
    Menu_UnlockMPSettings();
    Check(mp_explosive_scenery_unlocked, "separate modifier opens explosive scenery");
    Apply("BOOM");
    Menu_UnlockMPSettings();
    Check(!mp_explosive_scenery_unlocked, "second modifier toggle closes explosive scenery");

    Reset();
    for (const auto &[code, expected] : std::array<std::pair<const char *, unsigned>, 3>{
             {{"AU PP7", 1}, {"P2000", 2}, {"AU P2K", 3}}}) {
        Apply(code);
        Check(Upgrades[0][WUG_Handgun] == expected, "incremental pistol upgrade");
    }
    Reset();
    Apply("Q LAB");
    CheckUpgrades();
    const auto upgrades = Menu_GetBonus(0);
    Apply("Q LAB");
    Check(Menu_GetBonus(0) == upgrades, "upgrade family never awards duplicate levels");
    Check(Menu_GetBonus(1) == playerOne && Upgrades[1][WUG_Handgun] == 1,
          "editing player zero preserves another player's rewards/upgrades");

    Apply("PASSPORT"); Apply("PARTY"); Apply("GAMEROOM");
    CheckMenus();
    Save("UNLOCKS");
    const auto first = Read("saves/UNLOCKS.dat");
    Check(first.size() == 166, "whole profile retains the original six-block size");
    Reset();
    Load("UNLOCKS");
    Check(Menu_GetNightfireStatus() == 0xfff && (Menu_GetBonus(0) >> 32) == 0x3fffefc0,
          "loaded profile restores all unlock families");
    CheckUpgrades();
    CheckMenus();
    Save("UNLOCKS");
    Check(Read("saves/UNLOCKS.dat") == first && Read("saves/UNLOCKS.dat.bak") == first,
          "unchanged save round trip and previous-copy backup are exact");
    Check(Read("saves/OTHER.dat") == unrelated, "unrelated codename is untouched");
    const pid_t child = fork();
    Check(child >= 0, "fork fresh-process reload");
    if (child == 0) {
        execl(executable.c_str(), executable.c_str(), "--reload", root, (char *)nullptr);
        _exit(127);
    }
    int status = 0;
    Check(waitpid(child, &status, 0) == child && WIFEXITED(status) && WEXITSTATUS(status) == 0,
          "new process reconstructs unlocks from saved profile");
    std::printf("secret unlocks: five families/save/relaunch PASS (%u checks); %s\n", checks, root);
    return 0;
}
