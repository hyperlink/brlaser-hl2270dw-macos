#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
QUEUE=Brother_HL_2270DW_HQ1200
PAPER=Letter
URI=''
COPY_FROM=''
DRY_RUN=false
usage() {
  echo "Usage: sudo $0 (--uri DEVICE_URI | --copy-uri-from EXISTING_QUEUE) [--queue NAME] [--paper Letter|A4] [--dry-run]"
}
while [[ $# -gt 0 ]]; do
  case "$1" in
    --uri|--copy-uri-from|--queue|--paper)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      case "$1" in
        --uri) URI=$2 ;; --copy-uri-from) COPY_FROM=$2 ;; --queue) QUEUE=$2 ;; --paper) PAPER=$2 ;;
      esac
      shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
[[ $(uname -s) == Darwin && $(/usr/sbin/sysctl -n hw.optional.arm64 2>/dev/null) == 1 ]] || { echo 'Requires an Apple silicon Mac.' >&2; exit 1; }
[[ "$QUEUE" =~ ^[A-Za-z0-9_][A-Za-z0-9_-]*$ ]] || { echo 'Invalid queue name.' >&2; exit 2; }
[[ "$PAPER" == Letter || "$PAPER" == A4 ]] || { echo 'Paper must be Letter or A4.' >&2; exit 2; }
if [[ -n "$COPY_FROM" ]]; then
  [[ -z "$URI" ]] || { echo 'Choose only one URI option.' >&2; exit 2; }
  [[ "$COPY_FROM" =~ ^[A-Za-z0-9_][A-Za-z0-9_-]*$ ]] || { echo 'Invalid source queue name.' >&2; exit 2; }
  LINE=$(LC_ALL=C /usr/bin/lpstat -v "$COPY_FROM")
  PREFIX="device for $COPY_FROM: "
  [[ "$LINE" == "$PREFIX"* ]] || { echo 'Could not read the source queue URI.' >&2; exit 1; }
  URI=${LINE#"$PREFIX"}
fi
case "$URI" in
  socket://*|dnssd://*|lpd://*|ipp://*|ipps://*|usb://*) ;;
  *) echo 'Provide a supported CUPS device URI. Run lpstat -v to list existing printers.' >&2; exit 2 ;;
esac
[[ "$URI" != *$'\n'* && "$URI" != *$'\r'* && "$URI" != *'@'* ]] || { echo 'Control characters and credentials in URIs are not supported.' >&2; exit 2; }
[[ -f "$ROOT/build/rastertobrlaser" && -f "$ROOT/build/Brother-HL2270DW-brlaser-arm64.ppd" ]] || { echo 'Build first with ./scripts/build.sh or use the full release archive.' >&2; exit 1; }
[[ $(/usr/bin/lipo -archs "$ROOT/build/rastertobrlaser") == *arm64* ]] || { echo 'Built filter is not arm64.' >&2; exit 1; }
/usr/bin/codesign --verify "$ROOT/build/rastertobrlaser"
if /usr/bin/lpstat -p "$QUEUE" >/dev/null 2>&1; then
  echo "Queue $QUEUE already exists. Choose a new --queue name; existing queues are never overwritten." >&2
  exit 1
fi
echo "New queue: $QUEUE; paper: $PAPER; resolution: HQ1200"
echo "Device URI: $URI"
if $DRY_RUN; then echo 'Dry run: no changes made.'; exit 0; fi
[[ $EUID -eq 0 ]] || { echo 'Run with sudo to install into /Library/Printers.' >&2; exit 1; }
/usr/bin/install -d -o root -g wheel -m 755 /Library/Printers/brlaser-hl2270dw
/usr/bin/install -o root -g wheel -m 755 "$ROOT/build/rastertobrlaser" /Library/Printers/brlaser-hl2270dw/rastertobrlaser
/usr/bin/install -o root -g wheel -m 644 "$ROOT/build/Brother-HL2270DW-brlaser-arm64.ppd" /Library/Printers/PPDs/Contents/Resources/brlaser-hl2270dw-macos.ppd
/usr/sbin/lpadmin -p "$QUEUE" -E -v "$URI" -P /Library/Printers/PPDs/Contents/Resources/brlaser-hl2270dw-macos.ppd \
  -D "Brother HL-2270DW HQ1200" -o printer-is-shared=false -o "Resolution=1200dpi" -o "PageSize=$PAPER"
echo "Installed. Select Brother HL-2270DW HQ1200 in your print dialog and print a test page."
echo 'The previous queue and default printer were not changed.'
