// Based on https://www.waveshare.com/wiki/2inch_LCD_Module#Arduino_IDE_Installation_Steps
#include "DEV_Config.h"
#include "LCD_Driver.h"
#include "GUI_Paint.h"
#include "Debug.h"
// #include <SPI.h>


#define POT1_PIN 2
#define POT2_PIN 3
#define POT3_PIN 4
#define REFRESH_INTERVAL 2000UL  // 3 seconds

#define COLOR_TEXT 0xC618  // light gray
#define COLOR_BG 0x18E3    // almost black

unsigned long lastUpdate = 0;

struct CoffeePot {
  const char* name;
  int sensorPin;
  bool present;
  unsigned long placedAt;
  bool lastDrawnPresent;
  bool hasDrawnPresent;
  int lastElapsedSeconds;
  bool timerStatusDrawn; // true if "Removed" message is currently shown
};

CoffeePot pots[3] = {
  { "Medium", POT1_PIN, false, 0, false, false, -1, false },
  { "Dark", POT2_PIN, false, 0, false, false, -1, false },
  { "Decaf", POT3_PIN, false, 0, false, false, -1, false }
};


void setup() {
  Config_Init();
  LCD_Init();

  //LCD_Clear(0xffff);
  Paint_NewImage(LCD_WIDTH, LCD_HEIGHT, 0, COLOR_BG);

  // delay(2000);
  LCD_Clear(COLOR_BG);

  pinMode(POT1_PIN, INPUT);
  pinMode(POT2_PIN, INPUT);
  pinMode(POT3_PIN, INPUT);

  Serial.println("\n[debug] Writting text...");
  Paint_DrawString_EN(64, 12, "brew-em-all", &Font24, COLOR_BG, COLOR_TEXT);
  Serial.println("\n[debug] Text written.");

  //   Paint_DrawImage(0, 0);  // Initial draw
}

String formatElapsedTime(unsigned long seconds) {
  if (seconds < 60) {
    return "Last brew: " + String(seconds) + " sec";
  } else {
    int hours = seconds / 3600;
    int minutes = (seconds % 3600) / 60;
    char buffer[32];
    sprintf(buffer, "Last brew: %02dh %02dm", hours, minutes);
    return String(buffer);
  }
}

void updatePotStatus(CoffeePot& pot) {
  bool present = digitalRead(pot.sensorPin) == LOW;

  // Update state if pot status has changed
  if (present && !pot.present) {
    pot.present = true;
    pot.placedAt = millis();
  } else if (!present && pot.present) {
    pot.present = false;
  }
}

void drawPotStatus(CoffeePot& pot, int yOffset) {
  char buffer[64];

  // Always draw on first run or if present state changed
  if (!pot.hasDrawnPresent || pot.present != pot.lastDrawnPresent) {
    sprintf(buffer, "%-6s:  %s ", pot.name, pot.present ? "Present" : "Missing");
    LCD_ClearWindow(10, yOffset, LCD_WIDTH - 10, yOffset + 24, COLOR_BG);
    Paint_DrawString_EN(15, yOffset + 5, buffer, &Font20, COLOR_BG, pot.present ? GREEN : RED);
    pot.lastDrawnPresent = pot.present;
    pot.hasDrawnPresent = true;
  }

  // Only update timer line if present and time changed
  if (pot.present) {
    unsigned long elapsed = (millis() - pot.placedAt) / 1000;
    if (elapsed != pot.lastElapsedSeconds) {
      String timeStr = formatElapsedTime(elapsed);

      LCD_ClearWindow(10, yOffset + 25, LCD_WIDTH - 10, yOffset + 50, COLOR_BG);
      Paint_DrawString_EN(15, yOffset + 25, timeStr.c_str(), &Font20, COLOR_BG, COLOR_TEXT);
      pot.lastElapsedSeconds = elapsed;
      pot.timerStatusDrawn = false; // reset, since we're showing elapsed time
    }
  } else {
    // If it's missing and not already showing 'Removed'
    if (!pot.timerStatusDrawn) {
      LCD_ClearWindow(10, yOffset + 25, LCD_WIDTH - 10, yOffset + 50, COLOR_BG);
      sprintf(buffer, "Removed");
      Paint_DrawString_EN(15, yOffset + 25, buffer, &Font20, COLOR_BG, COLOR_TEXT);
      pot.timerStatusDrawn = true; // mark as 'Removed' drawn
      pot.lastElapsedSeconds = -1; // reset elapsed
    }
  }

  // Draw divider only once per update cycle (or leave it persistent)
  Paint_DrawLine(5, yOffset + 53, LCD_WIDTH - 5, yOffset + 53, COLOR_TEXT, DOT_PIXEL_1X1, LINE_STYLE_SOLID);
}


void loop() {
  unsigned long now = millis();
  if (!lastUpdate || (now - lastUpdate >= REFRESH_INTERVAL || now < lastUpdate)) {
    lastUpdate = now;
    for (int i = 0; i < 3; ++i) {
      updatePotStatus(pots[i]);
    }
    drawPotStatus(pots[0], 50);
    drawPotStatus(pots[1], 110);
    drawPotStatus(pots[2], 170);
  }
}
