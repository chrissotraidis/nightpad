#include "common/fmv/FmvAudio.h"
#include <SDL3/SDL.h>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <vector>

static void Check(bool ok, const char *what) {
    if (!ok) { fprintf(stderr, "FAIL: %s\n", what); exit(1); }
}
static double virtualTime;
static double VirtualClock() { return virtualTime; }
static void Queue(FmvAudio &audio, int samples) {
    std::vector<int16_t> pcm(samples * 2, 100);
    uint8_t *data[] = { reinterpret_cast<uint8_t *>(pcm.data()) };
    AVFrame frame{};
    frame.format = AV_SAMPLE_FMT_S16;
    frame.ch_layout.nb_channels = 2;
    frame.nb_samples = samples;
    frame.extended_data = data;
    audio.Queue(&frame);
}
static void Frozen(FmvAudio &audio) {
    audio.SetPaused(true);
    double at = audio.Clock();
    SDL_Delay(100);
    audio.SetPaused(true); // idempotent; must not reset the resume origin
    Check(audio.Clock() == at, "paused clock is frozen");
    audio.SetPaused(false);
    Check(std::fabs(audio.Clock() - at) < 0.03, "resume excludes paused wall time");
    SDL_Delay(60);
    Check(audio.Clock() > at + 0.025, "clock advances after resume");
}

int main() {
    Check(SDL_Init(SDL_INIT_AUDIO), SDL_GetError());
    FmvAudio audio;
    // A failed/missing audio device must still provide a pausable wall clock.
    Check(!audio.Open(0, 2, 48000, nullptr, 2), "silent device has no voice");
    audio.SetPaused(true);
    audio.Start();
    SDL_Delay(50);
    Check(audio.Clock() == 0.0, "pause before start does not advance");
    audio.SetPaused(false);
    SDL_Delay(40);
    Frozen(audio);
    audio.Close();

    // Deterministic replay clock, including completion and a pause before Start.
    FmvAudio::SetVirtualClock(VirtualClock);
    virtualTime = 20.0;
    Check(audio.Open(0, 2, 48000, nullptr, 2), "virtual voice opens without a device");
    Queue(audio, 48000);
    audio.Finish();
    audio.SetPaused(true);
    virtualTime = 30.0;
    audio.Start();
    virtualTime = 40.0;
    Check(audio.Clock() == 0.0 && !audio.PlayedOut(), "virtual clock starts paused");
    audio.SetPaused(false);
    virtualTime += 0.25;
    Check(audio.Clock() == 0.25, "virtual resume origin is preserved");
    audio.SetPaused(true);
    virtualTime += 100.0;
    Check(audio.Clock() == 0.25 && !audio.PlayedOut(), "virtual completion cannot pass during pause");
    audio.SetPaused(false);
    virtualTime += 0.75;
    Check(audio.Clock() == 1.0 && audio.PlayedOut(), "virtual movie finishes at original duration");
    audio.Close();
    FmvAudio::SetVirtualClock(nullptr);

    SDL_AudioSpec spec{SDL_AUDIO_S16, 2, 48000};
    auto device = SDL_OpenAudioDevice(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &spec);
    Check(device != 0, SDL_GetError());
    // Another voice on the same device must keep playing when this movie pauses.
    auto other = SDL_CreateAudioStream(&spec, &spec);
    std::vector<int16_t> otherPcm(48000 * 2 * 3, 50);
    Check(other && SDL_PutAudioStreamData(other, otherPcm.data(), otherPcm.size() * sizeof(int16_t)) &&
          SDL_BindAudioStream(device, other), "independent device voice");
    Check(audio.Open(device, 2, 48000, nullptr, 2), "SDL movie voice opens");
    Queue(audio, 48000);
    audio.Finish();
    audio.Start();
    SDL_Delay(80);
    audio.SetPaused(true);
    auto queued = audio.QueuedSeconds();
    int otherQueued = SDL_GetAudioStreamQueued(other);
    SDL_Delay(150);
    Check(audio.QueuedSeconds() == queued, "paused SDL voice retains queued samples");
    Check(SDL_GetAudioStreamQueued(other) < otherQueued, "pausing a movie does not pause another voice");
    audio.SetPaused(false);
    Frozen(audio);
    // Once audio drains, the continuing wall clock must also exclude pauses.
    for (int i = 0; i < 300 && !audio.PlayedOut(); ++i) SDL_Delay(10);
    Check(audio.PlayedOut(), "short movie voice drains");
    (void)audio.Clock();
    Frozen(audio);
    audio.SetPaused(true);
    audio.Close(); // cleanup while paused must release safely and reset state
    Check(!audio.Open(0, 2, 48000, nullptr, 2), "silent reopen after paused cleanup");
    audio.Start();
    SDL_Delay(40);
    Check(audio.Clock() > 0.02, "close resets pause state");
    audio.Close();
    SDL_DestroyAudioStream(other);
    SDL_CloseAudioDevice(device);
    SDL_Quit();
    puts("FMV audio pause: PASS (silent, virtual, queued, drained, independent voice, cleanup)");
}
