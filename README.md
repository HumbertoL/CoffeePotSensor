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
tools/flash.sh
```

`tools/flash.sh` builds the Netlify zip (below) and flashes the exact same firmware over USB, so the board's version matches the deployed one. Then deploy the zip. **Don't flash from the Arduino IDE** once updates are set up: an IDE build is version 0, so the board replaces it with whatever is on Netlify within a few minutes, including that build's Wi-Fi settings. `tools/compile.sh` only compiles (bundled arduino-cli, right partition scheme).

---

## 📡 Publishing to ThingSpeak

The board can send each pot's state to ThingSpeak channel **3533214**.

**Setup:**
1. Copy the template and fill in the Wi-Fi name and password, plus the channel's **Write API Key** (ThingSpeak → the channel → API Keys):
   ```bash
   cp secrets.example.h secrets.h
   ```
   `secrets.h` is gitignored. Without it the sketch still builds, with publishing off.
2. In the channel's settings, turn on **Field 1–7** and name them Medium, Dark, Decaf, Firmware, Wi-Fi signal, Free memory and Uptime. ThingSpeak silently drops fields that aren't turned on.
3. Flash the board. The serial monitor shows `[thingspeak] entry N` for each accepted entry.

**What's sent:** one entry at boot, one each time a pot is placed or removed (after the debounce), one after each Slack post or dashboard command, and a heartbeat after 30 minutes without any of those. Each entry has all three pots:

| Field | Pot | Value |
|---|---|---|
| `field1` | Medium | The Unix time (UTC seconds) the pot was placed. **0** if it's there but its age is unknown (it was already there at power-on). **-1** if it's removed |
| `field2` | Dark | Same |
| `field3` | Decaf | Same |
| `field4` | | The board's firmware version |
| `field5` | | Wi-Fi signal strength (RSSI, dBm). About -50 is great, below -80 is poor |
| `field6` | | The lowest free memory since the board started (KB), to spot leaks |
| `field7` | | Uptime (hours), to spot restarts |
| `status` | | What happened: `Dark placed`, `Started v39 (power-on)` (the reason the board restarted: power-on, crash, watchdog, brownout, idle restart…), `Updated v39 → v40` after an over-the-air update, `Update to v40 failed (-104)`, `Slack: Dark posted` / `Slack: Dark failed (-1)`, `Dark time set`. Empty for a heartbeat |

The age of a pot is the entry's time minus its field. For example, the latest Dark value is at `https://api.thingspeak.com/channels/3533214/fields/2/last.json` (add `?api_key=<Read API Key>` if the channel is private).

**Notes:**
- Sending runs in its own task, so a slow or missing network never holds up the screen or the sensors.
- ThingSpeak's free plan takes one update every 15 s. Changes that come faster are merged into one entry, with both notes in `status`. Failed sends are retried every 30 s.
- The connection is HTTPS, checked against the root certificates in `thingspeak_root_ca.h`. The clock comes from NTP (`pool.ntp.org`), so the network has to allow it.
- `SENSOR_TEST` mode publishes nothing.

---

## 💬 Fresh-pot messages in Slack

When a pot is placed on a **Tuesday, Wednesday or Friday between 8:00 am and 5:30 pm** (Central), the board posts to Slack, for example:

> :coffee: Fresh pot of **Dark** on the rack (brewed 2:29 PM)

Pots placed outside those hours (usually put back after cleaning) aren't announced. The days and times are `SLACK_DAYS`, `SLACK_FROM_MIN` and `SLACK_UNTIL_MIN` at the top of `CoffeePotSensor.ino`.

The board posts straight to a Slack **incoming webhook**, which works on every Slack plan; nothing else is hosted. Each post (or failure, after three tries 30 s apart) shows up as a ThingSpeak status, so it's in the dashboard's activity list. HTTPS to Slack is checked against the same roots as ThingSpeak (`thingspeak_root_ca.h`; Slack chains to ISRG Root X1).

Setup: create a Slack app at api.slack.com/apps, turn on **Incoming Webhooks**, add one for the channel, and put its address in `secrets.h` as `SLACK_WEBHOOK_URL`. It's a secret (anyone with it can post to the channel), so it never goes in the repo. A new firmware build carries it to the board over the air.

---

## 🚀 Firmware updates and the dashboard

The board updates itself over Wi-Fi from a Netlify site, which also hosts a simple dashboard (`dashboard/index.html`): each pot's age, the board's last update and firmware version, and recent activity, read from the ThingSpeak channel.

**How updates work:** 2 minutes after boot and then every hour, the board reads `<OTA_BASE_URL><OTA_FILE_NAME>.version`. If that number is higher than its own version, it downloads `<OTA_FILE_NAME>.bin`, installs it and restarts, showing "Updating..." in the header meanwhile. Pots that stay on the rack keep their ages across the restart (once the clock is set again). Both downloads use HTTPS, checked against `ota_root_ca.h`.

**The firmware contains the Wi-Fi password and the ThingSpeak key**, so its file name is a random UUID, and the UUID and site address live only in the gitignored `secrets.h` (`OTA_FILE_NAME`, `OTA_BASE_URL`). This repo is public: never commit them, and don't link the `.bin` from anywhere.

**Publishing a new version:**
1. Commit the firmware changes (the build refuses uncommitted firmware, and `SENSOR_TEST` must be 0). The version number is the repo's commit count.
2. Run `tools/build_netlify.sh`. It writes `dist/netlify-deploy.zip` (gitignored) with `index.html`, `<uuid>.bin` and `<uuid>.version`.
3. Drag the zip onto the site's **Deploys** page on Netlify.

The board picks it up within the hour and posts `Updated v39 → v40` to the activity list (or `Update to v40 failed (code)`). The dashboard shows the deployed version next to the version the board reports.

**Fixing a pot's time from the dashboard:** after a restart, pots that were on the rack show **?**. The dashboard's "Fix a pot's time" section can send the board the brew time it last reported before the restart (**Restore**), or a time you enter. It goes through a ThingSpeak **TalkBack** queue, which the board checks every 20 seconds; only pots on the rack can be set, and the board posts a note like `Dark time set` or `Dark time not set (not on the rack)`.

The section shows up only in a browser that has the TalkBack API key. Share it as a link: `https://<site>/#key=<TalkBack API key>` (or `?key=`). The dashboard saves the key in that browser and removes it from the address bar; **Settings → Copy share link** makes one. Anyone with the link can set pot times, so share it only with people who should.

Setup: in ThingSpeak, **Apps → TalkBack → New TalkBack**. Put its ID in `TALKBACK_ID` in `dashboard/index.html`, and its ID and API key in `secrets.h` (`TS_TALKBACK_ID`, `TS_TALKBACK_KEY`). Then flash with `tools/flash.sh` and deploy the zip.

**First-time setup:**
1. Run `tools/build_netlify.sh` and drop the zip on Netlify to create the site. Note its address.
2. Put the address in `secrets.h` as `OTA_BASE_URL` (like `"https://name.netlify.app/"`).
3. Flash the board once over USB with `tools/flash.sh`, and deploy the zip it builds. From then on it updates itself.

A build from the Arduino IDE is version 0, so the board replaces it with the published firmware at its next check. Use `tools/flash.sh` instead. To test uncommitted changes on the board, leave `OTA_BASE_URL` empty while you do.

**Changing `secrets.h`** (for example the Wi-Fi password) doesn't change the version, which comes from the commit count. A board can't pick that up over the air, so flash it with `tools/flash.sh` and deploy the new zip, so Netlify doesn't keep serving the old settings.

---

## 📝 Legal Stuff

_Brew-em-all™ is not a medical device._  
Freshness estimates are for entertainment purposes only.  
Batteries not included (because there aren’t any).  
Not compatible with smart homes, dumb homes, or homes with any standards at all.  
Do not taunt Brew-em-all™.  
Side effects may include prolonged eye contact with LCDs and the urge to refactor code at 2 AM.
