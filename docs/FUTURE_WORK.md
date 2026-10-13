# Future Work

These are ideas worth following up on. They're for the **ESP32-S3-Zero**, which is now the only supported board.

## 1. Time-of-flight (ToF) laser distance sensors

**Goal:** replace the IR reflection modules with sensors that measure the real distance to each pot.

**Why:**
- The cutoff distance (for example "pot within 80 mm") is set in code. You can retune it without touching the rod or a sensitivity screw.
- Color and room light barely affect it.
- It can tell "pot pushed all the way back" from "pot pulled forward".

**Candidate parts**

| Sensor | Range | Notes |
|---|---|---|
| VL53L0X | ~2 m | Cheap and common. ~25° field of view |
| VL53L1X | ~4 m | Field of view can be narrowed in software, which helps keep each sensor from seeing the neighboring pot |

Both come on 3.3 V breakout boards and talk over I2C. Pololu's `VL53L0X` / `VL53L1X` Arduino libraries are the usual choice.

**Things to solve**
- **They all share one I2C address (0x29).** Two ways around it:
  - Wire each sensor's **XSHUT** (shutdown) pin to its own GPIO. At boot, wake them one at a time and give each a new address. Rod cable: 3V3, GND, SDA, SCL and 3× XSHUT, which is **7 wires**. That fits in an Ethernet cable, with 1 spare.
  - Or put a TCA9548A I2C multiplexer on the rod. That keeps the cable at 4 wires, but adds a part.
- **I2C over a cable.** I2C is designed for short connections inside a device. For a run of 1–2 m:
  - keep the bus at 100 kHz,
  - use stronger pull-up resistors (2.2–4.7 kΩ),
  - put SDA and SCL on separate twisted pairs, each paired with GND.
  - If it's still unreliable, add a bus extender such as the P82B715.
- **Glass carafes** can still fool it: the laser can pass through or bounce off glass. Test with the actual pots before committing to it.
- **Code changes:**
  - `isPotPresent()` becomes "distance < threshold", with a separate threshold per pot.
  - The existing debounce in `updatePotStatus` stays as is.
  - Make sure sensor reads don't block `loop()` long enough to trip the ESP32 watchdog (about 5 s). Use the libraries' continuous / non-blocking mode.
- **Free pins for XSHUT** on the ESP32-S3-Zero headers: GPIO1, 2 and 13. Avoid GPIO3, which affects how the chip boots. See [HARDWARE.md](HARDWARE.md).

## 2. OTA (over-the-air) firmware updates: done

Done on 2026-10-13: the board pulls new firmware from the Netlify site (HTTPUpdate over HTTPS, checked hourly). See README.md, "Firmware updates and the dashboard", and `ota.cpp`.

## 3. Fresh-pot animation (GIF / video)

**Goal:** play a short animation on the display when a fresh pot is detected.

**Feasibility**
- **ESP32-S3: yes.**
  - 4 MB of flash. The board now uses the "Minimal SPIFFS" partition scheme for OTA: two 1.9 MB app slots (the firmware is about 1.1 MB, so roughly 800 KB is free for GIFs compiled in) and only 128 KB of file storage.
  - 2 MB of PSRAM for decoding.

**Formats**

| Format | Library | Notes |
|---|---|---|
| **Animated GIF** (recommended) | [AnimatedGIF](https://github.com/bitbank2/AnimatedGIF) (bitbank2) | Decodes one line at a time with very little RAM. Widely used with ST7789 on ESP32. A short loop is typically 50–500 KB, so several fit in flash |
| MJPEG video | [JPEGDEC](https://github.com/bitbank2/JPEGDEC) (bitbank2) | Works, but at 320×240 the free space holds only a second or two of video |

**Display driver: already done.** The screen now uses LovyanGFX (`ui.cpp`), which sends whole blocks of pixels with DMA. That's the usual pairing with AnimatedGIF: its draw callback hands over one line at a time, which maps onto `lcd.pushImage`. Expect roughly 12–15 fps full screen at the current 20 MHz SPI, or about 25 fps at 40 MHz, and much faster for smaller regions.

**Fitting it into the firmware**
- **Trigger:** in `updatePotStatus`, where a debounced placement is confirmed (the `if (raw)` branch that sets `placedAt` and `timeKnown`). It can't tell a freshly brewed pot from one that was just set back down. Today's timer has the same limitation.
- **Where to play it.** Two options:
  - **Full screen** for 2–3 seconds, then redraw everything. To force the redraw, clear the content keys `ui.cpp` keeps for the header and rows (`shownHeader`, `shownRow`).
  - **A smaller region beside that pot's row,** so the other timers stay visible.
- **The watchdog and the sensors.** `enableLoopWDT()` reboots the board if `loop()` blocks for about 5 s, and sensors aren't read while an animation plays.
  - Either keep animations to a few seconds,
  - or play one frame per `loop()` pass so sensor polling continues between frames.
- **Storing the GIFs:**
  - **As a C array** in flash. This is simplest: no filesystem needed, and the GIF ships with the firmware.
  - **As files** in the LittleFS partition. This lets you swap GIFs without recompiling, but with "Minimal SPIFFS" it's only 128 KB; a bigger file system means a custom partition table (flashed over USB once).
