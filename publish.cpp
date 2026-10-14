// Publishes the pots to ThingSpeak channel 3533214.
//
// Each entry holds all three pots, so the newest entry always has the full picture:
//   field1 Medium, field2 Dark, field3 Decaf:
//     the Unix time (UTC seconds) the pot was placed, 0 if it's there but its age is
//     unknown (it was already there at power-on), or -1 if it's removed.
//   field4: the board's firmware version (FIRMWARE_VERSION).
//   field5: Wi-Fi signal strength (RSSI, dBm; about -50 is great, below -80 is poor).
//   field6: the lowest free memory since boot (KB), to spot leaks.
//   field7: uptime (hours), to spot restarts.
//   status: what changed, like "Dark placed" (empty for a heartbeat).
// An entry is sent at boot, whenever a pot is placed or removed, after Slack posts and
// commands, and as a heartbeat every 30 minutes (from the .ino).
//
// Slack: publishSlack() posts a message to the incoming webhook in SLACK_WEBHOOK_URL
// (secrets.h; empty = off), retrying twice. The result comes back to the main loop as a
// note (publishTakeNote), which ends up in a ThingSpeak status.
//
// Commands from the dashboard come through ThingSpeak TalkBack (TS_TALKBACK_ID and
// TS_TALKBACK_KEY in secrets.h). The network task takes waiting commands every 20 s
// and hands them to the main loop (publishTakeCommand).
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

// Older secrets.h files don't have the TalkBack settings: commands are then off
#ifndef TS_TALKBACK_ID
#define TS_TALKBACK_ID ""
#endif
#ifndef TS_TALKBACK_KEY
#define TS_TALKBACK_KEY ""
#endif
#ifndef SLACK_WEBHOOK_URL
#define SLACK_WEBHOOK_URL ""
#endif

static const unsigned long TS_MIN_GAP_MS = 16000;   // ThingSpeak free plan: one update per 15 s
static const unsigned long TS_RETRY_MS = 30000;     // wait after a failed send
static const unsigned long COMMAND_POLL_MS = 20000; // how often to take TalkBack commands
static const unsigned long SLACK_RETRY_MS = 30000;  // between Slack attempts (3 in all)
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
static bool talkbackOn = false;
static QueueHandle_t commandQueue = nullptr;   // TalkBack commands, network task -> main loop
struct Command { char text[64]; };
static bool slackOn = false;
struct SlackMsg { char label[16]; char text[160]; };
static QueueHandle_t slackQueue = nullptr;     // main loop -> network task
static QueueHandle_t noteQueue = nullptr;      // notes for ThingSpeak, network task -> main loop
struct Note { char text[48]; };

static void addNote(const char* fmt, const char* a, int b) {
  Note n;
  snprintf(n.text, sizeof(n.text), fmt, a, b);
  if (noteQueue) xQueueSend(noteQueue, &n, 0);
}

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

// POSTs a form to api.thingspeak.com over HTTPS. Returns the HTTP status, or a negative HTTPClient error.
static int post(const char* path, const char* body, String& reply) {
  static WiFiClientSecure client;
  client.setCACert(TS_ROOT_CA);
  HTTPClient http;
  http.setConnectTimeout(8000);   // the HTTPS handshake takes a second or two
  http.setTimeout(8000);
  if (!http.begin(client, String("https://api.thingspeak.com") + path)) return HTTPC_ERROR_CONNECTION_REFUSED;
  http.addHeader("Content-Type", "application/x-www-form-urlencoded");
  int code = http.POST((uint8_t*)body, strlen(body));
  reply = code > 0 ? http.getString() : String("");
  http.end();
  return code;
}

// Takes the waiting TalkBack commands (up to 4) and queues them for the main loop.
// ThingSpeak replies with {"command_string":"...",...}, or with an empty body when none is waiting.
static void takeCommands() {
  char path[64], body[64];
  snprintf(path, sizeof(path), "/talkbacks/%s/commands/execute.json", TS_TALKBACK_ID);
  snprintf(body, sizeof(body), "api_key=%s", TS_TALKBACK_KEY);
  for (int i = 0; i < 4; ++i) {
    String reply;
    int code = post(path, body, reply);
    if (code != 200) {
      Serial.printf("[talkback] failed: %s\n", code > 0 ? String(code).c_str() : HTTPClient::errorToString(code).c_str());
      return;
    }
    int k = reply.indexOf("\"command_string\":\"");
    if (k < 0) return;   // nothing waiting
    k += 18;
    int end = reply.indexOf('"', k);
    if (end < 0) return;
    Command c;
    strlcpy(c.text, reply.substring(k, end).c_str(), sizeof(c.text));
    Serial.printf("[talkback] command \"%s\"\n", c.text);
    xQueueSend(commandQueue, &c, 0);
  }
}

// Posts one message to Slack. Returns the HTTP status (200 = posted), or a negative HTTPClient error.
static int slackPost(const char* text) {
  static WiFiClientSecure client;
  client.setCACert(TS_ROOT_CA);   // hooks.slack.com chains to ISRG Root X1, which is in this set
  HTTPClient http;
  http.setConnectTimeout(8000);
  http.setTimeout(8000);
  if (!http.begin(client, SLACK_WEBHOOK_URL)) return HTTPC_ERROR_CONNECTION_REFUSED;
  http.addHeader("Content-Type", "application/json");
  String body = String("{\"text\":\"") + text + "\"}";   // our own text: no quotes or backslashes
  int code = http.POST(body);
  http.end();
  return code;
}

void publishSlack(const char* label, const char* text) {
  if (!slackOn) return;
  SlackMsg m;
  strlcpy(m.label, label, sizeof(m.label));
  strlcpy(m.text, text, sizeof(m.text));
  if (xQueueSend(slackQueue, &m, 0) != pdTRUE) Serial.println(F("[slack] queue full, dropped"));
}

bool publishTakeNote(char* out, size_t len) {
  if (!noteQueue) return false;
  Note n;
  if (xQueueReceive(noteQueue, &n, 0) != pdTRUE) return false;
  strlcpy(out, n.text, len);
  return true;
}

bool publishTakeCommand(char* out, size_t len) {
  if (!commandQueue) return false;
  Command c;
  if (xQueueReceive(commandQueue, &c, 0) != pdTRUE) return false;
  strlcpy(out, c.text, len);
  return true;
}

// Sends one entry. Returns true if ThingSpeak accepted it (it replies with the entry number, or 0 if rejected).
static bool send(const char* body) {
  String reply;
  int code = post("/update", body, reply);
  bool ok = code == 200 && reply.toInt() > 0;
  if (ok) Serial.printf("[thingspeak] entry %s\n", reply.c_str());
  else if (code > 0) Serial.printf("[thingspeak] rejected: HTTP %d, reply \"%s\"\n", code, reply.c_str());
  else Serial.printf("[thingspeak] failed: %s\n", HTTPClient::errorToString(code).c_str());
  return ok;
}

static void publishTask(void*) {
  unsigned long lastSend = 0;
  unsigned long waitUntil = 0;   // after a failed send
  unsigned long lastPoll = 0;
  bool sentBefore = false, polledBefore = false;
  SlackMsg slack;
  bool slackBusy = false;           // a message is being sent (or waiting to retry)
  int slackTries = 0;
  unsigned long slackNextAt = 0;
  for (;;) {
    vTaskDelay(pdMS_TO_TICKS(500));
    if (WiFi.status() != WL_CONNECTED) continue;
    if (slackOn && !slackBusy && xQueueReceive(slackQueue, &slack, 0) == pdTRUE) {
      slackBusy = true;
      slackTries = 0;
      slackNextAt = millis();
    }
    if (slackBusy && (long)(millis() - slackNextAt) >= 0) {
      int code = slackPost(slack.text);
      ++slackTries;
      if (code == 200) {
        Serial.printf("[slack] posted: %s\n", slack.text);
        addNote("Slack: %s posted", slack.label, 0);
        slackBusy = false;
      } else if (slackTries >= 3) {
        Serial.printf("[slack] gave up: %s\n", code > 0 ? String(code).c_str() : HTTPClient::errorToString(code).c_str());
        addNote("Slack: %s failed (%d)", slack.label, code);
        slackBusy = false;
      } else {
        Serial.printf("[slack] attempt %d failed (%d), retrying\n", slackTries, code);
        slackNextAt = millis() + SLACK_RETRY_MS;
      }
    }
    if (talkbackOn && (!polledBefore || millis() - lastPoll >= COMMAND_POLL_MS)) {
      takeCommands();
      lastPoll = millis();
      polledBefore = true;
    }
    if (!enabled || !hasPending) continue;
    time_t epoch = time(nullptr);
    if (epoch < CLOCK_VALID) continue;
    if (sentBefore && millis() - lastSend < TS_MIN_GAP_MS) continue;
    if ((long)(millis() - waitUntil) < 0) continue;

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
    snprintf(body + n, sizeof(body) - n, "&field4=%d&field5=%d&field6=%u&field7=%.1f",
             FIRMWARE_VERSION, (int)WiFi.RSSI(), (unsigned)(ESP.getMinFreeHeap() / 1024), millis() / 3600000.0);
    if (status[0]) {
      strlcat(body, "&status=", sizeof(body));
      appendEncoded(body, sizeof(body), status);
    }

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
      waitUntil = millis() + TS_RETRY_MS;
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
  enabled = strlen(TS_API_KEY) > 0;
  if (!enabled) Serial.println(F("[thingspeak] no API key in secrets.h, publishing off"));
  talkbackOn = strlen(TS_TALKBACK_ID) && strlen(TS_TALKBACK_KEY);
  if (!talkbackOn) Serial.println(F("[talkback] no TS_TALKBACK_ID / TS_TALKBACK_KEY in secrets.h, commands off"));
  else commandQueue = xQueueCreate(8, sizeof(Command));
  slackOn = strlen(SLACK_WEBHOOK_URL) > 0;
  if (!slackOn) Serial.println(F("[slack] no SLACK_WEBHOOK_URL in secrets.h, Slack off"));
  else slackQueue = xQueueCreate(4, sizeof(SlackMsg));
  noteQueue = xQueueCreate(8, sizeof(Note));
  if (enabled || talkbackOn || slackOn) xTaskCreate(publishTask, "publish", 16384, nullptr, 1, nullptr);   // HTTPS needs the larger stack
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
  if (!status[0]) {
    // a heartbeat: nothing to add
  } else if (!pendingStatus[0]) {
    // first note
  } else if (strlen(pendingStatus) + strlen(status) + 3 < sizeof(pendingStatus)) {
    strlcat(pendingStatus, ", ", sizeof(pendingStatus));
  } else {
    status = "";
  }
  strlcat(pendingStatus, status, sizeof(pendingStatus));
  memcpy(pending, reports, sizeof(pending));
  pendingAt = millis();
  hasPending = true;
  portEXIT_CRITICAL(&lock);
}

#else  // no secrets.h

void publishBegin() { Serial.println(F("[thingspeak] no secrets.h, publishing off (copy secrets.example.h)")); }
bool publishTakeCommand(char*, size_t) { return false; }
bool publishTakeNote(char*, size_t) { return false; }
void publishSlack(const char*, const char*) {}
NetState publishNetState() { return NET_DISABLED; }
void publishPots(const PotReport*, const char*) {}

#endif
