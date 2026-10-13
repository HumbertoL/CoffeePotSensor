// The ESP32's screen (design A): a header with the title, clock and network icon,
// then one row per pot with its age, when it was brewed, and a freshness bar.
// Drawn with LovyanGFX in ui.cpp.
#pragma once

#include "publish.h"   // PotReport, NetState

#define FRESH_MIN 90    // under this many minutes: "Fresh" (green)
#define OLD_MIN   240   // from this many minutes: "Old" (red); in between: "OK" (amber)

void uiBegin();
// Redraws whatever changed. Cheap to call every loop.
void uiDraw(const char* const names[3], const PotReport pots[3], NetState net);
