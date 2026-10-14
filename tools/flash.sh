#!/usr/bin/env bash
# Builds the Netlify zip (tools/build_netlify.sh) and flashes the exact same firmware
# over USB, so the board runs the same version as the zip. A plain Arduino IDE build is
# version 0, so the board would replace it with whatever is on Netlify.
# Usage: tools/flash.sh [port]   (default: the only /dev/cu.usbmodem* port)
#
# Deploy the zip it builds too, so Netlify serves this same firmware. Note that a
# change to secrets.h alone doesn't change the version (it comes from the commit count),
# so a board already on that version won't pick it up over the air: flash it here.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLI="${ARDUINO_CLI:-$(command -v arduino-cli || echo "/Applications/Arduino IDE.app/Contents/Resources/app/lib/backend/resources/arduino-cli")}"
export BUILD="${TMPDIR:-/tmp}/coffeepot_build"
FQBN="esp32:esp32:waveshare_esp32_s3_zero:PartitionScheme=min_spiffs"

port="${1:-}"
if [ -z "$port" ]; then
  ports=(/dev/cu.usbmodem*)
  [ -e "${ports[0]}" ] || { echo "No board found (/dev/cu.usbmodem*). Plug it in, or hold BOOT while plugging in."; exit 1; }
  [ "${#ports[@]}" -eq 1 ] || { echo "More than one port; pass one: ${ports[*]}"; exit 1; }
  port="${ports[0]}"
fi

"$ROOT/tools/build_netlify.sh"

# Make sure what we flash is byte-for-byte the .bin in the zip
file_name="$(sed -nE 's/^static const char\* OTA_FILE_NAME = "([^"]*)";.*/\1/p' "$ROOT/secrets.h")"
cmp -s "$BUILD/CoffeePotSensor.ino.bin" "$ROOT/dist/netlify/$file_name.bin" || { echo "The build doesn't match the zip's .bin"; exit 1; }
version="$(cat "$ROOT/dist/netlify/$file_name.version")"

"$CLI" upload --fqbn "$FQBN" --input-dir "$BUILD" -p "$port"
echo
echo "Flashed firmware v$version to $port."
echo "Deploy dist/netlify-deploy.zip so Netlify serves the same build."
