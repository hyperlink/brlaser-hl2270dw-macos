# HL-2270DW HQ1200 printing on Apple silicon

An unofficial macOS build and installer for [Peter De Wachter's brlaser](https://github.com/pdewacht/brlaser), restoring **HQ1200** printing on the **Brother HL-2270DW** on Apple silicon Macs.

This project adds a native ARM64 build, a model-specific CUPS PPD, install/remove scripts, and source-complete release packaging. It is not an official Brother driver.

HQ1200 is Brother's high-quality mode (a 1200 × 1200 raster sent with `RAS1200MODE = TRUE`, `RESOLUTION = 600`), not native 1200 DPI optics. The queue offers 300 DPI, 600 DPI, and HQ1200 (default).

## Tested

- HL-2270DW over network on an Apple silicon Mac, macOS 27.0.1, Letter / single-sided / HQ1200.
- One physical HQ1200 test page confirmed correct. The migrated Intel Brother filter failed with `Bad CPU type in executable`; the ARM64 brlaser filter printed fine.
- Other models, USB, duplex, older macOS, and installing a downloaded `.pkg` on a clean Mac are untested. See [TESTING.md](TESTING.md).

## Install the signed .pkg (recommended)

1. Download `brlaser-hl2270dw-macos-0.1.2.pkg` from [v0.1.2](https://github.com/hyperlink/brlaser-hl2270dw-macos/releases/tag/v0.1.2). The installer is Developer ID signed (identity **Geneir Solutions**); see [TESTING.md](TESTING.md) for the signing and notarization status of each release.
2. Open it and follow the Installer prompts.
3. In **System Settings > Printers & Scanners**, add your HL-2270DW. Under **Use > Select Software**, choose **Brother HL-2270DW series, using brlaser v6 (Apple silicon HQ1200)**.
4. Pick HQ1200 and your paper size in the print dialog, then print.

The package installs driver files only. It does not create a queue or change your default printer. Complete source ships at `/Library/Printers/brlaser-hl2270dw/Source.tar.gz` and is also attached to the release.

## Build from source

Requires an Apple silicon Mac, Apple's Command Line Tools (`xcode-select --install`), and the macOS `ppdc`/`cupstestppd` utilities (used by `build.sh` and `test.sh`). No Homebrew or Rosetta needed; builds link only to macOS system libraries.

```sh
git clone https://github.com/hyperlink/brlaser-hl2270dw-macos.git
cd brlaser-hl2270dw-macos
./scripts/build.sh
./scripts/test.sh
sudo ./scripts/install.sh --copy-uri-from YOUR_EXISTING_QUEUE
```

Run `lpstat -v` to find your existing queue name. Add `--dry-run` to preview, `--uri 'socket://IP:9100'` for an explicit address, or `--paper A4` for A4 (Letter is default). The installer creates a separate queue, leaves your existing queue and default printer unchanged, and refuses to overwrite a queue (use `--queue Another_Name`).

## Remove

Script install:

```sh
sudo ./scripts/uninstall.sh Brother_HL_2270DW_HQ1200
```

Package install (ships its own uninstaller; pass the real name of the queue you created — the script refuses if you name a queue that doesn't match or if another queue still uses the driver):

```sh
sudo /Library/Printers/brlaser-hl2270dw/uninstall.sh YOUR_QUEUE_NAME
```

If you never created a queue, run it with any placeholder name to remove the driver files and the package receipt only.

Removal deletes the queue and driver files (when no other queue uses them). It does not restore a previous default printer.

## Troubleshooting

- **No output:** check `lpstat -p`, `lpstat -o`, printer power/network, and the queue URI.
- **HQ1200 missing:** confirm the new queue is selected (not Generic PCL or the migrated Brother queue). Resolution may be under Printer Features.
- **Bad CPU type:** confirm the queue uses the ARM64 driver — `file /Library/Printers/brlaser-hl2270dw/rastertobrlaser` should report `arm64`.
- **Queue already exists:** use a new `--queue` name.

When reporting problems, include macOS version, chip, connection type, and selected resolution. Scrub usernames, document names, serial numbers, network addresses, and passwords from logs first.

## License and credit

brlaser is © 2013 Peter De Wachter and contributors under **GPL-2.0-or-later**; packaging additions use the same license. See [LICENSE](LICENSE), [NOTICE.md](NOTICE.md), and [LEGAL.md](LEGAL.md).

Brother is a trademark of Brother Industries, Ltd. This independent community project is not affiliated with Brother or Apple, and comes with no warranty.

## Creating a release

See [SIGNING.md](SIGNING.md) for Developer ID signing and notarization. After building, testing, and reviewing [TESTING.md](TESTING.md), run `./scripts/package.sh` and publish the archive with `SHA256SUMS`. Always keep matching source available for every binary release.
