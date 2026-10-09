# CLAUDE.md

Arduino sketch ("brew-em-all") that tracks how long each of three coffee pots has been sitting on its burner and shows it on a Waveshare 2" ST7789 SPI LCD. Main target: **Arduino Nano (ATmega328P, 2 KB SRAM, 32 KB flash)**. ESP8266 (Wemos D1 Mini) also works with config changes. See [README.md](README.md) for hardware and wiring.

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
- ESP8266 FQBN: `esp8266:esp8266:d1_mini`. The core is installed in `~/Library/Arduino15`.
- The sketch folder name must match `CoffeePotSensor.ino`. Arduino compiles every `.cpp` in the folder automatically.
- Baseline (Nano): about 18.6 KB flash (60%) and 583 B globals (28%). Check the compile output after every change and watch RAM closely.

## Layout

| File | Owner | Purpose |
|---|---|---|
| `CoffeePotSensor.ino` | **ours** | All app logic: `CoffeePot` struct, sensor polling, drawing |
| `DEV_Config.h/.cpp` | Waveshare (modified) | Pin defines, SPI/serial init, ESP8266 alternatives commented out |
| `LCD_Driver.h/.cpp` | Waveshare | ST7789 init, window/cursor and pixel writes. `LCD_WIDTH 320`, `LCD_HEIGHT 240` (landscape via MADCTL `0xA0`) |
| `GUI_Paint.h/.cpp` | Waveshare | Drawing primitives (`Paint_DrawString_EN`, `Paint_DrawLine`, …) |
| `font8/16/20/24.cpp`, `fonts.h` | Waveshare | Monospace bitmap fonts in PROGMEM. Widths: 5 / 11 / 14 / 17 px; heights: 8 / 16 / 20 / 24 |
| `image.cpp/.h` | Waveshare | 70×70 sample bitmap. Unused (the linker drops it) |
| `Debug.h` | Waveshare | `Debug()` macro. Not useful: AVR `printf` isn't wired to Serial |

Keep changes to the Waveshare files small. App behavior belongs in the `.ino`.

## How it works

- Each pot has a digital sensor on **D2/D3/D4**. The pin is **active LOW**, so LOW means a pot is present. The pins use `INPUT` with no internal pull-up.
- `loop()` runs every `REFRESH_INTERVAL` ms (100 ms). For each pot it does two things:
  - `updatePotStatus`: on a removed→present edge, it resets `placedAt = millis()`.
  - `drawPotStatus`: it redraws the time line only when the elapsed seconds change.
- A pot that is present at boot counts from boot.
- Screen layout: title at y=12 (Font24). Pot rows start at y=50 and are 60 px apart. Each row has the name (Font20, green) at `y`, the status at `y+25`, and a divider at `y+53`.
- Colors are **RGB565** (`COLOR_BG 0x18E3`, `COLOR_TEXT 0xC618`, `STARBUCKS_GREEN 0x07E0`).

## Constraints and gotchas

- **There is no framebuffer.** `Paint_NewImage` only stores dimensions. Every `Paint_*` call writes pixels directly to the LCD over SPI: `Paint_SetPixel` → `LCD_DrawPaint`, one pixel at a time. This is slow on the Nano, so redraw only what changed.
- **Erase by overdrawing.** Text is drawn with an explicit background color, which repaints every glyph cell. Updates overwrite old text in place instead of clearing first. That's why `"Removed           "` is padded with spaces: it has to cover the longer `"Last brew: …"` string. Clearing with `LCD_ClearWindow` causes visible flicker, which is why those calls are commented out.
  - Passing `FONT_BACKGROUND` (WHITE) as the background switches to transparent mode. In that mode old text is not erased.
- **2 KB of SRAM.**
  - Put constant data in PROGMEM and read it with `pgm_read_byte`.
  - Prefer `char` buffers over `String`. `formatElapsedTime` currently returns `String`.
  - Use `F("...")` for Serial literals.
  - Avoid large stack buffers.
- **On AVR, `int` is 16 bits.** `formatElapsedTime` passes an `unsigned long` to `%02d`. This only prints correctly because of AVR's little-endian varargs layout. Cast to `int` or use `%lu` if you touch it.
- **Text width.** Font20 is 14 px wide, so a line starting at x=15 fits about 21 characters. `Paint_DrawString_EN` wraps silently when a line is too long.
- **`millis()` arithmetic** uses unsigned subtraction, so it handles rollover. Keep it that way.
- **5 V logic on the Nano** drives a 3.3 V display (out of spec, but it works). Pins already in use: D7 DC, D8 RST, D9 BL (PWM), D10 CS, D11 MOSI, D13 SCK, D2–D4 sensors. Free: D5, D6, D12, A0–A7.

## Porting to ESP8266

1. In `DEV_Config.h`, comment out the UNO pin block and enable the ESP8266 block.
2. In `DEV_Config.cpp`, uncomment `SPI.setFrequency(...)` and set it to 10–20 MHz.
3. Move the pot sensor pins too: D2–D4 on a Wemos are different GPIOs, and some are boot-strapping pins.

## Conventions

- Commit messages use conventional prefixes: `feat:`, `fix:`, `refactor:`, `docs:`.
- Use 2-space indent in the `.ino`. Leave the Waveshare files in their original style.
