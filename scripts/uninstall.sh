#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail
QUEUE=${1:-Brother_HL_2270DW_HQ1200}
[[ $# -le 1 && "$QUEUE" =~ ^[A-Za-z0-9_][A-Za-z0-9_-]*$ ]] || { echo "Usage: sudo $0 [QUEUE_NAME]" >&2; exit 2; }
[[ $EUID -eq 0 ]] || { echo 'Run with sudo.' >&2; exit 1; }
FILTER=/Library/Printers/brlaser-hl2270dw/rastertobrlaser
PKG_ID=io.github.hyperlink.brlaser.hl2270dw
PPD="/etc/cups/ppd/$QUEUE.ppd"
REMOVED_QUEUE=false
if [[ -f "$PPD" ]]; then
  grep -Fq "$FILTER" "$PPD" || { echo 'Refusing to remove a queue using a different driver.' >&2; exit 1; }
  /usr/sbin/lpadmin -x "$QUEUE"
  REMOVED_QUEUE=true
elif /usr/bin/lpstat -p "$QUEUE" >/dev/null 2>&1; then
  echo "Queue $QUEUE exists but has no matching PPD for this driver; not touching it." >&2
  exit 1
else
  echo "Queue $QUEUE not found; checking driver files only." >&2
fi
for other in /etc/cups/ppd/*.ppd; do
  [[ -f "$other" ]] || continue
  if grep -Fq "$FILTER" "$other"; then
    if $REMOVED_QUEUE; then
      echo 'Removed the selected queue; retained driver files because another queue uses them.'
      exit 0
    fi
    echo "Another queue still uses this driver; retained driver files. Queue $QUEUE was not removed." >&2
    exit 1
  fi
done
rm -f "$FILTER" /Library/Printers/PPDs/Contents/Resources/brlaser-hl2270dw-macos.ppd
rm -f /Library/Printers/brlaser-hl2270dw/Source.tar.gz /Library/Printers/brlaser-hl2270dw/LICENSE \
  /Library/Printers/brlaser-hl2270dw/NOTICE.md /Library/Printers/brlaser-hl2270dw/uninstall.sh \
  /Library/Printers/brlaser-hl2270dw/BUILD-INFO
if [[ -d /Library/Printers/brlaser-hl2270dw ]]; then
  rmdir /Library/Printers/brlaser-hl2270dw 2>/dev/null || echo 'Left /Library/Printers/brlaser-hl2270dw (not empty).'
fi
# Forget the pkg receipt so pkgutil no longer reports the driver as installed (M4).
if /usr/sbin/pkgutil --pkg-info "$PKG_ID" >/dev/null 2>&1; then
  /usr/sbin/pkgutil --forget "$PKG_ID"
fi
if $REMOVED_QUEUE; then
  echo "Removed this project's queue and driver files. Other printer drivers were not removed."
else
  echo "Removed this project's driver files. Queue $QUEUE was not found."
fi
