#include "DEV_Config.h"
#include "LCD_Driver.h"
#include "GUI_Paint.h"
#include "Debug.h"


#define POT1_PIN 2
#define POT2_PIN 3
#define POT3_PIN 4
#define REFRESH_INTERVAL 3000UL  // 5 seconds

unsigned long placedAt[3] = { 0, 0, 0 };
bool potPresent[3] = { false, false, false };
unsigned long lastUpdate = 0;

const char* potNames[3] = { "Medium", "Dark", "Decaf" };

void setup() {
  Config_Init();
  LCD_Init();
  Paint_NewImage(LCD_WIDTH, LCD_HEIGHT, ROTATE_0, WHITE);
  Paint_Clear(WHITE);

  pinMode(POT1_PIN, INPUT);
  pinMode(POT2_PIN, INPUT);
  pinMode(POT3_PIN, INPUT);

  LCD_Clear(WHITE);
  Paint_DrawString_EN(8, 8, "Coffee Pot Monitor", &Font24, WHITE, BLACK);
  //   Paint_DrawImage(0, 0);  // Initial draw
}

void drawPotStatus(int index, int yOffset) {
  char buffer[64];
  int sensorPin = index == 0 ? POT1_PIN : index == 1 ? POT2_PIN
                                                     : POT3_PIN;

  bool present = digitalRead(sensorPin) == LOW;
  if (present && !potPresent[index]) {
    potPresent[index] = true;
    placedAt[index] = millis();
  } else if (!present && potPresent[index]) {
    potPresent[index] = false;
  }

  // Clear and redraw region
  LCD_ClearWindow(10, yOffset, 320, yOffset + 40, WHITE);

  // Draw header: Pot Name + Status
  sprintf(buffer, "%-6s:  %s", potNames[index], present ? "Present" : "Missing");
  Paint_DrawString_EN(15, yOffset + 5, buffer, &Font20, WHITE, present ? GREEN : RED);

  // Draw timer or message
  if (present) {
    unsigned long elapsed = (millis() - placedAt[index]) / 1000;
    int hours = elapsed / 3600;
    int minutes = (elapsed % 3600) / 60;
    int seconds = elapsed % 60;
    sprintf(buffer, "Last brew:%02dh %02dm %02ds", hours, minutes, seconds);
  } else {
    sprintf(buffer, "Removed");
  }
  Paint_DrawString_EN(15, yOffset + 25, buffer, &Font20, WHITE, BLACK);
}

void loop() {
  unsigned long now = millis();
  if (!lastUpdate || (now - lastUpdate >= REFRESH_INTERVAL || now < lastUpdate)) {
    lastUpdate = now;
    drawPotStatus(0, 50);
    drawPotStatus(1, 110);
    drawPotStatus(2, 170);
    // Paint_DrawImage(0, 0);
    // lastUpdate = now;
  }
}
