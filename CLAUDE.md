# CLAUDE.md

Arduino sketch ("brew-em-all") that tracks how long each of three coffee pots has been sitting on its burner and shows it on a Waveshare 2" ST7789 SPI LCD. It supports two boards from the same code. Pins and SPI setup are chosen with `#if defined(ARDUINO_ARCH_ESP32)`.
- **Arduino Nano** (ATmega328P, 2 KB SRAM, 32 KB flash). This is the original target and the tightest constraint.
- **Waveshare ESP32-S3-Zero** (ESP32-S3FH4R2, 3.3 V). This is the planned replacement.

ESP8266 is no longer supported. See [README.md](README.md) for wiring. See [docs/HARDWARE.md](docs/HARDWARE.md) for part specs, sensor behavior, the physical setup (wall-mounted behind the pots), and the planned sensor-rod redesign. Keep that file up to date when hardware facts change. Planned ideas (ToF sensors, OTA updates) are tracked in [docs/FUTURE_WORK.md](docs/FUTURE_WORK.md).

## Build / flash

No tests or CI. To verify a change, compile it. If hardware is attached, also flash it and check the screen.

```bash
CLI="/Applications/Arduino IDE.app/Contents/Resources/app/lib/backend/resources/arduino-cli"
"$CLI" compile --fqbn arduino:avr:nano /Users/humberto/workspace/CoffeePotSensor
"$CLI" upload  --fqbn arduino:avr:nano -p /dev/cu.usbserial-XXXX /Users/humberto/workspace/CoffeePotSensor
"$CLI" monitor -p /dev/cu.usbserial-XXXX -c baudrate=115200
```

- `arduino-cli` is not on PATH. Use the copy bundled with Arduino IDE (path above).
- Clones and old-bootloader Nanos may need `arduino:avr:nano:cpu=atmega328old`.
- ESP32-S3 FQBN: `esp32:esp32:waveshare_esp32_s3_zero`. The esp32 core 3.3.x is installed in `~/Library/Arduino15`. The board uses native USB (no UART chip), so the port shows up as `/dev/cu.usbmodem*`. If upload can't find it, hold BOOT while plugging in.
- **Always compile both FQBNs** before calling a change done. Something that builds on one can fail on the other, for example an AVR-only header or a 16-bit `int` assumption.
- The sketch folder name must match `CoffeePotSensor.ino`. Arduino compiles every `.cpp` in the folder automatically.
- Baseline:
  - Nano: about 17.8 KB flash (57%) and 645 B globals (31%).
  - ESP32-S3: about 324 KB flash (24%) and 22.7 KB globals (6%). Check the compile output after every change and watch RAM closely.

## Layout

| File | Owner | Purpose |
|---|---|---|
| `CoffeePotSensor.ino` | **ours** | All app logic: `CoffeePot` struct, sensor polling, drawing |
| `DEV_Config.h/.cpp` | Waveshare (modified) | Per-board pin defines and `DEV_SPI_HZ`, SPI/serial init (`SPI.beginTransaction` is opened once and never ended) |
| `LCD_Driver.h/.cpp` | Waveshare | ST7789 init, window/cursor and pixel writes. `LCD_WIDTH 320`, `LCD_HEIGHT 240` (landscape via MADCTL `0xA0`) |
| `GUI_Paint.h/.cpp` | Waveshare | Drawing primitives (`Paint_DrawString_EN`, `Paint_DrawLine`, …) |
| `font8/16/20/24.cpp`, `fonts.h` | Waveshare | Monospace bitmap fonts in PROGMEM. Widths: 5 / 11 / 14 / 17 px; heights: 8 / 16 / 20 / 24. Only Font20 (3.8 KB) and Font24 (6.8 KB, used just for the title) are linked in. Unused fonts are discarded by `--gc-sections`, so they cost nothing in flash; there's no need to delete them or `#ifdef` them out |
| `image.cpp/.h` | Waveshare | 70×70 sample bitmap. Unused (the linker drops it) |
| `Debug.h` | Waveshare | `Debug()` macro. Not useful: AVR `printf` isn't wired to Serial |

Keep changes to the Waveshare files small. App behavior belongs in the `.ino`.

## How it works

- Each pot has an **IR reflection sensor module** (FC-51/TCRT5000 style, LM393 comparator with an onboard pull-up and a sensitivity screw). They connect to **D2/D3/D4** on the Nano and **GPIO4/5/6** on the ESP32-S3-Zero. The pin is **active LOW**, so LOW means a pot is present. The pins use `INPUT` with no internal pull-up.
- `loop()` runs every `REFRESH_INTERVAL` ms (100 ms). For each pot it does two things:
  - `updatePotStatus` debounces the sensor. A new reading must hold for `PLACE_DEBOUNCE_MS` (1 s) before a pot counts as placed, or `REMOVE_DEBOUNCE_MS` (3 s) before it counts as removed. Brief IR flickers, like a hand passing or steam, are ignored and don't reset the timer.
    - On a confirmed placement it sets `timeKnown = true` and `placedAt = rawChangedAt`, the moment the reading first changed rather than when the debounce finished.
    - `present` is the debounced state; `rawPresent` is the latest reading.
  - `drawPotStatus`: `formatStatus` builds the status text, padded to `STATUS_CHARS` (20) characters. The line is redrawn only when that text differs from `pot.shown`, which is what's currently on screen.
- At power-on, `setup()` records which pots are already present. Those pots show `Last brew: Unknown` until they are removed and put back. A pot that is absent at boot shows `Removed`, and its timer starts when it is placed.
- **Idle restart.** If no pot is placed or removed for `IDLE_RESTART_MS` (48 h), `restart()` restarts the sketch. In an office this happens over the weekend. Any present/removed edge on any pot updates `lastActivity`, and boot counts as activity.
  - On AVR, `restart()` uses `jmp 0`, a jump to the reset vector. This re-runs C startup, so globals and `millis()` start over, and then `setup()` runs again.
  - It deliberately doesn't use a watchdog reset. Nanos with the old bootloader get stuck in a reset loop after one.
  - On ESP32 it calls `ESP.restart()`. `setup()` also calls `enableLoopWDT()`, which reboots the board if `loop()` stops returning for about 5 s. Don't add long blocking work to `loop()`.
  - To test it, temporarily set `IDLE_RESTART_MS` to something like `30000UL`.
- Elapsed time uses unsigned `now - placedAt`, so it stays correct across the 49.7-day `millis()` rollover. The only limit is a single pot sitting for more than 49.7 days.
- Screen layout: title at y=12 (Font24). Pot rows start at y=50 and are 60 px apart. Each row has the name (Font20, green) at `y`, the status at `y+25`, and a divider at `y+53`.
- Colors are **RGB565** (`COLOR_BG 0x18E3`, `COLOR_TEXT 0xC618`, `STARBUCKS_GREEN 0x07E0`).

## Constraints and gotchas

- **There is no framebuffer.** `Paint_NewImage` only stores dimensions. Every `Paint_*` call writes pixels directly to the LCD over SPI: `Paint_SetPixel` → `LCD_DrawPaint`, one pixel at a time. This is slow on the Nano, so redraw only what changed.
- **Erase by overdrawing.** Text is drawn with an explicit background color, which repaints every glyph cell. Updates overwrite old text in place instead of clearing first. That's why `formatStatus` pads every status to a fixed width with spaces. At 20 chars × 14 px from x=15, the line ends at x=295, inside the 320 px screen. Clearing with `LCD_ClearWindow` causes visible flicker, which is why those calls are commented out.
  - Passing `FONT_BACKGROUND` (WHITE) as the background switches to transparent mode. In that mode old text is not erased.
- **2 KB of SRAM.**
  - Put constant data in PROGMEM and read it with `pgm_read_byte`.
  - Use `char` buffers, not `String`. The sketch doesn't use the heap at all.
  - Use `F("...")` for Serial literals.
  - Avoid large stack buffers.
- **On AVR, `int` is 16 bits and `long` is 32 bits.** `sprintf` arguments must match the format exactly: `%d` takes an `int`, and `%ld`/`%lu` take a `long`/`unsigned long`. Cast where needed (see `formatStatus`). Never store `millis()`-derived values in an `int`, because it overflows after 32,767. AVR `sprintf` doesn't support `%f`.
- **Text width.** Font20 is 14 px wide, so a line starting at x=15 fits about 21 characters. `Paint_DrawString_EN` wraps silently when a line is too long.
- **`millis()` arithmetic** uses unsigned subtraction, so it handles rollover. Keep it that way.
- **Nano pins:**
  - In use: D7 DC, D8 RST, D9 BL (PWM), D10 CS, D11 MOSI, D13 SCK, D2–D4 sensors.
  - Free: D5, D6, D12, A0–A7.
  - Its 5 V logic drives a 3.3 V display, which is out of spec but works.
- **ESP32-S3-Zero pins** are raw GPIO numbers:
  - In use: 7 BL, 8 RST, 9 DC, 10 CS, 11 MOSI, 12 SCK, 4–6 sensors.
  - Free on the edge headers: 1, 2, 3 (strapping pin), 13, and TX/RX (43/44).
  - GPIO14–16 (front) and 17, 18, 38–42, 45 (back) are **solder pads only**, not header pins. Don't assign them unless you're willing to solder wires to pads.
  - The core's default SPI pins for this board (34–37) **are not brought out**. That's why `SPI.begin(sck, miso, mosi, ss)` passes pins explicitly.
  - Avoid the strapping pins 0, 3, 45 and 46. Avoid 21 (onboard WS2812 LED) and 43/44 (UART0).
  - GPIOs are 3.3 V only.
- **Portability:**
  - Include `<Arduino.h>` for `PROGMEM`/`pgm_read_byte`, not `<avr/pgmspace.h>`, which doesn't exist on ESP32.
  - Keep includes outside `extern "C"` blocks.
  - Guard AVR-only code (such as `asm`) with `#if defined(ARDUINO_ARCH_ESP32)` / `#else`.

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
- Use 2-space indent in the `.ino`. Leave the Waveshare files in their original style.
