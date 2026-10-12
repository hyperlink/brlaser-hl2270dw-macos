// SPDX-License-Identifier: GPL-2.0-or-later
// Small deterministic CUPS raster for testing the brlaser resolution command path.
#include <cups/raster.h>
#include <cstdlib>
#include <cstring>
#include <unistd.h>

int main(int argc, char **argv) {
  if (argc != 2) return 2;
  const unsigned resolution = std::strtoul(argv[1], nullptr, 10);
  if (resolution != 600 && resolution != 1200) return 2;
  cups_raster_t *raster = cupsRasterOpen(STDOUT_FILENO, CUPS_RASTER_WRITE);
  if (!raster) return 1;
  cups_page_header2_t h = {};
  h.HWResolution[0] = h.HWResolution[1] = resolution;
  h.PageSize[0] = 612; h.PageSize[1] = 792;
  h.cupsWidth = 64; h.cupsHeight = 64;
  h.cupsBytesPerLine = 8;
  h.cupsBitsPerColor = h.cupsBitsPerPixel = h.cupsNumColors = 1;
  h.cupsColorSpace = CUPS_CSPACE_K;
  h.cupsColorOrder = CUPS_ORDER_CHUNKED;
  h.NumCopies = 1;
  std::strcpy(h.MediaType, "PLAIN");
  std::strcpy(h.cupsPageSizeName, "Letter");
  if (!cupsRasterWriteHeader2(raster, &h)) return 1;
  for (unsigned row = 0; row < 64; ++row) {
    unsigned char pixels[8];
    std::memset(pixels, row % 2 ? 0x55 : 0xAA, sizeof pixels);
    if (cupsRasterWritePixels(raster, pixels, sizeof pixels) != sizeof pixels) return 1;
  }
  cupsRasterClose(raster);
  return 0;
}
