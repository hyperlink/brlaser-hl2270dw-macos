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
mkdir -p "dist/$NAME/build"
cp -R scripts vendor tests "dist/$NAME/"
cp README.md LICENSE NOTICE.md LEGAL.md TESTING.md VERSION "dist/$NAME/"
cp build/rastertobrlaser build/Brother-HL2270DW-brlaser-arm64.ppd "dist/$NAME/build/"
# Include all corresponding source and installation/build scripts in the binary archive.
COPYFILE_DISABLE=1 tar --uid 0 --gid 0 --uname root --gname wheel -czf "dist/$NAME.tar.gz" -C dist "$NAME"
(cd dist && shasum -a 256 "$NAME.tar.gz" > SHA256SUMS)
echo "Release: dist/$NAME.tar.gz (binary + full source + scripts + licenses)"
