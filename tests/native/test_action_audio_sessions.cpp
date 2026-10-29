#include "action/sound/xaudio2Backend.h"
#include "action/sound/pcmCache.h"
#include "action/devtools/Demo.h"
#include "common/sound/voiceMixer.h"
#include "driving/platform/Ptr32.h"
#include <SDL3/SDL.h>
#include <array>
#include <cstdio>
#include <cstring>

static int failures, missing;
static void Check(bool ok, const char *what) {
    if (!ok) { fprintf(stderr, "FAIL: %s\n", what); ++failures; }
}
// Replay interception is disabled here; playback and PCM ownership use the
// actual backend/cache/mixer and SDL dummy device, with no game or retail data.
void Demo_SoundAnswer(int, DemoSoundQuery, uint32_t *) {}
void DSound_BackendMissing(const char *name) {
    if (missing++ == 0) fprintf(stderr, "backend warning: %s\n", name);
}
int main() {
    constexpr int cycles = 15, perBoot = 192;
    std::array<std::array<unsigned char, 72>, cycles> samples{};
    for (int i = 0; i < cycles; ++i) {
        samples[i][0] = (i + 1) * 13;
        samples[i][36] = (i + 1) * 17;
    }
    WAVEFORMATEX_Xbox format{};
    format.wFormatTag = 0x69;
    format.nChannels = 1;
    format.nSamplesPerSec = 44032;
    format.nBlockAlign = 36;
    format.wBitsPerSample = 4;
    DSBUFFERDESC_Xbox desc{};
    desc.dwSize = sizeof(desc);
    desc.dwFlags = 0x10; // 3D voice, so per-frame work must retain this buffer
    desc.lpwfxFormat = &format;
    const int16_t *previous = nullptr;
    for (int cycle = 0; cycle < cycles; ++cycle) {
        DSoundObject *device = nullptr;
        XA2_DirectSoundCreate(nullptr, &device, nullptr);
        Check(device && XA2_GetDevice(), "real SDL dummy audio device starts");
        Check(!PcmCache_InUse(previous), "new boot releases the previous PCM binding");
        DSoundBuffer *last = nullptr;
        for (int i = 0; i < perBoot; ++i) {
            uint32_t word = 0;
            XA2_IDirectSound_CreateSoundBuffer(device, &desc, &word, nullptr);
            Check(word != 0, "create the game's full boot buffer set");
            last = PtrFrom32<DSoundBuffer>(word);
        }
        size_t values = 0;
        const int16_t *pcm = PcmCache_Decode(samples[cycle].data(), samples[cycle].size(), 1, &values);
        Check(pcm && values > 0 && !PcmCache_InUse(pcm), "decode test-owned ADPCM before binding");
        XA2_IDirectSoundBuffer_SetBufferData(last, samples[cycle].data(), samples[cycle].size());
        Check(PcmCache_InUse(pcm), "the last buffer of every boot protects its PCM");
        XA2_IDirectSoundBuffer_SetPosition(last, 0, 0, 1, 0);
        XA2_IDirectSoundBuffer_Play(last, 0, 0, 1);
        XA2_DirectSoundDoWork();
        SDL_Delay(30);
        uint32_t status = 0;
        XA2_IDirectSoundBuffer_GetStatus(last, &status);
        Check((status & 1) != 0, "last boot buffer plays on the actual mixer");
        VoiceMixer_Report();
        previous = pcm;
    }
    // Creating the next boot's device also releases a still-looping voice.
    DSoundObject *device = nullptr;
    XA2_DirectSoundCreate(nullptr, &device, nullptr);
    Check(!PcmCache_InUse(previous), "reset releases a playing buffer safely");
    VoiceMixer_Report();
    Check(missing == 0, "no buffer registry overflow across fifteen boots");
    printf("action audio sessions: %s; boots=%d buffers=%d warnings=%d\n",
           failures ? "FAIL" : "PASS", cycles, cycles * perBoot, missing);
    return failures ? 1 : 0;
}
