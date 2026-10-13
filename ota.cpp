// Firmware updates over Wi-Fi (OTA).
//
// The board checks OTA_BASE_URL + OTA_FILE_NAME + ".version" (a whole number) 2 minutes
// after boot and then every hour. When that number is higher than FIRMWARE_VERSION, it
// downloads the matching ".bin", installs it, saves the pots' ages and restarts.
// tools/build_netlify.sh builds both files. Both URLs live in the gitignored secrets.h:
// the .bin contains the Wi-Fi password and ThingSpeak key, so its name is a random UUID
// that never appears in the repo. Downloads use HTTPS, checked against ota_root_ca.h.

#include "ota.h"

#if __has_include("secrets.h")
#include "secrets.h"
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <HTTPUpdate.h>
#include "ota_root_ca.h"

static const unsigned long OTA_FIRST_CHECK_MS = 2UL * 60UL * 1000UL;   // after boot
static const unsigned long OTA_CHECK_EVERY_MS = 60UL * 60UL * 1000UL;

static volatile bool busy = false;

bool otaBusy() { return busy; }

static String url(const char* ending) {
  String u = OTA_BASE_URL;
  if (!u.endsWith("/")) u += "/";
  return u + OTA_FILE_NAME + ending;
}

// The published version, or -1 if it couldn't be read
static long publishedVersion(WiFiClientSecure& client) {
  HTTPClient http;
  http.setConnectTimeout(8000);
  http.setTimeout(8000);
  if (!http.begin(client, url(".version"))) return -1;
  int code = http.GET();
  long v = -1;
  if (code == 200) {
    String body = http.getString();
    body.trim();
    if (body.length() && isDigit(body[0])) v = body.toInt();
  } else {
    Serial.printf("[ota] version check: %s\n", code > 0 ? String(code).c_str() : HTTPClient::errorToString(code).c_str());
  }
  http.end();
  return v;
}

static void checkAndInstall() {
  WiFiClientSecure client;
  client.setCACert(OTA_ROOT_CA);
  long v = publishedVersion(client);
  if (v < 0) return;
  if (v <= FIRMWARE_VERSION) {
    Serial.printf("[ota] up to date (v%d, published v%ld)\n", FIRMWARE_VERSION, v);
    return;
  }
  Serial.printf("[ota] installing v%ld (running v%d)\n", v, FIRMWARE_VERSION);
  busy = true;
  httpUpdate.rebootOnUpdate(false);   // restart ourselves, after saving the pots
  HTTPUpdateResult r = httpUpdate.update(client, url(".bin"));
  if (r == HTTP_UPDATE_OK) {
    Serial.println(F("[ota] installed, restarting"));
    savePotsForRestart();
    Serial.flush();
    ESP.restart();
  }
  Serial.printf("[ota] failed: %s\n", httpUpdate.getLastErrorString().c_str());
  busy = false;
}

static void otaTask(void*) {
  vTaskDelay(pdMS_TO_TICKS(OTA_FIRST_CHECK_MS));
  for (;;) {
    if (WiFi.status() == WL_CONNECTED) checkAndInstall();
    vTaskDelay(pdMS_TO_TICKS(OTA_CHECK_EVERY_MS));
  }
}

void otaBegin() {
  Serial.printf("[ota] firmware v%d\n", FIRMWARE_VERSION);
  if (!strlen(OTA_BASE_URL) || !strlen(OTA_FILE_NAME)) {
    Serial.println(F("[ota] no OTA_BASE_URL / OTA_FILE_NAME in secrets.h, updates off"));
    return;
  }
  // Wi-Fi is started by publishBegin(); this task just waits for it
  xTaskCreate(otaTask, "ota", 8192, nullptr, 1, nullptr);
}

#else  // no secrets.h

bool otaBusy() { return false; }
void otaBegin() { Serial.printf("[ota] firmware v%d, no secrets.h, updates off\n", FIRMWARE_VERSION); }

#endif
