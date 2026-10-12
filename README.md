# HL-2270DW HQ1200 printing on Apple silicon

An unofficial macOS build and installer for [Peter De Wachter's brlaser](https://github.com/pdewacht/brlaser), focused on restoring **HQ1200** printing on the **Brother HL-2270DW** after migrating from an Intel Mac to Apple silicon.

The printer driver and high-resolution support come from brlaser. This project provides a native ARM64 build, a model-specific CUPS PPD, installation/removal scripts, and source-complete release packaging. It is not an official Brother driver or a new implementation of the printing protocol.

## What has been tested

- Brother HL-2270DW over a network, on an Apple silicon Mac running macOS 27.0.1.
- One physical HQ1200 test page, confirmed by its owner to have correct small text and fine lines.
- The original migrated Brother Intel filter failed with `Bad CPU type in executable`; the ARM64 brlaser filter printed successfully.
- Letter paper, single-sided, HQ1200; see [TESTING.md](TESTING.md) for limits and packaging validation.

HQ1200 is Brother's high-quality mode, not a claim of native 1200 × 1200 optical resolution. brlaser accepts a 1200 × 1200 raster and sends `RAS1200MODE = TRUE` with `RESOLUTION = 600`, following its upstream implementation. The queue offers 300 DPI, 600 DPI, and HQ1200. HQ1200 is the default.

Other models, USB connections, duplex, and older macOS releases have not been physically tested by this project. The code targets macOS 11 or newer, but that deployment target is not a compatibility guarantee. CUPS/PPD printing must still be available on the installed macOS version.

## Install a release

1. Download `brlaser-hl2270dw-macos-0.1.0.tar.gz` and `SHA256SUMS` from [Releases](https://github.com/hyperlink/brlaser-hl2270dw-macos/releases). The archive contains the ARM64 executable **and all its corresponding source**.
2. In Terminal, change to the download folder, verify the checksum, and extract:

   ```sh
   shasum -a 256 -c SHA256SUMS
   tar -xzf brlaser-hl2270dw-macos-0.1.0.tar.gz
   cd brlaser-hl2270dw-macos-0.1.0
   ```

3. Run `lpstat -v` to find your existing printer's queue name. For example, if it says `device for Brother_HL_2270DW_series: ...`, preview and install with:

   ```sh
   ./scripts/install.sh --copy-uri-from Brother_HL_2270DW_series --dry-run
   sudo ./scripts/install.sh --copy-uri-from Brother_HL_2270DW_series
   ```

   Substitute your own existing queue name. Alternatively supply an explicit printer address:

   ```sh
   sudo ./scripts/install.sh --uri 'socket://YOUR_PRINTER_IP:9100' --paper A4
   ```

4. Select **Brother HL-2270DW HQ1200** in the application's print dialog and print a test page. The Resolution option should default to HQ1200; `lpoptions -p Brother_HL_2270DW_HQ1200 -l` shows it as `*1200dpi`.

The installer creates a separate queue, keeps your existing queue, and leaves the default printer unchanged. It refuses to overwrite an existing queue name; use `--queue Another_Name` if needed. Letter is the default paper size; use `--paper A4` for A4. The queue is not shared over the network.

**Signing:** the executable has an ad-hoc signature, not an Apple Developer ID signature, and this release is not notarized. A checksum checks download integrity, not publisher identity. macOS security settings may prevent downloaded code from running. Building from the included source is an alternative; this project does not require disabling SIP or Gatekeeper.

## Build from source

Requires an Apple silicon Mac, Apple's Command Line Tools (`xcode-select --install` if absent), and the macOS `ppdc`/`cupstestppd` utilities. No Homebrew libraries or Rosetta are needed.

```sh
git clone https://github.com/hyperlink/brlaser-hl2270dw-macos.git
cd brlaser-hl2270dw-macos
./scripts/build.sh
./scripts/test.sh
./scripts/install.sh --copy-uri-from YOUR_EXISTING_QUEUE --dry-run
sudo ./scripts/install.sh --copy-uri-from YOUR_EXISTING_QUEUE
```

Builds link only to macOS's system CUPS, C++, and system libraries. The upstream source is vendored at a recorded commit; the build does not download or execute a remote installer. No proprietary Brother files are needed.

## Remove

```sh
sudo ./scripts/uninstall.sh Brother_HL_2270DW_HQ1200
```

Use the queue name you chose at installation. The script checks that the selected queue belongs to this package, removes it, and removes the driver files only if no other queue uses them. It does not restore a previously chosen default printer; select your remaining queue in macOS if needed.

Installed files:

- `/Library/Printers/brlaser-hl2270dw/rastertobrlaser`
- `/Library/Printers/PPDs/Contents/Resources/brlaser-hl2270dw-macos.ppd`
- The CUPS queue and its system-managed configuration.

## Troubleshooting

- **No output:** check `lpstat -p` and `lpstat -o`, printer power/network access, and the URI copied from the working queue.
- **Wrong paper size:** choose Letter/A4 in the print dialog and application page setup.
- **HQ1200 missing:** confirm you selected the new queue, rather than Generic PCL or the migrated Brother queue. In some apps, Resolution is under Printer Features.
- **Queue already exists:** choose a new `--queue` name or intentionally uninstall the package's old queue first. Do not remove your working fallback merely to install this package.
- **Bad CPU type:** confirm the queue references this ARM64 driver. `file /Library/Printers/brlaser-hl2270dw/rastertobrlaser` should report `arm64`.

When reporting problems, include macOS version, chip family, connection type, selected resolution, and a description of the output. Remove usernames, document names, printer serial numbers, network addresses, and other private information from logs before posting them. Do not post passwords.

## License and credit

brlaser is Copyright © 2013 Peter De Wachter and other contributors, licensed under **GPL-2.0-or-later**. Packaging additions use the same license. Full upstream notices and the test library's Boost license are preserved. See [LICENSE](LICENSE), [NOTICE.md](NOTICE.md), and [LEGAL.md](LEGAL.md).

Brother is a trademark of Brother Industries, Ltd. This independent community project is not affiliated with or endorsed by Brother or Apple. Software is provided without warranty under its license.

## Creating a release

For Developer ID signing and a notarized `.pkg`, see [SIGNING.md](SIGNING.md). This requires certificates and Apple notarization acceptance; the existing v0.1.0 download remains unnotarized.

After building, running tests, and reviewing [TESTING.md](TESTING.md):

```sh
./scripts/package.sh
```

Publish the resulting archive and `SHA256SUMS` together. The archive includes the binary, generated PPD, complete upstream source, build/install scripts, license, and notices. Keep the matching source available for every binary release; a link to a moving upstream branch alone is not a substitute.
