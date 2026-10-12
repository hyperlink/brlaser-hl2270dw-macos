# Validation

## Physical test, 2026-10-11

One Brother HL-2270DW connected over the network to an Apple silicon Mac running macOS 27.0.1. A native brlaser version 6 build from commit `2a49e3287c70c254e7e3ac9dabe9d6a07218c3fa` printed a Letter, single-sided test page in HQ1200 mode. The owner confirmed the small text and fine lines looked correct. CUPS completed the job without the migrated Intel driver's architecture error.

The initial successful installation was assembled locally. The public package uses the same upstream driver source, with a package-specific installation path and an explicit macOS deployment target. That physical test does not, by itself, prove every aspect of the public installer, every supported paper size, or every macOS release.

Release 0.1.0 validation: the packaged build produced byte-for-byte identical printer data to the physically tested installed driver for the full original HQ1200 test-page raster. All four upstream test programs passed; the synthetic 600/1200 DPI tests confirmed the expected high-resolution commands. All vendored upstream files were compared byte-for-byte with the recorded source checkout. Installer preview and existing-queue refusal were checked against the current Mac's queue without changing it.

## Repeatable local checks

Run `./scripts/build.sh` and `./scripts/test.sh` to compile the driver, run all four upstream test executables, check the PPD, inspect architecture/system-library dependencies, and exercise the high-resolution command path using synthetic CUPS raster input. The PPD check ignores the filter's installed location before installation; run `cupstestppd` without that exemption on an installed PPD.

Before release, also run an installer dry run against an existing queue, verify invalid arguments are rejected without changes, unpack the release archive, confirm full source/license inclusion, and verify the archive's SHA-256 checksum. The dry run does not test administrator authentication or system-file writes.

## Not yet physically tested

- Other printer models or macOS versions.
- USB, IPP, or LPD transport.
- Duplex, manual tray, envelopes, A4, and toner-save behavior.
- Clean-machine installation of a browser-downloaded, quarantined release.

No automated test can confirm a sheet actually printed correctly. Report successful additional configurations with model, OS version, transport, paper size, resolution, and features tested; avoid posting private identifiers.

## Signed v0.1.1 package, 2026-10-12

The driver was signed with Developer ID Application (Geneir Solutions), hardened runtime, and a secure timestamp. The installer was signed with Developer ID Installer. The extracted signed driver passed strict signature validation and generated identical HQ1200 output to the unsigned build on the synthetic test raster. The full corresponding source is included in the package.

Apple accepted notarization submission `f97e9dad-df4b-4eac-a0e2-5013fa63d7d2`. Stapling and ticket validation succeeded, and Gatekeeper's installer assessment returned `accepted` with `source=Notarized Developer ID`. These checks do not replace physical printer testing or a separate clean-Mac installation. The signed package has not been installed over the original working queue on the development Mac.
