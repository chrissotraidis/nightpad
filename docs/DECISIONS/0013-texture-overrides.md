# Decision 0013: external texture overrides are deferred

Date: 2026-10-27

## Decision

NightPad does not ship a texture-override feature in this candidate. The
engine's DDS replacement mechanism is real but belongs to the D3D9 backend,
which this port does not compile, and there is no Xbox texture-pack scene to
consume it. A bounded SDL/Metal version is possible and its shape is recorded
below, but it is not part of the private candidate.

## Inventory of Xbox-compatible mods

- The public Nightfire modding scene is aimed at the PC, PS2 and Dolphin
  builds. The well-known tools (the BSP decompiler, GearCraft and the editor
  suites) and HD texture work target those versions; no packaged Xbox texture
  pack or injector is published.
- Xbox reverse engineering is still in progress upstream: the
  `filesys.dxx` archives are not fully unpacked, and the project's own advice
  is to dump files from a running game through Cxbx rather than to edit the
  disc.
- Save/profile edits and the game's own Secret Unlocks are the only
  Xbox-compatible customisation that exists in a form NightPad can consume, and
  NightPad keeps those with the original front end.

External references, all community material and none of it a requirement:
<https://github.com/NightfireResearch/nightfire-re> (extraction state),
<https://gamebanana.com/tools/games/2569> (tool list, PC/Dolphin oriented) and
<https://www.moddb.com/games/james-bond-007-nightfire/downloads/nightfire-bsp-decompiler>
(a PC tool). A search of the public scene found no Xbox texture injector.

## Why the engine's replacement cannot simply be switched on

`src/common/gfx/textureReplace.cpp` hashes each uploaded texture and loads
`textures/<hash>.dds` in its place, and `tools/texture_replacement.py` converts
dumps to PNGs and back. But it works on D3D9 textures, and the SDL GPU backend
says so at the top of `sdlGpuBackend.cpp`: texture replacement and texture
dumps are "not carried over from d3d9Backend.cpp".

That is what the tree shows as well. The action target compiles
`sdlGpuBackend.cpp` and not `d3d9Backend.cpp`, the built binary exports no
`TextureReplace` symbols, and a headless run with `DumpTextures=1` produced no
`textures_dump` folder and no replacement log line - the setting is inert on
this backend.

## The bounded prototype, if it is ever wanted

1. Give `sdlGpuBackend.cpp` a texture-creation hook that computes the same FNV
   hash over the game's source bytes and asks for `textures/<hash>.dds`.
2. Reuse the DDS parser and format table from `textureReplace.cpp`, creating an
   `SDL_GPUTexture` at the replacement's size and chain.
3. Keep the game's header size and format for coordinates, as the D3D9 path
   does, so a larger replacement only adds detail.
4. Validate headlessly: dump the frames with and without a replacement and
   compare the pixels, then confirm the same page on a device.

## Consequences

- The product does not advertise texture mods and no settings surface mentions
  them.
- R21 is decided: inventory complete, prototype deferred with the plan above.
