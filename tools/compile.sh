#!/usr/bin/env bash
# Compiles the firmware with the arduino-cli bundled in the Arduino IDE.
# Usage: tools/compile.sh
# EXTRA_FLAGS adds compiler flags (build_netlify.sh uses it to set FIRMWARE_VERSION).
# To build the files for Netlify (dashboard and firmware update), use tools/build_netlify.sh.
#
# The partition scheme must match the board's (set when it was last flashed over USB):
# "Minimal SPIFFS" gives each of the two app slots 1.9 MB, so updates have room.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLI="${ARDUINO_CLI:-$(command -v arduino-cli || echo "/Applications/Arduino IDE.app/Contents/Resources/app/lib/backend/resources/arduino-cli")}"
BUILD="${BUILD:-${TMPDIR:-/tmp}/coffeepot_build}"
FQBN="esp32:esp32:waveshare_esp32_s3_zero:PartitionScheme=min_spiffs"

"$CLI" compile --fqbn "$FQBN" --build-path "$BUILD" \
  --build-property "compiler.cpp.extra_flags=${EXTRA_FLAGS:-}" \
  "$ROOT"
