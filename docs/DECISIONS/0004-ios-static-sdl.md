# Decision 0004: static SDL on iOS

Date: 2026-10-27

## Decision

Link the pinned SDL3 release statically into the iPhoneOS engine builds. Keep
the existing shared-library build for macOS and the other desktop hosts.

## Why

The first iOS proof inherited the desktop choice to build SDL as a dylib. That
left `libSDL3.0.dylib` loose inside each app and made the combined engine link
depend on `@rpath`. An ordinary signed iOS app should carry executable code in
its main binary or a correctly embedded framework; a stale loose dylib is not an
acceptable release shape and can mask missing static dependencies.

SDL's own iOS build already supports a static archive. The product needs that
archive to be one owned copy of SDL, shared by both isolated engine objects and
the Apple shell.

## Evidence

- The pinned engine reconfigured SDL with `SDL_SHARED=OFF` and
  `SDL_STATIC=ON`.
- The complete action and driving iPhoneOS app targets build and link against
  `libSDL3.a`.
- The combined action/driving executable links with the static archive and no
  `libSDL3.0.dylib` dependency.
- The app-bundle copies still hold a stale dylib until manually removed; a clean
  build must prove no dylib is emitted.
- The combined link is Mach-O arm64 iOS and has four engine bridge exports.

## Limits

The standalone target bundles still carry their own duplicated SDL static code.
The combined product must link one SDL instance, not one per isolated engine.
That remains part of the single-app coordinator work. The current standalone
apps are also unsigned and have not been installed.

## Next experiment

Build the combined host and isolated engines into one clean `.app`, confirm
there are no nested dylibs, and launch both engine entrypoints from the same
static SDL instance under the coordinator.

