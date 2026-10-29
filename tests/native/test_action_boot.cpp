#include "action/game.h"
#include "action/engine/XboxSystem.h"
#include "action/engine/LaunchOptions.h"
#include <array>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <unistd.h>

extern uint32_t ResetMap_State;
static int failures;
static void Check(bool ok, const char *what) {
    if (!ok) { fprintf(stderr, "FAIL: %s\n", what); ++failures; }
}
static void WritePage(const std::array<unsigned char, 3072> &page) {
    FILE *file = fopen("psiLaunch.bin", "wb");
    Check(file && fwrite(page.data(), 1, page.size(), file) == page.size(), "write isolated handover");
    if (file) fclose(file);
}
static void CheckPage(const std::array<unsigned char, 3072> &page, const char *what) {
    void *actual = GetPTPData();
    Check(actual && memcmp(actual, page.data(), page.size()) == 0, what);
}
int main() {
    char root[] = "/tmp/nightpad-action-boot.XXXXXX";
    Check(mkdtemp(root) && chdir(root) == 0, "isolated launch state");
    if (failures) return 1;
    LaunchOptions_SetFromText("");
    GameFlow_ResetForBoot();
    Check(GetPTPData() == nullptr, "initial boot has no handover");
    // A stop can leave the loader at any phase, including AFTER_MOVIE. A new
    // boot must load the title normally rather than finish the previous movie.
    for (unsigned phase = 1; phase <= 4; ++phase) {
        ResetMap_State = phase;
        GameFlow_PushState(GAMEFLOW_MOVIE, 0, 0);
        GameFlow_ResetForBoot();
        Check(GameFlow_GetState() == GAMEFLOW_BOOT && ResetMap_State == 0,
              "new boot discards interrupted loader and flow phases");
    }
    std::array<unsigned char, 3072> first{}, second{};
    for (size_t i = 0; i < first.size(); ++i) { first[i] = i * 17 + 3; second[i] = i * 29 + 5; }
    WritePage(first);
    GameFlow_ResetForBoot();
    CheckPage(first, "handover after an initial boot reads new page");
    WritePage(second);
    CheckPage(first, "handover remains stable within one boot");
    GameFlow_ResetForBoot();
    CheckPage(second, "next handover replaces cached page");
    LaunchOptions_SetFromText("-level CastleExterior");
    GameFlow_ResetForBoot();
    Check(GetPTPData() == nullptr, "direct level boot ignores handover");
    LaunchOptions_SetFromText("");
    GameFlow_ResetForBoot();
    CheckPage(second, "handover works again after direct level boot");
    unlink("psiLaunch.bin");
    GameFlow_ResetForBoot();
    Check(GetPTPData() == nullptr && GetPTPData_Copy() == nullptr,
          "fresh boot cannot reuse deleted handover");
    Check(rmdir(root) == 0, "remove empty test directory");
    printf("action boot reset: %s\n", failures ? "FAIL" : "PASS");
    return failures ? 1 : 0;
}
