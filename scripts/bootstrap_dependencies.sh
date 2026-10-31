#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fetch_pin() {
    path=$1
    url=$2
    revision=$3
    mkdir -p "$repo/$path"
    if [ ! -d "$repo/$path/.git" ]; then
        git -C "$repo/$path" init -q
        git -C "$repo/$path" remote add origin "$url"
    fi
    git -C "$repo/$path" fetch --depth 1 origin "$revision"
    git -C "$repo/$path" checkout -q --detach FETCH_HEAD
    test "$(git -C "$repo/$path" rev-parse HEAD)" = "$revision"
}

fetch_pin vendor/nightfire https://github.com/NightfireResearch/nightfire-cxbx.git 8779cf79ff623b83b53b9acf9c0b0cd6639b75ab
fetch_pin references/galaxypad https://github.com/chrissotraidis/galaxypad.git 4db10c4c11e35958aae8da23b4d80fe6e5fe88e3
fetch_pin references/sunpad https://github.com/chrissotraidis/sunpad.git d40a0674afa7189c14bfd6ce6f099dd275b46397
fetch_pin tools/extract-xiso https://github.com/XboxDev/extract-xiso.git 3f5b62cfe68f000b0e3c8a30104973f3a297948e

git -C "$repo/vendor/nightfire" submodule update --init --depth 1 third_party/ffmpeg
test "$(git -C "$repo/vendor/nightfire/third_party/ffmpeg" rev-parse HEAD)" = 8ae0b34901ba60a802f183ee75a250a9fc3e09a5

# Only the numbered engine patches belong to Nightfire. The SDL patch is applied
# to the configured SDL source by scripts/patch_ios_sdl.sh. Later patches touch
# lines from earlier ones, so apply the series to a clean tree and otherwise
# prove that the existing tree matches it.
if [ -z "$(git -C "$repo/vendor/nightfire" status --porcelain --untracked-files=no)" ]; then
    for patch in "$repo"/patches/00*.patch; do
        git -C "$repo/vendor/nightfire" apply "$patch"
    done
else
    "$repo/scripts/verify_patches.sh"
fi

cmake -S "$repo/tools/extract-xiso" -B "$repo/tools/extract-xiso/build" -DCMAKE_BUILD_TYPE=Release
cmake --build "$repo/tools/extract-xiso/build" -j 4
echo "Dependencies are pinned. SDL and SPIRV-Cross are fetched at configure time by Nightfire's CMake build."

