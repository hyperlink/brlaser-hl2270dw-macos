# Provenance and notices

Upstream: https://github.com/pdewacht/brlaser

Vendored commit: `2a49e3287c70c254e7e3ac9dabe9d6a07218c3fa`

Upstream driver version: 6

The tracked upstream files are preserved, unmodified, under `vendor/brlaser/`, including its README, COPYING, source headers, and tests. The upstream copyright notices remain authoritative; no exclusive ownership of brlaser is claimed by this project.

The test-only `vendor/brlaser/test/lest.hpp` carries Martin Moene's copyright and the Boost Software License 1.0 in its header. Those notices are preserved. It is not linked into the printing executable.

Packaging additions dated 2026-10-11 are licensed GPL-2.0-or-later. They generate `config.h`, compile an ARM64 executable, generate a PPD with macOS's CUPS tools, set HQ1200 and Letter defaults, choose a package-specific filter path, and add installation/removal/release scripts. Upstream driver source is not modified. The generated PPD differs from the upstream default configuration in these documented ways.

The upstream implementation supplies HQ1200 and printer protocol support. This project packages that work for macOS; it does not claim to have invented those capabilities.

No proprietary Brother executables, migrated Brother PPDs, icons, logos, utilities, firmware, macOS libraries, or SDK files are included. Standard system libraries and build tools are supplied by the user's macOS installation.
