#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail
QUEUE=${1:-Brother_HL_2270DW_HQ1200}
[[ $# -le 1 && "$QUEUE" =~ ^[A-Za-z0-9_][A-Za-z0-9_-]*$ ]] || { echo "Usage: sudo $0 [QUEUE_NAME]" >&2; exit 2; }
[[ $EUID -eq 0 ]] || { echo 'Run with sudo.' >&2; exit 1; }
FILTER=/Library/Printers/brlaser-hl2270dw/rastertobrlaser
PPD="/etc/cups/ppd/$QUEUE.ppd"
if [[ -f "$PPD" ]]; then
  grep -Fq "$FILTER" "$PPD" || { echo 'Refusing to remove a queue using a different driver.' >&2; exit 1; }
  /usr/sbin/lpadmin -x "$QUEUE"
fi
for other in /etc/cups/ppd/*.ppd; do
  [[ -f "$other" ]] || continue
  if grep -Fq "$FILTER" "$other"; then
    echo 'Removed the selected queue; retained driver files because another queue uses them.'
    exit 0
  fi
done
rm -f "$FILTER" /Library/Printers/PPDs/Contents/Resources/brlaser-hl2270dw-macos.ppd
rm -f /Library/Printers/brlaser-hl2270dw/Source.tar.gz /Library/Printers/brlaser-hl2270dw/LICENSE /Library/Printers/brlaser-hl2270dw/NOTICE.md
if [[ -d /Library/Printers/brlaser-hl2270dw ]]; then rmdir /Library/Printers/brlaser-hl2270dw; fi
echo 'Removed this project’s queue and driver files. Other printer drivers were not removed.'
