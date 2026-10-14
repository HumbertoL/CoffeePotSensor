// Publishes the pots to ThingSpeak channel 3533214.
//
// Each entry holds all three pots, so the newest entry always has the full picture:
//   field1 Medium, field2 Dark, field3 Decaf:
//     the Unix time (UTC seconds) the pot was placed, 0 if it's there but its age is
//     unknown (it was already there at power-on), or -1 if it's removed.
//   field4: the board's firmware version (FIRMWARE_VERSION).
//   status: what changed, like "Dark placed".
// An entry is sent at boot and whenever a pot is placed or removed.
//
// The network work runs in its own task, so a slow or missing network never holds up
// the screen or the sensors. Changes that come faster than ThingSpeak's limit (one
// update every 15 s on the free plan) are merged into one entry. Failed sends are retried.
// Credentials come from secrets.h (copy secrets.example.h). Without it, publishing is off.
// The clock is set from NTP in TIME_ZONE, for the screen's clock and "Brewed 2:29 pm".

#include "publish.h"
#include "ota.h"   // FIRMWARE_VERSION
#include <time.h>

#define TIME_ZONE "CST6CDT,M3.2.0,M11.1.0"   // US Central (POSIX TZ string)
static const time_t CLOCK_VALID = 1700000000;  // before this, NTP hasn't set the clock yet

bool clockValid() { return time(nullptr) >= CLOCK_VALID; }

#if __has_include("secrets.h")
#include "secrets.h"
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include "thingspeak_root_ca.h"

static const unsigned long TS_MIN_GAP_MS = 16000;   // ThingSpeak free plan: one update per 15 s
static const unsigned long TS_RETRY_MS = 30000;     // wait after a failed send
#define STATUS_LEN 100

// Shared between the main loop and the network task
static portMUX_TYPE lock = portMUX_INITIALIZER_UNLOCKED;
static bool wifiStarted = false;   // Wi-Fi is on (for publishing and/or updates)
static bool enabled = false;       // publishing is on
static volatile bool hasPending = false;
static volatile bool lastSendFailed = false;   // set by the network task
static unsigned long startedAt = 0;
static unsigned long lastConnectedAt = 0;      // main loop only
static PotReport pending[3];
static unsigned long pendingAt;   // millis() when pending was taken (ages count from here)
static char pendingStatus[STATUS_LEN];

// Appends s to a form body, URL-encoded
static void appendEncoded(char* out, size_t outLen, const char* s) {
  size_t n = strlen(out);
  for (; *s && n + 4 < outLen; ++s) {
    char c = *s;
    if (isalnum((unsigned char)c) || c == '-' || c == '_' || c == '.') out[n++] = c;
    else if (c == ' ') out[n++] = '+';
    else n += snprintf(out + n, outLen - n, "%%%02X", (uint8_t)c);
  }
  out[n] = '\0';
}

// Sends one entry. Returns true if ThingSpeak accepted it (it replies with the entry number, or 0 if rejected).
static bool send(const char* body) {
  static WiFiClientSecure client;
  client.setCACert(TS_ROOT_CA);
  HTTPClient http;
  http.setConnectTimeout(8000);   // the HTTPS handshake takes a second or two
  http.setTimeout(8000);
  if (!http.begin(client, "https://api.thingspeak.com/update")) return false;
  http.addHeader("Content-Type", "application/x-www-form-urlencoded");
  int code = http.POST((uint8_t*)body, strlen(body));
  String reply = code > 0 ? http.getString() : String("");
  http.end();
  bool ok = code == 200 && reply.toInt() > 0;
  if (ok) Serial.printf("[thingspeak] entry %s\n", reply.c_str());
  else if (code > 0) Serial.printf("[thingspeak] rejected: HTTP %d, reply \"%s\"\n", code, reply.c_str());
  else Serial.printf("[thingspeak] failed: %s\n", HTTPClient::errorToString(code).c_str());
  return ok;
}

static void publishTask(void*) {
  unsigned long lastSend = 0;
  bool sentBefore = false;
  for (;;) {
    vTaskDelay(pdMS_TO_TICKS(500));
    if (!hasPending || WiFi.status() != WL_CONNECTED) continue;
    time_t epoch = time(nullptr);
    if (epoch < CLOCK_VALID) continue;
    if (sentBefore && millis() - lastSend < TS_MIN_GAP_MS) continue;

    PotReport r[3];
    unsigned long at;
    char status[STATUS_LEN];
    portENTER_CRITICAL(&lock);
    memcpy(r, pending, sizeof(r));
    at = pendingAt;
    strlcpy(status, pendingStatus, sizeof(status));
    hasPending = false;
    portEXIT_CRITICAL(&lock);

    char body[256];
    snprintf(body, sizeof(body), "api_key=%s", TS_API_KEY);
    unsigned long since = millis() - at;
    for (int i = 0; i < 3; ++i) {
      long value = r[i].state == POT_REMOVED ? -1
                 : r[i].state == POT_UNKNOWN ? 0
                 : (long)(epoch - (time_t)((r[i].ageMs + since) / 1000));
      size_t n = strlen(body);
      snprintf(body + n, sizeof(body) - n, "&field%d=%ld", i + 1, value);
    }
    size_t n = strlen(body);
    snprintf(body + n, sizeof(body) - n, "&field4=%d", FIRMWARE_VERSION);
    strlcat(body, "&status=", sizeof(body));
    appendEncoded(body, sizeof(body), status);

    bool ok = send(body);
    lastSendFailed = !ok;
    lastSend = millis();
    sentBefore = true;
    if (!ok) {
      // Put it back unless something newer is already waiting, then wait before retrying
      portENTER_CRITICAL(&lock);
      if (!hasPending) {
        memcpy(pending, r, sizeof(r));
        pendingAt = at;
        strlcpy(pendingStatus, status, sizeof(pendingStatus));
        hasPending = true;
      }
      portEXIT_CRITICAL(&lock);
      vTaskDelay(pdMS_TO_TICKS(TS_RETRY_MS));
    }
  }
}

// Starts Wi-Fi and the clock (also needed for firmware updates), then publishing if there's a key
void publishBegin() {
  if (!strlen(WIFI_SSID)) {
    Serial.println(F("[thingspeak] no Wi-Fi SSID in secrets.h, network off"));
    return;
  }
  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  configTzTime(TIME_ZONE, "pool.ntp.org", "time.nist.gov");   // ThingSpeak fields stay Unix (UTC) times
  wifiStarted = true;
  startedAt = millis();
  if (!strlen(TS_API_KEY)) {
    Serial.println(F("[thingspeak] no API key in secrets.h, publishing off"));
    return;
  }
  enabled = true;
  xTaskCreate(publishTask, "publish", 16384, nullptr, 1, nullptr);   // HTTPS needs the larger stack
}

NetState publishNetState() {
  if (!wifiStarted) return NET_DISABLED;
  unsigned long now = millis();
  if (WiFi.status() == WL_CONNECTED) {
    lastConnectedAt = now;
    return lastSendFailed ? NET_UPLOAD_FAILING : NET_ONLINE;
  }
  unsigned long since = lastConnectedAt ? now - lastConnectedAt : now - startedAt;
  return since < 60000UL ? NET_CONNECTING : NET_OFFLINE;
}

void publishPots(const PotReport reports[3], const char* status) {
  if (!enabled) return;
  portENTER_CRITICAL(&lock);
  // Merge with a change that hasn't been sent yet: the newest state wins, the notes add up
  if (!hasPending) pendingStatus[0] = '\0';
  else if (strlen(pendingStatus) + strlen(status) + 3 < sizeof(pendingStatus)) strlcat(pendingStatus, ", ", sizeof(pendingStatus));
  else status = "";
  strlcat(pendingStatus, status, sizeof(pendingStatus));
  memcpy(pending, reports, sizeof(pending));
  pendingAt = millis();
  hasPending = true;
  portEXIT_CRITICAL(&lock);
}

#else  // no secrets.h

void publishBegin() { Serial.println(F("[thingspeak] no secrets.h, publishing off (copy secrets.example.h)")); }
NetState publishNetState() { return NET_DISABLED; }
void publishPots(const PotReport*, const char*) {}

#endif
