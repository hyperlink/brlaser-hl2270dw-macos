# Developer ID signing and notarization

The v0.1.2 installer is Developer ID signed and Apple-notarized with a stapled ticket (verification recorded in [TESTING.md](TESTING.md)). These instructions describe how to produce future signed releases.

## One-time certificate setup

Use the paid Apple Developer Program account with the appropriate role. On the signing Mac, open Xcode > Settings > Accounts (the label may appear as Apple Accounts), add the Apple account, select its team, and open Manage Certificates. Use the add menu to create **Developer ID Application** and **Developer ID Installer** certificates if available. These are not Apple Development or Mac App Distribution certificates.

Alternatively, use [Apple's certificate portal instructions](https://developer.apple.com/help/account/certificates/create-developer-id-certificates/) and [Keychain Access CSR instructions](https://developer.apple.com/help/account/certificates/create-a-certificate-signing-request/): create a certificate signing request on this Mac, upload it for the corresponding Developer ID certificate type, then download and double-click the certificate to install it. The certificate must have its matching private key in this Mac's Keychain. Apple documents Account Holder as the role for creating these certificates through this workflow.

Check availability without exporting private keys:

```sh
security find-identity -v -p codesigning
security find-identity -v -p basic
```

Keep private keys, `.p12` exports, app-specific passwords, and API keys out of Git and chat.

## Notary credentials

In your own Terminal, use this interactive command:

```sh
xcrun notarytool store-credentials brlaser-notary
```

Follow its prompts for the account, team, and an app-specific password (or configure an appropriate App Store Connect API key). Store the credentials in Keychain. The profile name itself is not a secret. Never put a password directly in a saved script or shell command history.

## Build and sign

Choose a new VERSION for a new release; do not replace an existing release's published assets. From the repository root:

```sh
./scripts/build.sh
./scripts/test.sh
./scripts/build-pkg.sh \
  'Developer ID Application: YOUR NAME (TEAMID)' \
  'Developer ID Installer: YOUR NAME (TEAMID)'
```

Use exact identity names returned by `security`. The binary is signed with hardened runtime and a secure timestamp, then the installer is signed with Developer ID Installer. No extra entitlements are required by this driver. The source archive and license notices are included in the installer payload under `/Library/Printers/brlaser-hl2270dw/`.

`./scripts/build-pkg.sh --unsigned-for-testing` can validate package layout locally without certificates. It is explicitly labeled UNSIGNED-TEST and must not be advertised as signed or notarized.

## Submit, check, and staple

Replace `PACKAGE.pkg` below with the newly signed file in `dist/`:

```sh
xcrun notarytool submit 'PACKAGE.pkg' --keychain-profile brlaser-notary
```

Keep the returned submission ID. Submission is asynchronous; do not resubmit merely because it is still processing.

```sh
xcrun notarytool info 'SUBMISSION-ID' --keychain-profile brlaser-notary
```

Only after the status is **Accepted**:

```sh
xcrun stapler staple 'PACKAGE.pkg'
xcrun stapler validate 'PACKAGE.pkg'
pkgutil --check-signature 'PACKAGE.pkg'
spctl --assess --type install --verbose=2 'PACKAGE.pkg'
shasum -a 256 'PACKAGE.pkg'
```

If rejected, retrieve the log with `xcrun notarytool log 'SUBMISSION-ID' --keychain-profile brlaser-notary`, fix the reported problem, and create a new submission. Preserve the final stapled package: rebuilding or changing it invalidates the prior verification and changes its checksum.

Before publishing, test the signed driver through CUPS, download/install the final package in a clean environment, and verify Gatekeeper behavior. Update the release notes and checksums only after successful validation. Developer ID signatures expose the developer's certificate identity to recipients.

## What the installer does

The `.pkg` installs the native filter, model PPD, source, and notices. It does not discover printers, create a queue, change the default printer, or run printer setup as root. After installation, add the printer in System Settings > Printers & Scanners and choose the `Brother HL-2270DW series, using brlaser v6 (Apple silicon HQ1200)` software entry. Select HQ1200 and the appropriate paper size, then test print. The install scripts' CLI path remains available for building from source.

The uninstall script removes the package's known files and forgets its installation receipt once no other queue uses the driver.

References: [Apple notarization overview](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution), [Developer ID](https://developer.apple.com/developer-id/).
