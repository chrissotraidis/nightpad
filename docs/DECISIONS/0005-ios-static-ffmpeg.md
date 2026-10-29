# Decision 0005: static FFmpeg on iOS

Date: 2026-10-27

## Decision

Use the pinned FFmpeg source as static arm64 libraries on iOS and bind the
existing movie API directly to the codec, demuxer and utility symbols. Keep the
desktop dynamic-loading path unchanged.

## Evidence

- The existing pinned FFmpeg configuration built static arm64 libraries for
  both device and simulator with XMV, WMV2, Xbox IMA ADPCM, WAV IMA ADPCM, EAMAD
  and EA R1 enabled.
- The simulator media probe decoded one WMV2 video packet and one Xbox ADPCM
  audio packet from the owner-supplied XMV file.
- The complete iPhoneOS action and driving targets now link their three static
  FFmpeg archives while retaining an empty dynamic-library list.
- The combined isolated-engine link also includes those three archives and
  still links to an arm64 iOS executable with four bridge exports.

## Limits

The static engine path has not run on a physical device or decoded movie audio
through either engine's production player. The engine binaries are unsigned.
The static FFmpeg notices and the exact configuration must be included in the
final package manifest.

## Next experiment

Run the movie and audio fixtures through the combined engine build on the iOS
simulator where supported, then repeat on a signed physical device with an
interruption and audio-route change.

