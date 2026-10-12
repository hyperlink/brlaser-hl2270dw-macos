#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail
export COPYFILE_DISABLE=1
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
VERSION=$(cat VERSION)
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'Invalid VERSION (expected N.N.N).' >&2; exit 2; }
UNSIGNED=false
if [[ $# == 1 && "$1" == --unsigned-for-testing ]]; then
  UNSIGNED=true
elif [[ $# != 2 || "$1" != 'Developer ID Application: '* || "$2" != 'Developer ID Installer: '* ]]; then
  echo "Usage: $0 'Developer ID Application: NAME (TEAM)' 'Developer ID Installer: NAME (TEAM)'" >&2
  echo "Local packaging test only: $0 --unsigned-for-testing" >&2
  exit 2
fi
[[ -f build/rastertobrlaser ]] || { echo 'Run build.sh and test.sh first.' >&2; exit 1; }
# Build the shipped source from a commit, not the dirty working tree (M2):
# refuse to run with uncommitted changes so the archive never leaks gitignored
# secrets (*.p12, *.p8, *.key) or untracked files, and stays reproducible.
[[ -z "$(git status --porcelain)" ]] || { echo 'Working tree is dirty. Commit or stash changes first.' >&2; exit 1; }
COMMIT=$(git rev-parse HEAD)
STAGE=$(mktemp -d /private/tmp/brlaser-pkg-stage.XXXXXX)
# Keep the component package and distribution artifacts out of the payload root:
# pkgbuild --root scoops up anything under STAGE, so component.pkg (and its temp
# build files) must live in a separate directory (P2).
BUILDDIR=$(mktemp -d /private/tmp/brlaser-pkg-build.XXXXXX)
trap 'rm -rf "$STAGE" "$BUILDDIR"' EXIT
DRIVER="$STAGE/Library/Printers/brlaser-hl2270dw"
mkdir -p "$DRIVER" "$STAGE/Library/Printers/PPDs/Contents/Resources" dist
cp build/rastertobrlaser "$DRIVER/"
cp build/Brother-HL2270DW-brlaser-arm64.ppd "$STAGE/Library/Printers/PPDs/Contents/Resources/brlaser-hl2270dw-macos.ppd"
cp LICENSE NOTICE.md "$DRIVER/"
# Ship an uninstaller in the payload so pkg users can cleanly remove the driver
# and forget the receipt (M4).
cp scripts/uninstall.sh "$DRIVER/uninstall.sh"
# Full corresponding source travels inside the installer itself, built from the
# committed tree at HEAD (never the working copy) and gzip -n for reproducibility (M2).
git archive --format=tar --prefix="brlaser-hl2270dw-macos-$VERSION/" "$COMMIT" | gzip -n > "$DRIVER/Source.tar.gz"
# Record the commit the shipped source corresponds to.
printf 'version=%s\ncommit=%s\n' "$VERSION" "$COMMIT" > "$DRIVER/BUILD-INFO"
chmod 755 "$DRIVER/rastertobrlaser" "$DRIVER/uninstall.sh"
find "$STAGE" -type d -exec chmod 755 {} +
find "$STAGE" -type f ! -name rastertobrlaser ! -name uninstall.sh -exec chmod 644 {} +
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
# Build an unsigned component package, then wrap it in a product archive that gates
# host architecture (arm64) and minimum OS (11.0) so the dead arm64 driver cannot
# install on Intel or pre-11 Macs, and shows the GPL in Installer (M1). The signed,
# notarizable artifact is the productbuild output.
pkgbuild --root "$STAGE" --filter '(^|/)\._' --ownership recommended --install-location / \
  --identifier io.github.hyperlink.brlaser.hl2270dw --version "$VERSION" \
  "$BUILDDIR/component.pkg"
mkdir -p "$BUILDDIR/res"
cp LICENSE "$BUILDDIR/res/LICENSE"
cat > "$BUILDDIR/distribution.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
  <title>brlaser for Brother HL-2270DW</title>
  <options customize="never" require-scripts="false" hostArchitectures="arm64"/>
  <allowed-os-versions><os-version min="11.0"/></allowed-os-versions>
  <license file="LICENSE"/>
  <choices-outline><line choice="default"><line choice="drv"/></line></choices-outline>
  <choice id="default"/>
  <choice id="drv" visible="false"><pkg-ref id="io.github.hyperlink.brlaser.hl2270dw"/></choice>
  <pkg-ref id="io.github.hyperlink.brlaser.hl2270dw" version="$VERSION">component.pkg</pkg-ref>
</installer-gui-script>
EOF
productbuild --distribution "$BUILDDIR/distribution.xml" --package-path "$BUILDDIR" \
  --resources "$BUILDDIR/res" ${SIGN_ARGS[@]+"${SIGN_ARGS[@]}"} "$OUT"
if ! $UNSIGNED; then pkgutil --check-signature "$OUT"; fi
echo "Created $OUT. This package installs driver files only; add the printer in macOS settings."
echo 'It is NOT notarized yet. Do not describe it as notarized until acceptance and stapling succeed.'
