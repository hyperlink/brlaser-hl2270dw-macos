#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
mkdir -p build/tests
for name in lest line block job; do
  sources=()
  case "$name" in
    line) sources=(vendor/brlaser/src/line.cc) ;;
    job) sources=(vendor/brlaser/src/job.cc vendor/brlaser/src/line.cc) ;;
  esac
  clang++ -std=c++11 -O2 "vendor/brlaser/test/test_$name.cc" ${sources[@]+"${sources[@]}"} -o "build/tests/test_$name"
  "build/tests/test_$name"
  echo "PASS: upstream test_$name"
done
cupstestppd -I filters build/Brother-HL2270DW-brlaser-arm64.ppd
file build/rastertobrlaser | grep -q 'arm64'
otool -L build/rastertobrlaser
clang++ -std=c++11 tests/raster_fixture.cc -lcups -o build/tests/raster_fixture
for resolution in 600 1200; do
  build/tests/raster_fixture "$resolution" > "build/tests/$resolution.raster"
  build/rastertobrlaser 1 test resolution-test 1 '' "build/tests/$resolution.raster" \
    > "build/tests/$resolution.prn" 2> "build/tests/$resolution.log"
  grep -q 'PAGE: 1 1' "build/tests/$resolution.log"
done
LC_ALL=C grep -aq '@PJL SET RAS1200MODE = TRUE' build/tests/1200.prn
LC_ALL=C grep -aq '@PJL SET RAS1200MODE = FALSE' build/tests/600.prn
echo 'PASS: HQ1200 enabled at 1200 DPI, disabled at 600 DPI.'
echo 'Unit tests do not replace a physical test print.'
