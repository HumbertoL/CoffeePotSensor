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

---

## ⚡ Running on ESP8266 (e.g., Wemos D1 Mini)

It works and with some performance benefits!

### Key differences:

- You'll need to adjust the pins (D1, D2, etc.) in `DEV_Config.h`
- You'll need to set the SPI Frequency (around 10-20MHz)

| LCD Pin | Wemos D1 Mini | GPIO   |
| ------- | ------------- | ------ |
| VCC     | 3V3           |        |
| GND     | G             |        |
| DIN     | D7            | GPIO13 |
| CLK     | D5            | GPIO14 |
| CS      | D2            | GPIO4  |
| DC      | D1            | GPIO5  |
| RST     | D4            | GPIO2  |
| BL      | D6 (optional) | GPIO12 |


**Benefits:**
- Faster screen refresh
- More breathing room for fun features
- Lower power usage

---

## 📝 Legal Stuff

_Brew-em-all™ is not a medical device._  
Freshness estimates are for entertainment purposes only.  
Batteries not included (because there aren’t any).  
Not compatible with smart homes, dumb homes, or homes with any standards at all.  
Do not taunt Brew-em-all™.  
Side effects may include prolonged eye contact with LCDs and the urge to refactor code at 2 AM.
