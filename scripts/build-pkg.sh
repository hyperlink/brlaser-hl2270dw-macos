#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail
export COPYFILE_DISABLE=1
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
VERSION=$(cat VERSION)
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || exit 2
UNSIGNED=false
if [[ $# == 1 && "$1" == --unsigned-for-testing ]]; then
  UNSIGNED=true
elif [[ $# != 2 || "$1" != 'Developer ID Application: '* || "$2" != 'Developer ID Installer: '* ]]; then
  echo "Usage: $0 'Developer ID Application: NAME (TEAM)' 'Developer ID Installer: NAME (TEAM)'" >&2
  echo "Local packaging test only: $0 --unsigned-for-testing" >&2
  exit 2
fi
[[ -f build/rastertobrlaser ]] || { echo 'Run build.sh and test.sh first.' >&2; exit 1; }
STAGE=$(mktemp -d /private/tmp/brlaser-pkg-stage.XXXXXX)
trap 'rm -rf "$STAGE"' EXIT
DRIVER="$STAGE/Library/Printers/brlaser-hl2270dw"
mkdir -p "$DRIVER" "$STAGE/Library/Printers/PPDs/Contents/Resources" dist
cp build/rastertobrlaser "$DRIVER/"
cp build/Brother-HL2270DW-brlaser-arm64.ppd "$STAGE/Library/Printers/PPDs/Contents/Resources/brlaser-hl2270dw-macos.ppd"
cp LICENSE NOTICE.md "$DRIVER/"
# Full corresponding source travels inside the installer itself.
COPYFILE_DISABLE=1 tar --uid 0 --gid 0 --uname root --gname wheel -czf "$DRIVER/Source.tar.gz" \
  scripts vendor tests README.md LICENSE NOTICE.md LEGAL.md TESTING.md SIGNING.md VERSION
chmod 755 "$DRIVER/rastertobrlaser"
find "$STAGE" -type d -exec chmod 755 {} +
find "$STAGE" -type f ! -name rastertobrlaser -exec chmod 644 {} +
xattr -cr "$STAGE"
SIGN_ARGS=()
SUFFIX=''
if $UNSIGNED; then
  SUFFIX=-UNSIGNED-TEST
else
  codesign --force --options runtime --timestamp --sign "$1" "$DRIVER/rastertobrlaser"
  codesign --verify --strict --verbose "$DRIVER/rastertobrlaser"
  SIGN_ARGS=(--sign "$2" --timestamp)
fi
OUT="dist/brlaser-hl2270dw-macos-$VERSION$SUFFIX.pkg"
[[ ! -e "$OUT" ]] || { echo "Refusing to replace $OUT" >&2; exit 1; }
pkgbuild --root "$STAGE" --filter '(^|/)\._' --ownership recommended --install-location / \
  --identifier io.github.hyperlink.brlaser.hl2270dw --version "$VERSION" \
  ${SIGN_ARGS[@]+"${SIGN_ARGS[@]}"} "$OUT"
if ! $UNSIGNED; then pkgutil --check-signature "$OUT"; fi
echo "Created $OUT. This package installs driver files only; add the printer in macOS settings."
echo 'It is NOT notarized yet. Do not describe it as notarized until acceptance and stapling succeed.'
