// Based on https://www.waveshare.com/wiki/2inch_LCD_Module#Arduino_IDE_Installation_Steps
#include "DEV_Config.h"
#include "LCD_Driver.h"
#include "GUI_Paint.h"
#include "Debug.h"
// #include <SPI.h>


#define POT1_PIN 2
#define POT2_PIN 3
#define POT3_PIN 4
#define REFRESH_INTERVAL 3000UL  // 5 seconds

#define COLOR_TEXT   0xC618  // light gray
#define COLOR_BG     0x18E3  // almost black

unsigned long lastUpdate = 0;

const char* potNames[3] = { "Medium", "Dark", "Decaf" };

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

// State tracking per pot
// State tracking per pot
bool potPresent[3] = {false, false, false};
unsigned long placedAt[3] = {0, 0, 0};
bool lastDrawnPresent[3] = {false, false, false};
bool hasDrawnPresent[3] = {false, false, false};
int lastElapsedSeconds[3] = {-1, -1, -1};

void drawPotStatus(int index, int yOffset) {
  char buffer[64];
  int sensorPin = index == 0 ? POT1_PIN : index == 1 ? POT2_PIN : POT3_PIN;

  bool present = digitalRead(sensorPin) == LOW;

  // Update state if pot status has changed
  if (present && !potPresent[index]) {
    potPresent[index] = true;
    placedAt[index] = millis();
  } else if (!present && potPresent[index]) {
    potPresent[index] = false;
  }

  // Always draw on first run or if present state changed
  if (!hasDrawnPresent[index] || present != lastDrawnPresent[index]) {
    sprintf(buffer, "%-6s:  %s ", potNames[index], present ? "Present" : "Missing");
    LCD_ClearWindow(10, yOffset, LCD_WIDTH - 10, yOffset + 24, COLOR_BG);
    Paint_DrawString_EN(15, yOffset + 5, buffer, &Font20, COLOR_BG, present ? GREEN : RED);
    lastDrawnPresent[index] = present;
    hasDrawnPresent[index] = true;
  }

  // Only update timer line if present and time changed
  if (present) {
    unsigned long elapsed = (millis() - placedAt[index]) / 1000;
    if (elapsed != lastElapsedSeconds[index]) {
      int hours = elapsed / 3600;
      int minutes = (elapsed % 3600) / 60;
      int seconds = elapsed % 60;
      sprintf(buffer, "Last brew:%02dh %02dm %02ds", hours, minutes, seconds);
      LCD_ClearWindow(10, yOffset + 25, LCD_WIDTH - 10, yOffset + 50, COLOR_BG);
      Paint_DrawString_EN(15, yOffset + 25, buffer, &Font20, COLOR_BG, COLOR_TEXT);
      lastElapsedSeconds[index] = elapsed;
    }
  } else {
    // If it's missing and not already showing 'Removed'
    if (lastElapsedSeconds[index] != -2) {
      LCD_ClearWindow(10, yOffset + 25, LCD_WIDTH - 10, yOffset + 50, COLOR_BG);
      sprintf(buffer, "Removed");
      Paint_DrawString_EN(15, yOffset + 25, buffer, &Font20, COLOR_BG, COLOR_TEXT);
      lastElapsedSeconds[index] = -2; // mark as 'Removed'
    }
  }

  // Draw divider only once per update cycle (or leave it persistent)
  Paint_DrawLine(5, yOffset + 52, LCD_WIDTH - 5, yOffset + 52, COLOR_TEXT, DOT_PIXEL_1X1, LINE_STYLE_SOLID);
}


void loop() {

  unsigned long now = millis();
  if (!lastUpdate || (now - lastUpdate >= REFRESH_INTERVAL || now < lastUpdate)) {
    Serial.println("\n[debug] In loop");
    lastUpdate = now;
    drawPotStatus(0, 50);
    Serial.println("\n[debug] Pot 1 status");
    drawPotStatus(1, 110);
    Serial.println("\n[debug] Pot 2 status");
    drawPotStatus(2, 170);
    Serial.println("\n[debug] Pot 3 status");
    // Paint_DrawImage(0, 0);
    // lastUpdate = now;
  }
}
