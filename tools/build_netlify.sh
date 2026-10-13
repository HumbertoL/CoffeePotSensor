#!/usr/bin/env bash
# Builds everything the Netlify site serves, ready to deploy:
#   dist/netlify/index.html        the dashboard
#   dist/netlify/<uuid>.bin        the firmware (name from OTA_FILE_NAME in secrets.h)
#   dist/netlify/<uuid>.version    its version, which the board checks first
#   dist/netlify-deploy.zip        the same files, zipped with index.html at the top
# Usage: tools/build_netlify.sh
#
# The firmware version is the repo's commit count, so it rises with every commit.
# The firmware must be committed first, so each published version matches one commit.
#
# dist/ is gitignored: the .bin contains the Wi-Fi password and ThingSpeak key, and
# its UUID name must never appear in this (public) repo.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SECRETS="$ROOT/secrets.h"
DASHBOARD="$ROOT/dashboard/index.html"
export BUILD="${TMPDIR:-/tmp}/coffeepot_build"
OUT="$ROOT/dist/netlify"
ZIP="$ROOT/dist/netlify-deploy.zip"

[ -f "$SECRETS" ] || { echo "Missing secrets.h (copy secrets.example.h)"; exit 1; }
dirty="$(git -C "$ROOT" status --porcelain -- '*.ino' '*.cpp' '*.h')"
if [ -n "$dirty" ]; then
  echo "The firmware has uncommitted changes. Commit them first, so this build's"
  echo "version number matches a commit:"
  echo "$dirty"
  exit 1
fi
if grep -qE '^#define SENSOR_TEST 1' "$ROOT/CoffeePotSensor.ino"; then
  echo "SENSOR_TEST is 1 in CoffeePotSensor.ino. Set it to 0 before publishing."
  exit 1
fi

read_secret() { sed -nE 's/^static const char\* '"$1"' = "([^"]*)";.*/\1/p' "$SECRETS"; }
file_name="$(read_secret OTA_FILE_NAME)"
base_url="$(read_secret OTA_BASE_URL)"
[ -n "$file_name" ] || { echo "OTA_FILE_NAME is empty in secrets.h"; exit 1; }
[[ "$file_name" =~ ^[0-9a-fA-F-]{36}$ ]] || { echo "OTA_FILE_NAME should be a UUID (uuidgen)"; exit 1; }
if [ -z "$base_url" ]; then
  echo "Note: OTA_BASE_URL is empty in secrets.h, so this firmware won't check for updates."
  echo "      Fine for the first deploy; set it to the site's address, then rebuild and flash over USB."
fi

version="$(git -C "$ROOT" rev-list --count HEAD)"
commit="$(git -C "$ROOT" rev-parse --short HEAD)"

EXTRA_FLAGS="-DFIRMWARE_VERSION=$version" "$ROOT/tools/compile.sh"

rm -rf "$OUT" "$ZIP"
mkdir -p "$OUT"
# Stamp the version into the dashboard, so it can show what's deployed
grep -q '^const DEPLOYED_FIRMWARE = "";' "$DASHBOARD" || { echo "Couldn't find DEPLOYED_FIRMWARE in $DASHBOARD"; exit 1; }
sed 's/^const DEPLOYED_FIRMWARE = "";/const DEPLOYED_FIRMWARE = "'"$version"'";/' "$DASHBOARD" > "$OUT/index.html"
cp "$BUILD/CoffeePotSensor.ino.bin" "$OUT/$file_name.bin"
echo "$version" > "$OUT/$file_name.version"
(cd "$OUT" && zip -q -X "$ZIP" index.html "$file_name.bin" "$file_name.version")

echo
echo "Firmware version $version (commit $commit)"
echo "Deploy folder: dist/netlify/"
echo "Deploy zip:    dist/netlify-deploy.zip"
[ -n "$base_url" ] && echo "The board will find it at ${base_url%/}/<OTA_FILE_NAME>.bin"
exit 0
