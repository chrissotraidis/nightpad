#include "common/sound/voiceMixer.h"
#include "common/fmv/FmvAudio.h"
#include <SDL3/SDL.h>
#include <atomic>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <limits>
#include <vector>

static std::atomic<float> peak{0};
static std::atomic<unsigned> callbacks{0};
static void Check(bool ok, const char *what) {
    if (!ok) { fprintf(stderr, "FAIL: %s (%s)\n", what, SDL_GetError()); exit(1); }
}
static void SDLCALL Capture(void *, const SDL_AudioSpec *, float *samples, int bytes) {
    float high = 0;
    for (int i = 0; i < bytes / (int)sizeof(float); ++i)
        high = std::fmax(high, std::fabs(samples[i]));
    float previous = peak.load();
    while (previous < high && !peak.compare_exchange_weak(previous, high)) {}
    callbacks.fetch_add(1);
}
static void Output(float expected, const char *what) {
    SDL_Delay(80); // drain blocks already submitted at the previous volume
    peak.store(0);
    callbacks.store(0);
    SDL_Delay(100);
    const float observed = peak.load();
    printf("%s: peak=%.6f expected=%.6f callbacks=%u\n", what, observed, expected, callbacks.load());
    Check(callbacks.load() > 0 && std::fabs(observed - expected) < 0.002f, what);
}
int main() {
    Check(VoiceMixer_SetMasterVolume(0.5f), "volume accepted before device exists");
    Check(VoiceMixer_Start(), "actual mixer starts");
    auto device = VoiceMixer_Device();
    Check(SDL_GetAudioDeviceGain(device) == 0.5f, "pre-boot volume reaches device");
    Check(SDL_SetAudioPostmixCallback(device, Capture, nullptr), "capture final PCM");
    std::vector<int16_t> pcm(48000, 8192); // constant 0.25 at original amplitude
    auto voice = VoiceMixer_CreateVoice(48000, 1, 1, 2, 16);
    Check(voice != nullptr, "game voice exists");
    VoiceMixer_SetData(voice, pcm.data(), pcm.size() * sizeof(int16_t));
    VoiceMixer_SetGains(voice, 1.0f, 0.5f);
    VoiceMixer_SetVolume(voice, 0.5f); // game's own setting remains multiplicative
    VoiceMixer_Play(voice, true);
    Output(0.0625f, "game voice at half master");
    Check(VoiceMixer_SetMasterVolume(1.0f), "restore original master");
    Output(0.125f, "game voice keeps original per-voice volume");

    FmvAudio movie;
    Check(movie.Open(device, 2, 48000, nullptr, 2), "movie shares mixer device");
    std::vector<int16_t> moviePcm(48000 * 2 * 8, 8192);
    uint8_t *data[] = {reinterpret_cast<uint8_t *>(moviePcm.data())};
    AVFrame frame{};
    frame.format = AV_SAMPLE_FMT_S16;
    frame.ch_layout.nb_channels = 2;
    frame.nb_samples = moviePcm.size() / 2;
    frame.extended_data = data;
    movie.Queue(&frame);
    movie.SetVolume(0.4f);
    movie.Start();
    Output(0.225f, "game plus movie keep their own mix");
    Check(VoiceMixer_SetMasterVolume(0.5f), "change combined master live");
    Output(0.1125f, "master attenuates game and movie together");
    Check(VoiceMixer_SetMasterVolume(0.0f), "mute combined output");
    double before = movie.Clock();
    Output(0.0f, "muted output is silent");
    Check(VoiceMixer_IsPlaying(voice) && movie.Clock() > before + 0.05,
          "mute does not pause playback or movie clock");
    for (float invalid : {-0.1f, 1.1f, std::numeric_limits<float>::infinity(),
                          std::numeric_limits<float>::quiet_NaN()})
        Check(!VoiceMixer_SetMasterVolume(invalid), "invalid volume rejected");
    Check(SDL_GetAudioDeviceGain(device) == 0.0f, "invalid volume leaves mute intact");
    Check(VoiceMixer_SetMasterVolume(1.0f), "unmute");
    Output(0.225f, "unmute restores combined output");
    movie.SetPaused(true);
    Output(0.125f, "native movie pause remains independent of master");
    movie.Close();
    VoiceMixer_Release(voice);
    Check(VoiceMixer_SetMasterVolume(0.25f) && VoiceMixer_Start(), "session restart retains volume");
    voice = VoiceMixer_CreateVoice(48000, 1, 1, 2, 16);
    VoiceMixer_SetData(voice, pcm.data(), pcm.size() * sizeof(int16_t));
    VoiceMixer_SetGains(voice, 1.0f, 1.0f);
    VoiceMixer_Play(voice, true);
    Output(0.0625f, "new session voice inherits master only once");
    VoiceMixer_Release(voice);
    SDL_SetAudioPostmixCallback(device, nullptr, nullptr);
    puts("master volume: PASS (pre-boot, game, movie, live, mute, clock, invalid, new session)");
}
