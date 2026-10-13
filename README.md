# ☕ brew-em-all™

## What is this?

Have you ever gone into the kitchen, hoping for a fresh cup of Joe… but left wondering if it's today’s dark roast or yesterday’s regret?

Introducing: **Brew-em-all™**

The no-nonsense, caffeine-loving gadget that finally answers the question:

**“How long has that pot been sitting there?”**

It started life on an Arduino Nano with a whopping **2 KB of memory** and a blazingly slow **16 MHz** processor, a brain no more powerful than the one inside that *Tamagotchi you forgot to feed in 1998.*  
It has since been promoted to an ESP32-S3, which is roughly the coffee equivalent of switching from instant to pour-over.

It tracks **three coffee pots** simultaneously and shows how old each one is on a full-color LCD.

✨ **Features include:**

- How long each pot has been sitting there, color-coded from fresh to regret
- When each pot was brewed
- Wi-Fi, so ThingSpeak knows about your coffee too
- No touchscreen. Not even a single button

Is it elegant? *Getting there.*  
Is it smart? *Smarter than it was.*  
But does it work? *Debatable.*  

**Order yours today!**

[![brew-em-all](http://img.youtube.com/vi/xJZB41Rl86o/0.jpg)](http://www.youtube.com/watch?v=xJZB41Rl86o "brew-em-all")

---

## 🧠 Hardware

- **Microcontroller**: [Waveshare ESP32-S3-Zero](https://www.waveshare.com/wiki/ESP32-S3-Zero), sold as the "ESP32-S3 Mini Development Board" (ESP32-S3FH4R2: 4 MB flash, 2 MB PSRAM, Wi-Fi)
- **Sensors**: 3× IR reflection (obstacle) modules, active LOW
- **Display**: Waveshare 2-inch Mini LCD Screen  
  - 240x320 Resolution IPS LCD  
  - 262K RGB color  
  - SPI interface  
  - Driver: **ST7789VW**  
  - [Product Link](https://www.waveshare.com/wiki/2inch-LCD-Module)

The original Arduino Nano version is no longer supported. It's in git history up to commit `63bcd10`.

See [docs/HARDWARE.md](docs/HARDWARE.md) for full part details, sensor notes, power and the case. Ideas on the roadmap are in [docs/FUTURE_WORK.md](docs/FUTURE_WORK.md).

---

## 🔌 Wiring

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

Each sensor must pull its pin **LOW when a pot is on the rack** and HIGH when it isn't. Any digital sensor that does this will work, such as an IR proximity module or a microswitch to GND. The pins are plain `INPUT`, with no internal pull-up; with a bare switch, add an external pull-up (about 10 kΩ to 3V3) or use `INPUT_PULLUP`.

---

## 🖥️ The screen

A header shows the title, the time and the network status. Below it, each pot gets a row with its age, when it was brewed, and a bar that empties as it gets older:

| Age | Color | Word |
|---|---|---|
| Under 90 minutes (`FRESH_MIN`) | Green | Fresh |
| 90 minutes to 4 hours (`OLD_MIN`) | Amber | OK |
| 4 hours and up | Red | Old |

A removed pot shows **–** ("Not on the rack"). The timer restarts whenever a pot goes from *removed* to *present*. After a power cycle there's no way to know how old a pot already on the rack is, so it shows **?** ("There since power-on") until it's removed and put back. A pot that's absent at power-on is treated as fresh when it's placed. Ages go up to hundreds of hours for the pot nobody drinks.

The network icon (only with a `secrets.h`): white Wi-Fi means connected; amber means connecting; gray with a red slash means offline for a minute or more; white with an amber **!** means Wi-Fi works but ThingSpeak isn't taking uploads. The time and "Brewed 2:29 pm" appear once the clock is set from the network (US Central time, `TIME_ZONE` in `publish.cpp`).

If no pot is placed or removed for **48 hours**, which in an office means the weekend, the device restarts itself to clear out any long-running state. Any pot still on the rack shows **?** afterwards.

---

## 🛠️ Building & Flashing

- Install the **esp32** board package (version 3.x) and the **LovyanGFX** library (Library Manager, or `arduino-cli lib install LovyanGFX`).
- In the Arduino IDE, select **Tools → Board → esp32 → Waveshare ESP32-S3-Zero**, and **Tools → Partition Scheme → Minimal SPIFFS (1.9MB APP with OTA/128KB SPIFFS)**. The partition scheme matters: the board can only update itself over Wi-Fi with firmware built for the same scheme it was last flashed with over USB.
- Leave **USB CDC On Boot** set to *Enabled*, its default, so serial output (115200 baud) comes over the USB-C port.
- If the board doesn't show up as a port, hold **BOOT** while plugging it in.

```bash
tools/compile.sh
arduino-cli upload --fqbn esp32:esp32:waveshare_esp32_s3_zero:PartitionScheme=min_spiffs --input-dir "$TMPDIR/coffeepot_build" -p <port>
```

`tools/compile.sh` uses the arduino-cli bundled with the Arduino IDE and the right partition scheme.

---

## 📡 Publishing to ThingSpeak

The board can send each pot's state to ThingSpeak channel **3533214**.

**Setup:**
1. Copy the template and fill in the Wi-Fi name and password, plus the channel's **Write API Key** (ThingSpeak → the channel → API Keys):
   ```bash
   cp secrets.example.h secrets.h
   ```
   `secrets.h` is gitignored. Without it the sketch still builds, with publishing off.
2. In the channel's settings, turn on **Field 1–4** and name them Medium, Dark, Decaf and Firmware. ThingSpeak silently drops fields that aren't turned on.
3. Flash the board. The serial monitor shows `[thingspeak] entry N` for each accepted entry.

**What's sent:** one entry at boot and one each time a pot is placed or removed (after the debounce). Each entry has all three pots:

| Field | Pot | Value |
|---|---|---|
| `field1` | Medium | The Unix time (UTC seconds) the pot was placed. **0** if it's there but its age is unknown (it was already there at power-on). **-1** if it's removed |
| `field2` | Dark | Same |
| `field3` | Decaf | Same |
| `field4` | | The board's firmware version |
| `status` | | What changed, like `Dark placed`, or `Started` at boot |

The age of a pot is the entry's time minus its field. For example, the latest Dark value is at `https://api.thingspeak.com/channels/3533214/fields/2/last.json` (add `?api_key=<Read API Key>` if the channel is private).

**Notes:**
- Sending runs in its own task, so a slow or missing network never holds up the screen or the sensors.
- ThingSpeak's free plan takes one update every 15 s. Changes that come faster are merged into one entry, with both notes in `status`. Failed sends are retried every 30 s.
- The connection is HTTPS, checked against the root certificates in `thingspeak_root_ca.h`. The clock comes from NTP (`pool.ntp.org`), so the network has to allow it.
- `SENSOR_TEST` mode publishes nothing.

---

## 🚀 Firmware updates and the dashboard

The board updates itself over Wi-Fi from a Netlify site, which also hosts a simple dashboard (`dashboard/index.html`): each pot's age, the board's last update and firmware version, and recent activity, read from the ThingSpeak channel.

**How updates work:** 2 minutes after boot and then every hour, the board reads `<OTA_BASE_URL><OTA_FILE_NAME>.version`. If that number is higher than its own version, it downloads `<OTA_FILE_NAME>.bin`, installs it and restarts, showing "Updating..." in the header meanwhile. Pots that stay on the rack keep their ages across the restart (once the clock is set again). Both downloads use HTTPS, checked against `ota_root_ca.h`.

**The firmware contains the Wi-Fi password and the ThingSpeak key**, so its file name is a random UUID, and the UUID and site address live only in the gitignored `secrets.h` (`OTA_FILE_NAME`, `OTA_BASE_URL`). This repo is public: never commit them, and don't link the `.bin` from anywhere.

**Publishing a new version:**
1. Commit the firmware changes (the build refuses uncommitted firmware, and `SENSOR_TEST` must be 0). The version number is the repo's commit count.
2. Run `tools/build_netlify.sh`. It writes `dist/netlify-deploy.zip` (gitignored) with `index.html`, `<uuid>.bin` and `<uuid>.version`.
3. Drag the zip onto the site's **Deploys** page on Netlify.

The board picks it up within the hour. The dashboard shows the deployed version next to the version the board reports.

**First-time setup:**
1. Run `tools/build_netlify.sh` and drop the zip on Netlify to create the site. Note its address.
2. Put the address in `secrets.h` as `OTA_BASE_URL` (like `"https://name.netlify.app/"`).
3. Flash the board once over USB with the Minimal SPIFFS partition scheme. From then on it updates itself.

A build from the Arduino IDE is version 0, so the board replaces it with the published firmware at its next check. To test local changes on the board, leave `OTA_BASE_URL` empty while you do.

---

## 📝 Legal Stuff

_Brew-em-all™ is not a medical device._  
Freshness estimates are for entertainment purposes only.  
Batteries not included (because there aren’t any).  
Not compatible with smart homes, dumb homes, or homes with any standards at all.  
Do not taunt Brew-em-all™.  
Side effects may include prolonged eye contact with LCDs and the urge to refactor code at 2 AM.
