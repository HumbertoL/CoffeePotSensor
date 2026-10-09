# Hardware Notes

This is everything known so far about the physical build: the parts, how they're wired and powered, and the plans for the next version. Anything not confirmed is marked *(unverified)*.

## Physical setup

- **Mounting:** the device mounts on the **wall behind the coffee pots**. The sensors face forward at the backs of the pots.
- **Three pots, left to right:** Medium, Dark, Decaf. Each pot has one sensor.
- **Current build:** everything is in one 3D-printed shell: the microcontroller, the display, and all three sensors. The wiring inside it is messy.
- **Planned redesign:** split it into two parts, joined by one cable.
  - **Sensor rod:** a slim bar holding the three sensors, hanging down to the height of the pots.
  - **Brain box:** a small box higher up on the wall with the ESP32-S3-Zero and the display.

## Display: Waveshare 2inch LCD Module

[Wiki](https://www.waveshare.com/wiki/2inch-LCD-Module)

| | |
|---|---|
| Panel | IPS, 240×320, 262K colors |
| Driver | ST7789VW |
| Interface | 4-wire SPI (write-only, no MISO) |
| Operating voltage | 3.3 V or 5 V |
| Display area | 30.60 × 40.80 mm |
| Pixel pitch | 0.0975 mm |
| Module size | 58.0 × 35.0 mm, with standoffs at the four corners |
| Connectors | 8-pin header and an 8-pin cable connector, both carrying VCC, GND, DIN, CLK, CS, DC, RST, BL |

**How the firmware drives it** (`LCD_Driver.cpp`):
- **Orientation:** landscape, 320 × 240. The init command `0x36 = 0xA0` rotates the panel.
- **Color format:** 16-bit RGB565 (`0x3A = 0x05`).
- **Color inversion:** turned on (`0x21`). IPS panels need this for colors to come out right.
- **Backlight:** dimmed with PWM, set to `80`/255 in `DEV_Config.cpp`.
- **SPI mode:** mode 3. The clock runs at 8 MHz on the Nano and 20 MHz on the ESP32-S3. The ST7789 itself can go faster than that.
- **Drawing:** the code doesn't keep a copy of the screen in memory. Every pixel is written straight to the display.

## Microcontrollers

### Arduino Nano (current)

- ATmega328P chip at 16 MHz, with 2 KB of RAM and 32 KB of flash.
- Its pins run at 5 V, but the display expects 3.3 V. This is out of spec, but it works in practice.
- It uses the old Nano bootloader *(unverified)*. That's why the idle restart avoids a watchdog reset; see CLAUDE.md.

### Waveshare ESP32-S3-Zero (replacing the Nano)

[Wiki](https://www.waveshare.com/wiki/ESP32-S3-Zero). It's also sold as the "ESP32-S3 Mini Development Board".

- **Chip:** ESP32-S3FH4R2, a dual-core 240 MHz processor with 4 MB of flash, 2 MB of PSRAM, Wi-Fi and BLE 5.
- **USB:** native USB-C only, with no USB-to-serial chip. To force download mode, hold **BOOT** while plugging it in.
- **Pins are 3.3 V only and not 5 V tolerant.**
- **3V3(OUT):** this pin is fed by the onboard regulator, rated for up to 800 mA.
- **Onboard RGB LED:** a WS2812 on GPIO21.
- **Header pins vs. solder pads:** only some GPIOs are on the edge headers.
  - Left header: 5V, GND, 3V3, GP1–GP6.
  - Right header: TX (43), RX (44), GP13–GP7.
  - **Solder pads only:** GP14–16 on the front; GP17, 18, 38–42 and 45 on the back.
- **Avoid:** GPIO0 and GPIO3 (they affect how the chip boots), 21 (the RGB LED), and 43/44 (the serial port).

## Wiring

| Signal | Nano | ESP32-S3-Zero |
|---|---|---|
| LCD VCC | 5V | 3V3(OUT) |
| LCD GND | GND | GND |
| LCD DIN (MOSI) | D11 | GPIO11 |
| LCD CLK (SCK) | D13 | GPIO12 |
| LCD CS | D10 | GPIO10 |
| LCD DC | D7 | GPIO9 |
| LCD RST | D8 | GPIO8 |
| LCD BL | D9 (PWM) | GPIO7 |
| Medium sensor OUT | D2 | GPIO4 |
| Dark sensor OUT | D3 | GPIO5 |
| Decaf sensor OUT | D4 | GPIO6 |
| Sensor VCC | 5V | **3V3 only** |
| Sensor GND | GND | GND |

On the ESP32-S3-Zero, all of these pins are on the edge headers, so none of the solder pads are needed. The display connects to the right header (GP7–12), and the sensors connect to the left header (GP4–6, next to 3V3 and GND).

## Pot sensors: IR reflection modules *(type inferred from the code)*

These are most likely FC-51 or TCRT5000-style IR obstacle modules. Each module has:
- an IR LED and a photodiode facing forward,
- an LM393 comparator chip,
- a sensitivity screw, and
- an indicator LED.

When enough IR bounces back, the comparator pulls OUT **LOW**. The firmware treats LOW as "pot present".

- **Power:** 3.3–5 V. On the ESP32 they **must** run from 3V3. The module's output pull-up goes to its own supply voltage, so at 5 V it would put 5 V on the ESP32's pins. At 3.3 V the range is a little shorter, so re-tune the sensitivity screw.
- **Current:** about 20–30 mA each, mostly the LEDs. Three of them draw well under 100 mA.
- **Pull-up:** the module has one built in, so the pins are plain `INPUT`.
- **Reliability caveats:**
  - Readings depend on the pot's surface: glass, shiny steel and dark plastic all reflect differently.
  - They also depend on distance and angle, and on ambient IR such as sunlight.
  - A sensor tuned right at its threshold will flicker.
- **Firmware debounce:** a pot counts as placed after 1 s of steady "present", and as removed after 3 s of steady "absent". A hand passing by or a brief dropout won't reset the timer.

## Planned sensor rod wiring

The sensors only produce three on/off signals, so the rod needs **one 5-wire cable**: 3V3, GND, and the three outputs. A second microcontroller or an I2C bus isn't needed.

- **On the rod:** mount the three modules on one strip of perfboard. Run a shared 3V3 rail and a shared GND rail along it.
- **Cable:** Ethernet cable is a good fit. It has 8 wires, so 3 are spare for a fourth sensor. It's cheap, comes in any length, and RJ45 jacks on both ends make the rod detachable.
- **Length:** plain on/off signals like these are reliable over 1–2 m. The firmware debounce absorbs occasional noise.
- **Code:** nothing changes.

## Firmware behavior that depends on the hardware

- **Power-on:** a pot already on the burner at power-on shows **Unknown**. Its timer starts the next time it's put back.
- **Idle restart:** with no pot activity for 48 h (a weekend), the device restarts itself.
- **ESP32 watchdog:** the ESP32 also has a hardware watchdog that reboots it if the firmware hangs.
