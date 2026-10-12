#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
VERSION=$(cat VERSION)
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'Invalid VERSION.' >&2; exit 1; }
NAME="brlaser-hl2270dw-macos-$VERSION"
[[ -f build/rastertobrlaser ]] || { echo 'Build and test first.' >&2; exit 1; }
[[ ! -e "dist/$NAME" ]] || { echo "dist/$NAME already exists; move it before rebuilding." >&2; exit 1; }
# Build the shipped source from the committed tree, not the working copy, so the
# archive never leaks gitignored secrets or untracked files and stays traceable (M2).
[[ -z "$(git status --porcelain)" ]] || { echo 'Working tree is dirty. Commit or stash changes first.' >&2; exit 1; }
COMMIT=$(git rev-parse HEAD)
mkdir -p "dist/$NAME/build"
# Extract the source for this commit into the staging dir (prefix stripped so it
# lands under dist/$NAME), then overlay the freshly built binary artifacts.
git archive --format=tar --prefix="$NAME/" "$COMMIT" | tar -x -C dist
printf 'version=%s\ncommit=%s\n' "$VERSION" "$COMMIT" > "dist/$NAME/BUILD-INFO"
cp build/rastertobrlaser build/Brother-HL2270DW-brlaser-arm64.ppd "dist/$NAME/build/"
# Include all corresponding source and installation/build scripts in the binary archive.
COPYFILE_DISABLE=1 tar --uid 0 --gid 0 --uname root --gname wheel -czf "dist/$NAME.tar.gz" -C dist "$NAME"
(cd dist && shasum -a 256 "$NAME.tar.gz" > SHA256SUMS)
echo "Release: dist/$NAME.tar.gz (binary + full source @ $COMMIT + scripts + licenses)"
