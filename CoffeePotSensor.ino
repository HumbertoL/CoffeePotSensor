// Based on https://www.waveshare.com/wiki/2inch_LCD_Module#Arduino_IDE_Installation_Steps
#include "DEV_Config.h"
#include "LCD_Driver.h"
#include "GUI_Paint.h"
#include "Debug.h"

#if defined(ARDUINO_ARCH_ESP32)
#define POT1_PIN 4  // GPIO numbers on the ESP32-S3-Zero (3.3V inputs only!)
#define POT2_PIN 5
#define POT3_PIN 6
#else
#define POT1_PIN 2
#define POT2_PIN 3
#define POT3_PIN 4
#endif
#define REFRESH_INTERVAL 100UL  // ms between sensor polls
#define STATUS_CHARS 20         // status text is padded to this width so it fully overwrites the previous text
#define PLACE_DEBOUNCE_MS 1000UL   // sensor must read "present" this long before a pot counts as placed
#define REMOVE_DEBOUNCE_MS 3000UL  // ...or "absent" this long before it counts as removed (ignores IR flicker)
#define IDLE_RESTART_MS (48UL * 60 * 60 * 1000)  // restart after this long with no pot activity (e.g. over a weekend)

#define COLOR_TEXT 0xC618  // light gray
#define COLOR_BG 0x18E3    // almost black
#define STARBUCKS_GREEN 0x07E0

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
  char shown[STATUS_CHARS + 1];  // status text currently on screen
  bool nameDrawn;  // true if name has been drawn
};

CoffeePot pots[3] = {
  { "Medium", POT1_PIN, false, false, 0, false, 0, "", false },
  { "Dark", POT2_PIN, false, false, 0, false, 0, "", false },
  { "Decaf", POT3_PIN, false, false, 0, false, 0, "", false }
};


bool isPotPresent(const CoffeePot& pot) {
  return digitalRead(pot.sensorPin) == LOW;
}

// Restart the sketch from scratch: globals are re-initialized, millis() starts
// over at 0, and setup() runs again (which also hardware-resets the LCD).
// On AVR this jumps to the reset vector instead of using a watchdog reset,
// because Nanos with the old bootloader get stuck in a reset loop after a
// watchdog reset.
void restart() {
  Serial.println(F("[debug] No pot activity, restarting..."));
  Serial.flush();
#if defined(ARDUINO_ARCH_ESP32)
  ESP.restart();
#else
  noInterrupts();
  asm volatile("jmp 0");
#endif
}

void setup() {
#if defined(ARDUINO_ARCH_ESP32)
  // Hardware watchdog: reboots the board if loop() ever stops returning (a real hang)
  enableLoopWDT();
#endif
  Config_Init();
  LCD_Init();

  //LCD_Clear(0xffff);
  Paint_NewImage(LCD_WIDTH, LCD_HEIGHT, 0, COLOR_BG);

  // delay(2000);
  LCD_Clear(COLOR_BG);

  pinMode(POT1_PIN, INPUT);
  pinMode(POT2_PIN, INPUT);
  pinMode(POT3_PIN, INPUT);

  // A pot already on the burner at power-on has an unknown age. Recording it as
  // present means the timer only starts once it's removed and put back.
  for (int i = 0; i < 3; ++i) {
    pots[i].present = pots[i].rawPresent = isPotPresent(pots[i]);
  }

  Serial.println("\n[debug] Writting text...");
  Paint_DrawString_EN(64, 12, "brew-em-all", &Font24, COLOR_BG, COLOR_TEXT);
  Serial.println("\n[debug] Text written.");

  //   Paint_DrawImage(0, 0);  // Initial draw
}

void formatStatus(const CoffeePot& pot, unsigned long now, char* buffer) {
  if (!pot.present) {
    strcpy(buffer, "Removed");
  } else if (!pot.timeKnown) {
    strcpy(buffer, "Last brew: Unknown");
  } else {
    unsigned long seconds = (now - pot.placedAt) / 1000;
    if (seconds < 60) {
      snprintf(buffer, STATUS_CHARS + 1, "Last brew: %02d sec", (int)seconds);
    } else {
      unsigned long hours = seconds / 3600;
      int minutes = (seconds % 3600) / 60;
      snprintf(buffer, STATUS_CHARS + 1, "Last brew: %02luh %02dm", hours, minutes);
    }
  }

  // Pad with spaces so shorter text covers whatever was drawn before
  size_t len = strlen(buffer);
  memset(buffer + len, ' ', STATUS_CHARS - len);
  buffer[STATUS_CHARS] = '\0';
}

void updatePotStatus(CoffeePot& pot, unsigned long now) {
  bool raw = isPotPresent(pot);
  if (raw != pot.rawPresent) {
    pot.rawPresent = raw;
    pot.rawChangedAt = now;
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
}

void drawPotStatus(CoffeePot& pot, int yOffset, unsigned long now) {
  // Draw pot name in green only once
  if (!pot.nameDrawn) {
    // LCD_ClearWindow(10, yOffset, LCD_WIDTH - 10, yOffset + 24, COLOR_BG);
    Paint_DrawString_EN(15, yOffset, pot.name, &Font20, COLOR_BG, STARBUCKS_GREEN);

    // Draw divider
    Paint_DrawLine(5, yOffset + 53, LCD_WIDTH - 5, yOffset + 53, COLOR_TEXT, DOT_PIXEL_1X1, LINE_STYLE_SOLID);

    pot.nameDrawn = true;
  }

  // Only redraw the status line when its text changes
  char status[STATUS_CHARS + 1];
  formatStatus(pot, now, status);
  if (strcmp(status, pot.shown) != 0) {
    Paint_DrawString_EN(15, yOffset + 25, status, &Font20, COLOR_BG, COLOR_TEXT);
    strcpy(pot.shown, status);
  }
}


void loop() {
  unsigned long now = millis();
  if (!lastUpdate || (now - lastUpdate >= REFRESH_INTERVAL || now < lastUpdate)) {
    lastUpdate = now;

    // Nobody has touched a pot in a long time (a weekend), so start fresh.
    // Pots still on the burner will show "Unknown" afterwards.
    if (now - lastActivity >= IDLE_RESTART_MS) {
      restart();
    }

    for (int i = 0; i < 3; ++i) {
      updatePotStatus(pots[i], now);
      // Start at 50, then increment by 60 for each pot
      int yOffset = 50 + (i * 60);
      drawPotStatus(pots[i], yOffset, now);
    }
  }
}
