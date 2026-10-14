// Copy this file to secrets.h and fill in your values.
// secrets.h is listed in .gitignore, so it stays out of git.
// Without a secrets.h the sketch still builds, with publishing and updates off.
// ("static" lets more than one file include it.)

#pragma once

static const char* WIFI_SSID = "";
static const char* WIFI_PASSWORD = "";
static const char* TS_API_KEY = "";   // ThingSpeak channel 3533214's Write API Key (API Keys tab)

// Firmware updates (OTA). The .bin holds the secrets above, so its name is a random UUID:
// make your own (uuidgen) and never commit it. The board downloads
// OTA_BASE_URL + OTA_FILE_NAME + ".version" / ".bin". Leave OTA_BASE_URL empty to turn updates off.
static const char* OTA_BASE_URL = "";   // the Netlify site, like "https://name.netlify.app/"
static const char* OTA_FILE_NAME = "";  // a random UUID

// ThingSpeak TalkBack, for commands from the dashboard (ThingSpeak: Apps > TalkBack).
// Leave the key empty to turn commands off. The dashboard gets the key from its share link.
#define TS_TALKBACK_ID  ""
#define TS_TALKBACK_KEY ""     // the TalkBack's API key

// Slack incoming webhook for "fresh pot" messages (api.slack.com/apps > Incoming Webhooks).
// It's a secret: anyone with it can post to the channel. Leave it empty to turn Slack off.
#define SLACK_WEBHOOK_URL ""
