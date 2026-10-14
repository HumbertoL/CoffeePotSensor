// brew-em-all: shows how long each of three coffee pots has been on the rack.
// Runs on a Waveshare ESP32-S3-Zero with a Waveshare 2" ST7789 LCD (see README.md).
#include "publish.h"  // ThingSpeak (credentials in secrets.h)
#include "ui.h"       // the screen (LovyanGFX)
#include "ota.h"      // firmware updates over Wi-Fi
#include <time.h>
#include <esp_system.h>

#if !defined(ARDUINO_ARCH_ESP32)
#error "brew-em-all runs on the ESP32-S3-Zero only (Nano support was dropped)"
#endif

#define POT1_PIN 4  // GPIO numbers on the ESP32-S3-Zero (3.3V inputs only!)
#define POT2_PIN 5
#define POT3_PIN 6
#define REFRESH_INTERVAL 100UL  // ms between sensor polls
// Sensor test mode: set to 1 to show raw readings with no debounce and log each change to Serial.
// For checking a sensor or case print; set it back to 0 for normal use. Nothing is published in this mode.
#define SENSOR_TEST 0
#if SENSOR_TEST
#define PLACE_DEBOUNCE_MS 0UL
#define REMOVE_DEBOUNCE_MS 0UL
#else
#define PLACE_DEBOUNCE_MS 1000UL   // sensor must read "present" this long before a pot counts as placed
#define REMOVE_DEBOUNCE_MS 3000UL  // ...or "absent" this long before it counts as removed (ignores IR flicker)
#endif
#define IDLE_RESTART_MS (48UL * 60 * 60 * 1000)  // restart after this long with no pot activity (e.g. over a weekend)

unsigned long lastUpdate = 0;
unsigned long lastActivity = 0;  // millis() of the last pot placed/removed (or boot)

struct CoffeePot {
  const char* name;
  int sensorPin;
  bool present;               // debounced state
  bool rawPresent;            // latest sensor reading
  unsigned long rawChangedAt; // millis() when rawPresent last changed
  bool timeKnown;  // false until the pot has been placed while we were watching
  unsigned long placedAt;
};

const char* const potNames[3] = { "Medium", "Dark", "Decaf" };  // top to bottom on the screen

CoffeePot pots[3] = {
  { potNames[0], POT1_PIN, false, false, 0, false, 0 },
  { potNames[1], POT2_PIN, false, false, 0, false, 0 },
  { potNames[2], POT3_PIN, false, false, 0, false, 0 }
};


bool isPotPresent(const CoffeePot& pot) {
  return digitalRead(pot.sensorPin) == LOW;
}

// Restart from scratch: millis() starts over and setup() runs again
// (which also resets the LCD).
void restart() {
  Serial.println(F("[debug] No pot activity, restarting..."));
  Serial.flush();
  ESP.restart();
}

// Pots' ages kept across a restart into new firmware (RTC memory survives a software
// reset). Only the update path writes it; the weekend idle restart starts fresh.
#define SAVED_MAGIC 0xC0FFEE01
struct SavedPots {
  uint32_t magic;
  int8_t state[3];
  time_t placedEpoch[3];   // Unix time each POT_KNOWN pot was placed
};
RTC_NOINIT_ATTR SavedPots savedPots;
bool restorePending = false;

void savePotsForRestart() {
  if (!clockValid()) return;   // no clock: the ages can't be carried over
  time_t epoch = time(nullptr);
  unsigned long now = millis();
  for (int i = 0; i < 3; ++i) {
    savedPots.state[i] = !pots[i].present ? POT_REMOVED : pots[i].timeKnown ? POT_KNOWN : POT_UNKNOWN;
    savedPots.placedEpoch[i] = epoch - (time_t)((now - pots[i].placedAt) / 1000);
  }
  savedPots.magic = SAVED_MAGIC;
}

// Once the clock is set after an update restart, give back the ages of the pots
// that are still on the rack
void restorePots(unsigned long now) {
  if (!restorePending || !clockValid()) return;
  restorePending = false;
  time_t epoch = time(nullptr);
  bool any = false;
  for (int i = 0; i < 3; ++i) {
    if (savedPots.state[i] != POT_KNOWN || !pots[i].present || pots[i].timeKnown) continue;
    if (savedPots.placedEpoch[i] > epoch) continue;
    pots[i].placedAt = now - (unsigned long)(epoch - savedPots.placedEpoch[i]) * 1000UL;
    pots[i].timeKnown = true;
    any = true;
  }
  if (any) publishState("Ages restored after update");
}

// Why the board last restarted, for the "Started" note (a crash loop shows up on the dashboard)
const char* resetReasonText() {
  switch (esp_reset_reason()) {
    case ESP_RST_POWERON: return "power-on";
    case ESP_RST_SW: return "restart";
    case ESP_RST_PANIC: return "crash";
    case ESP_RST_INT_WDT:
    case ESP_RST_TASK_WDT:
    case ESP_RST_WDT: return "watchdog";
    case ESP_RST_BROWNOUT: return "brownout";
    case ESP_RST_USB: return "USB";
    default: return "other";
  }
}

// Each pot's state, for the screen and ThingSpeak
void potReports(PotReport reports[3], unsigned long now) {
  for (int i = 0; i < 3; ++i) {
    reports[i].state = !pots[i].present ? POT_REMOVED : pots[i].timeKnown ? POT_KNOWN : POT_UNKNOWN;
    reports[i].ageMs = now - pots[i].placedAt;
  }
}

// Sends all three pots to ThingSpeak, with a note on what changed
void publishState(const char* status) {
#if !SENSOR_TEST
  PotReport reports[3];
  potReports(reports, millis());
  publishPots(reports, status);
#endif
}

void setup() {
  // Hardware watchdog: reboots the board if loop() ever stops returning (a real hang)
  enableLoopWDT();
  Serial.begin(115200);
  Serial.println(F("\n[BOOT] Starting brew-em-all..."));
  uiBegin();

  pinMode(POT1_PIN, INPUT);
  pinMode(POT2_PIN, INPUT);
  pinMode(POT3_PIN, INPUT);

  // A pot already on the rack at power-on has an unknown age. Recording it as
  // present means the timer only starts once it's removed and put back.
  for (int i = 0; i < 3; ++i) {
    pots[i].present = pots[i].rawPresent = isPotPresent(pots[i]);
  }
  // After an update, the pots still on the rack get their ages back once the clock is set
  restorePending = esp_reset_reason() == ESP_RST_SW && savedPots.magic == SAVED_MAGIC;
  savedPots.magic = 0;

  publishBegin();
  otaBegin();
  char status[40];
  snprintf(status, sizeof(status), "Started v%d (%s)", FIRMWARE_VERSION, resetReasonText());
  Serial.printf("[BOOT] %s\n", status);
  publishState(status);
}

void updatePotStatus(CoffeePot& pot, unsigned long now) {
  bool raw = isPotPresent(pot);
  if (raw != pot.rawPresent) {
    pot.rawPresent = raw;
    pot.rawChangedAt = now;
#if SENSOR_TEST
    Serial.print(pot.name);
    Serial.println(raw ? F(": present") : F(": absent"));
#endif
  }

  // Only accept a change once the reading has held steady long enough
  if (raw == pot.present) {
    return;
  }
  unsigned long debounce = raw ? PLACE_DEBOUNCE_MS : REMOVE_DEBOUNCE_MS;
  if (now - pot.rawChangedAt < debounce) {
    return;
  }

  lastActivity = now;
  if (raw) {
    // Start the timer from when the pot actually arrived, not when the debounce finished
    pot.placedAt = pot.rawChangedAt;
    pot.timeKnown = true;
  }
  pot.present = raw;

  char status[24];
  snprintf(status, sizeof(status), "%s %s", pot.name, raw ? "placed" : "removed");
  publishState(status);
}

void loop() {
  unsigned long now = millis();
  if (!lastUpdate || now - lastUpdate >= REFRESH_INTERVAL) {
    lastUpdate = now;

    // Nobody has touched a pot in a long time (a weekend), so start fresh.
    // Pots still on the rack will show "Unknown" afterwards.
    if (now - lastActivity >= IDLE_RESTART_MS) {
      restart();
    }

    restorePots(now);
    for (int i = 0; i < 3; ++i) {
      updatePotStatus(pots[i], now);
    }
    PotReport reports[3];
    potReports(reports, now);
    uiDraw(potNames, reports, publishNetState());
  }
}
