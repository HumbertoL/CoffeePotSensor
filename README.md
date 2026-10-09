# ☕ brew-em-all™

## What is this?

Have you ever gone into the kitchen, hoping for a fresh cup of Joe… but left wondering if it's today’s dark roast or yesterday’s regret?

Introducing: **Brew-em-all™**

The no-nonsense, caffeine-loving gadget that finally answers the question:

**“How long has that pot been sitting there?”**

Built on an Arduino Nano with a whopping **2 KB of memory** and a blazingly slow **16 MHz** processor, a brain no more powerful than the one inside that *Tamagotchi you forgot to feed in 1998.*  
That’s not a typo. That’s **kilobytes**, baby.

Despite its prehistoric specs, this little gizmo tracks **three coffee pots** simultaneously, updating a full-color LCD every 3 seconds. Or, you know, whenever it feels like it.

✨ **Features include:**

- Absolutely no connectivity  
- No cloud, no ads, no cookie banners  
- No touchscreen. Not even a single button  
- Just raw, bare-metal code doing the job like it’s 1986  

Is it elegant? *No.*  
Is it smart? *Also no.*  
But does it work? *Debatable.*  

**Order yours today!**

[![brew-em-all](http://img.youtube.com/vi/xJZB41Rl86o/0.jpg)](http://www.youtube.com/watch?v=xJZB41Rl86o "brew-em-all")

---

## 🧠 Hardware

- **Microcontroller**: Arduino Nano  
  - 32 KB flash, 2 KB SRAM, 16 MHz ATmega328P
- **Display**: Waveshare 2-inch Mini LCD Screen  
  - 240x320 Resolution IPS LCD  
  - 262K RGB color  
  - SPI interface  
  - Driver: **ST7789VW**  
  - [Product Link](https://www.waveshare.com/wiki/2inch-LCD-Module)

---

## 🔌 Wiring

### Arduino Nano Pinout

| LCD Pin | Arduino Nano |
|---------|---------------|
| VCC     | 5V            |
| GND     | GND           |
| DIN     | D11           |
| CLK     | D13           |
| CS      | D10           |
| DC      | D7            |
| RST     | D8            |
| BL      | D9 (optional) |

> **Note:** This screen was designed for 3.3V logic. The Nano outputs 5V on its GPIOs, so technically this is out of spec. Many users (including this one) report the display works anyway, but for long-term reliability you might consider using logic level shifters.

### Pot Sensors

| Pot    | Arduino Nano |
|--------|--------------|
| Medium | D2           |
| Dark   | D3           |
| Decaf  | D4           |

Each sensor must pull its pin **LOW when a pot is on the burner** and HIGH when it isn't. Any digital sensor that does this will work, such as an IR proximity module or a microswitch to GND.

The pins are configured as plain `INPUT`, with no internal pull-up. If you use a bare switch, either add an external pull-up resistor (about 10 kΩ to 5V) or change `pinMode` to `INPUT_PULLUP` in `CoffeePotSensor.ino`.

The timer resets whenever a pot goes from *removed* to *present*. After a power cycle there's no way to know how old a pot already on the burner is, so it shows **Unknown** until it's removed and put back. A pot that's absent at power-on is treated as fresh when it's placed.

If no pot is placed or removed for **48 hours**, which in an office means the weekend, the device restarts itself to clear out any long-running state. Any pot still on the burner shows **Unknown** afterwards.

---

## 🛠️ Building & Flashing

**Arduino IDE:** open `CoffeePotSensor.ino`. Select **Tools → Board → Arduino Nano**. Some clones need **Processor → ATmega328P (Old Bootloader)**. Then click Upload.

**arduino-cli:**

```bash
arduino-cli compile --fqbn arduino:avr:nano .
arduino-cli upload  --fqbn arduino:avr:nano -p <port> .
```

No extra libraries are needed. The Waveshare driver, fonts and drawing code are included in the sketch folder. Serial debug output runs at **115200 baud**.

---

## ⚡ Running on ESP32-S3 (Waveshare ESP32-S3-Zero)

The same sketch builds for the [Waveshare ESP32-S3-Zero](https://www.waveshare.com/wiki/ESP32-S3-Zero), sold as the "ESP32-S3 Mini Development Board" with the ESP32-S3FH4R2 chip. No code changes are needed. The pins are picked automatically from the board you select.

| LCD Pin | ESP32-S3-Zero |
|---------|---------------|
| VCC     | 3V3           |
| GND     | GND           |
| DIN     | GPIO11        |
| CLK     | GPIO12        |
| CS      | GPIO10        |
| DC      | GPIO9         |
| RST     | GPIO8         |
| BL      | GPIO7         |

| Pot    | ESP32-S3-Zero |
|--------|---------------|
| Medium | GPIO4         |
| Dark   | GPIO5         |
| Decaf  | GPIO6         |

> ⚠️ **The ESP32-S3 runs on 3.3V and its pins are not 5V tolerant.** Power the sensors from **3V3**, or make sure their output never goes above 3.3V. Pull-up resistors go to 3V3, not 5V.

**Building:**
- In the Arduino IDE, select **Tools → Board → esp32 → Waveshare ESP32-S3-Zero**. This needs the esp32 board package, version 3.x.
- Leave **USB CDC On Boot** set to *Enabled*, its default, so serial output comes over the USB-C port.
- If the board doesn't show up as a port, hold **BOOT** while plugging it in.

```bash
arduino-cli compile --fqbn esp32:esp32:waveshare_esp32_s3_zero .
arduino-cli upload  --fqbn esp32:esp32:waveshare_esp32_s3_zero -p <port> .
```

**Benefits:**
- The display gets 3.3V logic, so it's in spec and needs no level shifters.
- A hardware watchdog reboots the board if it ever hangs.
- The SPI bus runs at 20 MHz, so the screen redraws faster.
- There's more breathing room for fun features.

---

## 📝 Legal Stuff

_Brew-em-all™ is not a medical device._  
Freshness estimates are for entertainment purposes only.  
Batteries not included (because there aren’t any).  
Not compatible with smart homes, dumb homes, or homes with any standards at all.  
Do not taunt Brew-em-all™.  
Side effects may include prolonged eye contact with LCDs and the urge to refactor code at 2 AM.
