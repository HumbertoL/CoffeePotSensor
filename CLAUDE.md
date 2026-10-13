# CLAUDE.md

Arduino sketch ("brew-em-all") that tracks how long each of three coffee pots has been sitting on the rack (the pots sit on a rack, not a burner) and shows it on a Waveshare 2" ST7789 SPI LCD. It runs on a **Waveshare ESP32-S3-Zero** (ESP32-S3FH4R2, 3.3 V, Wi-Fi) and publishes to ThingSpeak.

The Arduino Nano was dropped on 2026-10-12, along with the Waveshare driver files (in git history up to `63bcd10`). ESP8266 was dropped before that. See [README.md](README.md) for wiring, the screen and ThingSpeak. See [docs/HARDWARE.md](docs/HARDWARE.md) for part specs, sensor behavior and the physical setup (wall-mounted behind the pots). Keep that file up to date when hardware facts change. Planned ideas (ToF sensors, OTA updates) are tracked in [docs/FUTURE_WORK.md](docs/FUTURE_WORK.md).

## Build / flash

No tests or CI. To verify a change, compile it. If hardware is attached, also flash it and check the screen.

```bash
tools/compile.sh                     # compile (bundled arduino-cli, min_spiffs partition)
tools/build_netlify.sh               # dashboard + OTA firmware zip for Netlify (needs committed firmware)
CLI="/Applications/Arduino IDE.app/Contents/Resources/app/lib/backend/resources/arduino-cli"
"$CLI" upload  --fqbn esp32:esp32:waveshare_esp32_s3_zero:PartitionScheme=min_spiffs --input-dir "$TMPDIR/coffeepot_build" -p /dev/cu.usbmodemXXXX
"$CLI" monitor -p /dev/cu.usbmodemXXXX -c baudrate=115200
```

- `arduino-cli` is not on PATH. Use the copy bundled with Arduino IDE (path above).
- The esp32 core 3.3.x is installed in `~/Library/Arduino15`. **LovyanGFX** 1.2.32 is installed in `~/Documents/Arduino/libraries`. TFT_eSPI is also installed, but it's configured inside the library folder for office_ac_controller, so don't use it here.
- The board uses native USB (no UART chip), so the port shows up as `/dev/cu.usbmodem*`. If upload can't find it, hold BOOT while plugging in.
- **Compile both with and without `secrets.h`** before calling a change done (move it aside temporarily). Without it, `publish.cpp` takes a different branch.
- The sketch folder name must match `CoffeePotSensor.ino`. Arduino compiles every `.cpp` in the folder automatically.
- **Partition scheme: `PartitionScheme=min_spiffs`** (two 1.9 MB app slots, for OTA). The board can only take OTA builds made with the scheme it was last flashed with over USB, so never change it casually.
- Baseline: about 414 KB flash (21%) without `secrets.h`; about 1.12 MB (56%) and 50 KB globals with it (Wi-Fi, HTTPS, OTA).
- **Never commit credentials.** They go only in `secrets.h`. Before committing, read the staged diff and check that no SSID, password or API key is in it, including in `secrets.example.h`.
- **This repo is public.** The OTA file name (a UUID) and the Netlify site address are secret too, because the `.bin` contains the credentials: they live only in `secrets.h` (`OTA_FILE_NAME`, `OTA_BASE_URL`) and `dist/` (gitignored). Never write them into a tracked file, a commit message or the dashboard.
- `secrets.h` defines its values as `static const char*` so several files (`publish.cpp`, `ota.cpp`) can include it.

## Layout

| File | Purpose |
|---|---|
| `CoffeePotSensor.ino` | App logic: `CoffeePot` struct, sensor polling and debounce, idle restart. Hands each pot's state to the screen and ThingSpeak as a `PotReport` |
| `ui.h/.cpp` | The screen, drawn with LovyanGFX (design A: a header, then one row per pot). The LCD pins, the `LGFX` panel config, the freshness cutoffs `FRESH_MIN` (90) / `OLD_MIN` (240) and the colors live here |
| `publish.h/.cpp` | ThingSpeak publishing: Wi-Fi, NTP (`TIME_ZONE`, US Central) and a FreeRTOS task that posts each pot's placed-at Unix time (`field1–3`; 0 = unknown, -1 = removed) and the firmware version (`field4`). Also `publishNetState()` and `clockValid()` for the screen. The field mapping is in README.md; keep it stable |
| `ota.h/.cpp` | Firmware updates: a task checks `<OTA_BASE_URL><OTA_FILE_NAME>.version` 2 min after boot and hourly, installs the `.bin` with HTTPUpdate if newer than `FIRMWARE_VERSION`, calls `savePotsForRestart()` (in the .ino, RTC memory) and restarts. `otaBusy()` shows "Updating..." in the header |
| `ota_root_ca.h` | Root certificates for the Netlify download (copied from office_ac_controller) |
| `dashboard/index.html` | The Netlify dashboard: reads the public ThingSpeak channel (optional Read API Key in localStorage), shows pot ages, the board's last update and firmware version, and recent activity. `DEPLOYED_FIRMWARE` is stamped by `build_netlify.sh` |
| `tools/compile.sh`, `tools/build_netlify.sh` | Compile, and build `dist/netlify-deploy.zip` (dashboard + `<uuid>.bin` + `<uuid>.version`; version = git commit count) |
| `secrets.example.h` | Template for the gitignored `secrets.h` (Wi-Fi SSID and password, ThingSpeak Write API Key, OTA URL parts). Without `secrets.h`, the sketch builds with publishing and updates off (`__has_include`) |
| `thingspeak_root_ca.h` | Root certificates for HTTPS to api.thingspeak.com (copied from office_ac_controller) |

## How it works

- Each pot has an **IR reflection sensor module** (FC-51/TCRT5000 style, LM393 comparator with an onboard pull-up and a sensitivity screw) on **GPIO4/5/6**. The pin is **active LOW**, so LOW means a pot is present. The pins use `INPUT` with no internal pull-up.
- `loop()` runs every `REFRESH_INTERVAL` ms (100 ms):
  - `updatePotStatus` debounces each sensor. A new reading must hold for `PLACE_DEBOUNCE_MS` (1 s) before a pot counts as placed, or `REMOVE_DEBOUNCE_MS` (3 s) before it counts as removed. Brief IR flickers, like a hand passing or steam, are ignored and don't reset the timer.
    - On a confirmed placement it sets `timeKnown = true` and `placedAt = rawChangedAt`, the moment the reading first changed rather than when the debounce finished.
    - `present` is the debounced state; `rawPresent` is the latest reading.
    - Each confirmed change is published (`publishState`).
  - `uiDraw` gets all three pots as `PotReport`s plus the network state, and redraws only the regions whose content changed.
- **`SENSOR_TEST`** (top of the `.ino`): when set to 1, there is no debounce, so the screen follows the raw sensor reading, and each change is logged to Serial. Nothing is published. It's for checking sensors and case prints. **It must be 0 in commits.** The user often keeps it at 1 locally while testing: commit around it, never with it.
- At power-on, `setup()` records which pots are already present. Those pots show **?** ("There since power-on") until they are removed and put back. A pot that is absent at boot shows **–**, and its timer starts when it is placed.
- **Idle restart.** If no pot is placed or removed for `IDLE_RESTART_MS` (48 h), `restart()` calls `ESP.restart()`. In an office this happens over the weekend. Any present/removed edge on any pot updates `lastActivity`, and boot counts as activity. `setup()` also calls `enableLoopWDT()`, which reboots the board if `loop()` stops returning for about 5 s. Don't add long blocking work to `loop()`; network work belongs in the publish task.
  - To test it, temporarily set `IDLE_RESTART_MS` to something like `30000UL`.
- Elapsed time uses unsigned `now - placedAt`, so it stays correct across the 49.7-day `millis()` rollover. The only limit is a single pot sitting for more than 49.7 days. The decaf pot can reach hundreds of hours, so the age text must fit "999h 59m".

## Screen (`ui.cpp`)

- 320 × 240 landscape: a 30 px header (title, local clock once NTP has set it, network icon), then three 70 px rows (name, age in a large font colored by freshness, "Brewed 2:29 pm" or "Brewed Oct 3", the word Fresh / OK / Old, and a bar that empties at `OLD_MIN`).
- Each region is drawn into a sprite (header 320 × 30; one shared 320 × 70 row sprite, 45 KB) and pushed in one burst, so there's no flicker. A region is redrawn only when its content key changes. PSRAM is off (the board default), so keep sprites small.
- Fonts are LovyanGFX built-ins: `DejaVu18`/`DejaVu12` (smooth) and `FreeSansBold18pt7b` for the age.
- Panel config (unverified on hardware as of 2026-10-12): SPI2 at 20 MHz, mode 3, `invert = true`, `setRotation(3)` (the old Waveshare demo used MADCTL 0xA0 and INVON). If the image is upside down, use rotation 1; if red and blue are swapped, set `rgb_order`.
- Never call the pots' place a "burner".

## Constraints and gotchas

- **`millis()` arithmetic** uses unsigned subtraction, so it handles rollover. Keep it that way.
- **ESP32-S3-Zero pins** are raw GPIO numbers:
  - In use: 7 BL, 8 RST, 9 DC, 10 CS, 11 MOSI, 12 SCK, 4–6 sensors.
  - Free on the edge headers: 1, 2, 3 (strapping pin), 13, and TX/RX (43/44).
  - GPIO14–16 (front) and 17, 18, 38–42, 45 (back) are **solder pads only**, not header pins. Don't assign them unless you're willing to solder wires to pads.
  - The core's default SPI pins for this board (34–37) **are not brought out**, so the LCD's SPI pins are set explicitly in `ui.cpp`.
  - Avoid the strapping pins 0, 3, 45 and 46. Avoid 21 (onboard WS2812 LED) and 43/44 (UART0).
  - GPIOs are 3.3 V only.

## Case (`case/`)

- **`case/v2/coffee_case_v2.scad` is the current case:** a sensor bar, mast and head, designed for the ESP32-S3-Zero. Its README lists the parts, print orientations, test prints, settings, and each measurement's confidence.
- **Conventions in v2:**
  - Frame: X right, Y up the wall, Z out of the wall.
  - Bodies print back-down and covers print face-down (`face_down` rotates, never mirrors). No supports.
  - Boards are held by posts, ledges and pockets plus the cover, not screws.
  - Boards and wires are drawn only under `$preview && SHOW_PARTS`.
- **Status and next steps** are at the top of `case/v2/README.md`. Fit settings are tuned from the user's test prints and recorded under "Test print results" there.
- **Checks to rerun after changing it.** The tools are in `case/tools/`: `overhang.py`, `compare.py` and `stlinfo_lib.py`.
  - Overlaps between case parts and boards. Only the pins and the crush ribs should overlap.
  - Downward-facing surfaces above the bed on each exported part.
  - Bed fit (250 × 210 mm).
  - That exports are byte-identical with `SHOW_PARTS` on and off.
- **Testing modules from another file:** load it with `use <...>`. That makes the modules available, but **not** the top-level variables, so pass numbers in directly.
- **The old case** (below) is the SolidWorks conversion, kept as a record.

- The OpenSCAD files are the source of truth. The original SolidWorks files (`.SLDASM` / `.SLDPRT`, a closed binary format that can't be read here) and their STL exports were removed from the repo. They're kept in git history at commit `e428796`, and `git checkout e428796 -- case` restores them.
- `case/scad/` is a verified OpenSCAD conversion: one file per part plus `assembly.scad`. See [case/README.md](case/README.md) for the parts, the coordinate frame and the accuracy table.
- **STL and SolidWorks files are git-ignored.** Never commit them.
- To re-verify a part against the originals, restore them as above, then run `python3 case/tools/compare.py <STL> case/scad/<part>.scad "<module>()"`. Aim for < 0.5 % each way. Use `case/tools/slice.py` to measure exact outlines.
- In part files, set `$fn` **inside** the module. A top-level `$fn` doesn't apply when the file is loaded with `use <>`. Use `$fn = 36` to match SolidWorks' 10° facets.

## Conventions

- Commit messages use conventional prefixes: `feat:`, `fix:`, `refactor:`, `docs:`.
- Use 2-space indent in the `.ino` and the `.cpp` files.
