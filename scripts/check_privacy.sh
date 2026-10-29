#!/bin/sh
set -eu

# Private data and retail content must stay out of the repository. This checks
# only what git tracks; ignored build/evidence/vendor trees are expected.
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo"

listed=$(mktemp /tmp/nightpad-tracked.XXXXXX)
cleanup() { rm -f "$listed"; }
trap cleanup EXIT INT TERM
git ls-files > "$listed"

if grep -Eq '^(ref|REF|build|evidence|vendor|references|generated)/' "$listed"; then
    echo "privacy: a private or generated tree is tracked:" >&2
    grep -E '^(ref|REF|build|evidence|vendor|references|generated)/' "$listed" >&2
    exit 1
fi

if grep -Eiq '\.(iso|xbe|iso\.gz|xmv|wav|mp3|ipa|dylib|a|o|app)/?$' "$listed"; then
    echo "privacy: a retail or binary artefact is tracked:" >&2
    grep -Ei '\.(iso|xbe|iso\.gz|xmv|wav|mp3|ipa|dylib|a|o|app)/?$' "$listed" >&2
    exit 1
fi

for ignored in /ref/ /REF/ /build/ /evidence/ /vendor/ /references/ /generated/; do
    if ! grep -qx "$ignored" .gitignore; then
        echo "privacy: .gitignore does not exclude $ignored" >&2
        exit 1
    fi
done

while IFS= read -r file; do
    size=$(wc -c < "$file" | tr -d ' ')
    if [ "$size" -gt 1048576 ]; then
        echo "privacy: $file is $size bytes; large files need review" >&2
        exit 1
    fi
done < "$listed"

# The app must not gain a network path by accident. About-page links open in
# the user's browser; nothing in the app talks to a server.
if git grep -nEi 'URLSession|NSURLConnection|CFStream|NWConnection|getaddrinfo|socket\(' -- apple > /tmp/nightpad-network.txt 2>/dev/null; then
    echo "privacy: networking API found in apple/:" >&2
    cat /tmp/nightpad-network.txt >&2
    rm -f /tmp/nightpad-network.txt
    exit 1
fi
rm -f /tmp/nightpad-network.txt

count=$(wc -l < "$listed" | tr -d ' ')
echo "privacy: PASS ($count tracked source files; no retail, binary or private trees; no network APIs in the app)"
