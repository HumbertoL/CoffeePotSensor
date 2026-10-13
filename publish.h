// Publishes each pot's state to ThingSpeak (ESP32 only; see publish.cpp).
#pragma once

#include <Arduino.h>

// One pot, as the main loop sees it when something changes
struct PotReport {
  int8_t state;          // POT_REMOVED, POT_UNKNOWN or POT_KNOWN
  unsigned long ageMs;   // POT_KNOWN: how long ago it was placed
};
#define POT_REMOVED -1
#define POT_UNKNOWN 0
#define POT_KNOWN 1

#if defined(ARDUINO_ARCH_ESP32)
void publishBegin();
// Hands the latest state of all three pots to the network task. Never blocks.
// status is a short note for the ThingSpeak entry, like "Dark placed".
void publishPots(const PotReport reports[3], const char* status);
#else
inline void publishBegin() {}
inline void publishPots(const PotReport*, const char*) {}
#endif
