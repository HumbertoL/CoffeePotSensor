// Publishes each pot's state to ThingSpeak (see publish.cpp).
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

// Network state, for the screen's status icon
enum NetState : uint8_t {
  NET_DISABLED,     // no secrets.h, or no SSID / API key: nothing to show
  NET_CONNECTING,   // not connected yet, or reconnecting (under a minute)
  NET_ONLINE,       // connected, and the last upload (if any) worked
  NET_OFFLINE,      // disconnected for a minute or more
  NET_UPLOAD_FAILING  // connected, but ThingSpeak isn't taking uploads
};

void publishBegin();
NetState publishNetState();
// True once NTP has set the clock (local time then comes from localtime_r)
bool clockValid();
// Hands the latest state of all three pots to the network task. Never blocks.
// status is a short note for the ThingSpeak entry, like "Dark placed".
void publishPots(const PotReport reports[3], const char* status);
