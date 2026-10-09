# Future Work

These are ideas worth following up on. None of them are started yet. Both items assume the **ESP32-S3-Zero**: the Nano has neither the memory nor the Wi-Fi for them.

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

## 2. OTA (over-the-air) firmware updates

**Goal:** update the firmware over Wi-Fi without taking the box off the wall and plugging in USB.

**What's already in place**
- The ESP32 board package (3.3.x) includes the `ArduinoOTA`, `Update`, `HTTPUpdate` and `WiFi` libraries.
- The S3-Zero's default partition scheme ("Default 4MB with spiffs") already reserves **two 1.25 MB app slots**. One holds the running firmware while the new one downloads into the other. The firmware is ~324 KB today. Wi-Fi and OTA add a few hundred KB, which still fits.
  - Don't pick the "No OTA" partition scheme.

**Options**

| Approach | How | Fits when |
|---|---|---|
| **ArduinoOTA (push)** | Upload from the Arduino IDE / `arduino-cli` to the device over the network. The device announces itself over mDNS | The office network allows mDNS and devices talking to each other directly |
| **HTTPUpdate (pull)** | The device downloads a `.bin` file from a URL and installs it | The office network blocks the above. It could check at boot, which pairs well with the existing 48 h weekend restart |

**Things to solve**
- **The watchdog.**
  - With `ArduinoOTA`, the whole upload happens inside one `ArduinoOTA.handle()` call. That trips the 5 s loop watchdog enabled in `setup()`.
  - Call `disableLoopWDT()` in `onStart` and turn it back on if the update fails.
  - `HTTPUpdate` has the same problem.
- **Wi-Fi credentials** must not be committed. Put them in a git-ignored `secrets.h`, and commit a `secrets.example.h` as a template.
- **Office Wi-Fi.** Check with IT before building this.
  - Many offices use WPA2-Enterprise logins or guest networks with a sign-in page. Those are hard or impossible for a microcontroller to join.
  - Ask whether there's an IoT network, or whether the device can be added to an allowed list by its MAC address.
- **Security.**
  - For `ArduinoOTA`, set a password (`ArduinoOTA.setPassword`).
  - For `HTTPUpdate`, use HTTPS, or at least check the file's checksum.
  - Otherwise anyone on the network could flash it.
- **Wi-Fi outages.** The firmware should keep working when Wi-Fi is down. Connect without blocking and never wait on Wi-Fi in `setup()`.
- **Progress on screen.** Show "Updating… NN%" on the LCD during an update (`onProgress`), so nobody unplugs it halfway through.
- **README.** It currently brags about "Absolutely no connectivity" and needs an update.
