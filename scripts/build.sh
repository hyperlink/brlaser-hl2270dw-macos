#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
[[ $(uname -s) == Darwin && $(uname -m) == arm64 ]] || { echo 'Build on an Apple silicon Mac.' >&2; exit 1; }
xcrun --find clang++ >/dev/null
mkdir -p build/ppd
printf '#define PACKAGE "brlaser"\n#define VERSION "6"\n' > build/config.h
clang++ -std=c++11 -O2 -arch arm64 -mmacosx-version-min=11.0 \
  -fstack-protector-strong -D_FORTIFY_SOURCE=2 -Ibuild \
  vendor/brlaser/src/{main,job,line,debug}.cc -lcups -o build/rastertobrlaser
codesign --force --sign - build/rastertobrlaser
sed -e 's/@CMAKE_PROJECT_NAME@/brlaser/g' -e 's/@BRLASER_VERSION@/6/g' \
  -e 's|33 rastertobrlaser|33 /Library/Printers/brlaser-hl2270dw/rastertobrlaser|' \
  vendor/brlaser/brlaser.drv.in > build/brlaser.drv
ppdc -d build/ppd build/brlaser.drv
sed -e 's/DefaultResolution: 600dpi/DefaultResolution: 1200dpi/' \
  -e 's/1200dpi\/1200HQ/1200dpi\/HQ1200/' \
  -e 's/DefaultPageSize: A4/DefaultPageSize: Letter/' \
  -e 's/DefaultPageRegion: A4/DefaultPageRegion: Letter/' \
  -e 's/DefaultPaperDimension: A4/DefaultPaperDimension: Letter/' \
  -e 's/DefaultImageableArea: A4/DefaultImageableArea: Letter/' \
  -e 's/using brlaser v6/using brlaser v6 (Apple silicon HQ1200)/' \
  build/ppd/br2270dw.ppd > build/Brother-HL2270DW-brlaser-arm64.ppd
cupstestppd -I filters build/Brother-HL2270DW-brlaser-arm64.ppd
codesign --verify --verbose build/rastertobrlaser
echo 'Built ARM64 filter and HQ1200 PPD in build/.'
