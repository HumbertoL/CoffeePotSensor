// Firmware updates over Wi-Fi (OTA), pulled from the Netlify site (see ota.cpp).
#pragma once

#include <Arduino.h>

// Published builds get their version from tools/build_netlify.sh (the git commit
// count). A build from the Arduino IDE is version 0, so the board replaces it with
// the published firmware at its next check.
#ifndef FIRMWARE_VERSION
#define FIRMWARE_VERSION 0
#endif

void otaBegin();
// True while an update is downloading or installing (the screen says so)
bool otaBusy();

// Implemented in the .ino: called just before the board restarts into new firmware,
// so the pots' ages can survive the restart
void savePotsForRestart();
