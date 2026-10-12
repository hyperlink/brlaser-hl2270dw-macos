# Redistribution notes

This is practical licensing information, not legal advice or a legal clearance opinion. Patent, trademark, warranty, and other obligations can depend on jurisdiction and use. Consult a qualified lawyer if you need a legal opinion, especially for commercial distribution.

## Open-source license

The included brlaser source permits redistribution and modification under GPL version 2 or, at the recipient's option, any later version. This package and its packaging scripts are distributed under GPL-2.0-or-later. The complete GPLv2 text is in LICENSE and vendor/brlaser/COPYING; existing copyright/license notices are preserved.

When distributing this package:

- Keep the license, copyright notices, and warranty disclaimer.
- Provide complete corresponding source for any distributed binary, including your changes and the scripts controlling compilation and installation, under the applicable GPL terms.
- Identify changes and their dates when modifying upstream files. This version preserves the upstream files and documents its generated configuration changes in NOTICE.md.
- Do not impose additional restrictions inconsistent with the GPL.
- Retain the separate license notice for the test-only Boost-licensed lest header.

The release script bundles full corresponding source with the binary archive. This is simpler than relying on a separate written source offer. Publishing only a binary or linking only to the latest upstream branch would not follow this project's distribution approach.

Relevant primary sources:

- [GPLv2 sections 1–3: copies, modifications, and binary/source distribution](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
- [GNU license FAQ: binary downloads and source access](https://www.gnu.org/licenses/gpl-faq.en.html#DistributeWithSourceOnInternet)
- [Upstream brlaser license and attribution](https://github.com/pdewacht/brlaser)

## Brother and Apple material

Only the open-source brlaser implementation is redistributed. Brother's proprietary Intel driver, installer, PPD, icons, and utilities are excluded. This package does not rely on permission to redistribute that proprietary software.

Brother and model names identify the compatible hardware. Brother is a trademark of Brother Industries, Ltd.; Apple and macOS are trademarks of Apple Inc. No logos or endorsement claims are used. This project is not affiliated with or endorsed by either company. Trademark rules are separate from the GPL.

## Limits

The GPL permission is not a guarantee against every possible third-party claim. This project has not performed patent clearance or a jurisdiction-specific legal review. The software has limited hardware testing and is supplied without warranty, as stated in its license. An ad-hoc code signature does not imply Apple notarization, certification, or approval.
