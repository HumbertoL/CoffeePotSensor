// Screen drawing with LovyanGFX (see ui.h for the layout).
//
// Each region (the header, and each pot's row) is drawn into a sprite in memory and
// then sent to the LCD in a single burst, so nothing flickers. The rows share one
// 320 x 70 sprite (45 KB). A region is redrawn only when something it shows has changed.

#include <LovyanGFX.hpp>
#include <time.h>
#include "ui.h"
#include "ota.h"

// LCD wiring on the ESP32-S3-Zero (GPIO numbers). The core's default SPI pins
// (GPIO34-37) aren't on the headers, so SPI uses GPIO11/12.
#define LCD_CS   10
#define LCD_DC   9
#define LCD_RST  8
#define LCD_BL   7
#define LCD_MOSI 11
#define LCD_SCK  12
#define LCD_SPI_HZ 20000000   // safe for jumper wires; the ST7789 can go faster

// Waveshare 2" ST7789 module (240 x 320 panel, used in landscape)
class LGFX : public lgfx::LGFX_Device {
  lgfx::Panel_ST7789 panel;
  lgfx::Bus_SPI bus;
  lgfx::Light_PWM light;
public:
  LGFX() {
    auto b = bus.config();
    b.spi_host = SPI2_HOST;
    b.spi_mode = 3;              // as the Waveshare driver used
    b.freq_write = LCD_SPI_HZ;
    b.freq_read = 16000000;
    b.pin_sclk = LCD_SCK;
    b.pin_mosi = LCD_MOSI;
    b.pin_miso = -1;
    b.pin_dc = LCD_DC;
    b.dma_channel = SPI_DMA_CH_AUTO;
    bus.config(b);
    panel.setBus(&bus);

    auto p = panel.config();
    p.pin_cs = LCD_CS;
    p.pin_rst = LCD_RST;
    p.panel_width = 240;
    p.panel_height = 320;
    p.invert = true;             // the Waveshare demo's init sent INVON
    p.readable = false;
    p.bus_shared = false;
    panel.config(p);

    auto l = light.config();
    l.pin_bl = LCD_BL;
    l.freq = 44100;
    l.pwm_channel = 7;
    light.config(l);
    panel.setLight(&light);

    setPanel(&panel);
  }
};

static LGFX lcd;
static LGFX_Sprite headerCanvas(&lcd);
static LGFX_Sprite canvas(&lcd);   // one pot's row

#define W 320
#define HEADER_H 30
#define ROW_H 70
#define BACKLIGHT 80   // 0-255, as before

static const uint16_t C_BG = lgfx::color565(0x14, 0x16, 0x1a);
static const uint16_t C_LINE = lgfx::color565(0x2a, 0x2d, 0x33);
static const uint16_t C_TEXT = lgfx::color565(0xe8, 0xe6, 0xe1);
static const uint16_t C_MUTED = lgfx::color565(0xa9, 0xa6, 0x9e);
static const uint16_t C_GREEN = lgfx::color565(0x5d, 0xca, 0x7a);
static const uint16_t C_AMBER = lgfx::color565(0xef, 0xb0, 0x27);
static const uint16_t C_RED = lgfx::color565(0xe8, 0x5a, 0x4f);
static const uint16_t C_GRAY = lgfx::color565(0x7a, 0x78, 0x70);

// What each region showed last time, to skip redraws
static char shownHeader[32];
static char shownRow[3][96];

void uiBegin() {
  lcd.init();
  lcd.setRotation(3);            // landscape, matching the Waveshare demo's MADCTL 0xA0
  lcd.setBrightness(BACKLIGHT);
  lcd.fillScreen(C_BG);
  headerCanvas.setColorDepth(16);
  headerCanvas.createSprite(W, HEADER_H);
  canvas.setColorDepth(16);
  canvas.createSprite(W, ROW_H);
  shownHeader[0] = '\0';
  for (auto& r : shownRow) r[0] = '\0';
}

// Wi-Fi symbol: three arcs over a dot, centered on (cx, cy) at the bottom
static void drawWifi(LGFX_Sprite& c, int cx, int cy, uint16_t color) {
  c.fillCircle(cx, cy, 2, color);
  for (int r = 6; r <= 14; r += 4) c.fillArc(cx, cy, r, r - 2, 225, 315, color);
}

// Network icon, ending at x = right
static void drawNet(LGFX_Sprite& c, int right, int cy, NetState net) {
  int cx = right - 14;
  switch (net) {
    case NET_ONLINE: drawWifi(c, cx, cy + 6, C_TEXT); break;
    case NET_CONNECTING: drawWifi(c, cx, cy + 6, C_AMBER); break;
    case NET_OFFLINE:
      drawWifi(c, cx, cy + 6, C_GRAY);
      c.drawWideLine(cx - 11, cy - 8, cx + 11, cy + 8, 1, C_RED);
      break;
    case NET_UPLOAD_FAILING:
      // Wi-Fi is up but uploads aren't working: the Wi-Fi symbol plus an amber "!"
      drawWifi(c, cx - 4, cy + 6, C_TEXT);
      c.fillRoundRect(cx + 11, cy - 9, 4, 12, 2, C_AMBER);
      c.fillCircle(cx + 13, cy + 7, 2, C_AMBER);
      break;
    default: break;
  }
}

static void drawHeader(NetState net, const char* clock) {
  LGFX_Sprite& c = headerCanvas;
  c.fillScreen(C_BG);
  c.setTextColor(C_GREEN, C_BG);
  c.setFont(&fonts::DejaVu18);
  c.setTextDatum(lgfx::middle_left);
  c.drawString("brew-em-all", 12, HEADER_H / 2);
  int right = W - 8;
  drawNet(c, right, HEADER_H / 2, net);
  if (net != NET_DISABLED) right -= 36;
  c.setFont(&fonts::DejaVu12);
  c.setTextColor(C_MUTED, C_BG);
  c.setTextDatum(lgfx::middle_right);
  c.drawString(clock, right, HEADER_H / 2);
  c.drawFastHLine(0, HEADER_H - 1, W, C_LINE);
  c.pushSprite(0, 0);
}

// strftime, tidied: "%l" and "%e" pad with a space, so collapse leading and doubled
// spaces ("Brewed  2:41 PM" -> "Brewed 2:41 PM"), then lower-case a final AM/PM.
static void formatTime(char* out, size_t len, const char* fmt, const struct tm* t) {
  strftime(out, len, fmt, t);
  char* d = out;
  for (char* s = out; *s; ++s)
    if (!(*s == ' ' && (d == out || d[-1] == ' '))) *d++ = *s;
  *d = '\0';
  size_t n = strlen(out);
  if (n >= 2 && out[n - 1] == 'M' && (out[n - 2] == 'A' || out[n - 2] == 'P')) {
    out[n - 2] += 'a' - 'A';
    out[n - 1] += 'a' - 'A';
  }
}

static void formatAge(unsigned long minutes, char* out, size_t len) {
  if (minutes < 60) snprintf(out, len, "%lu min", minutes);
  else snprintf(out, len, "%luh %02lum", minutes / 60, minutes % 60);
}

void uiDraw(const char* const names[3], const PotReport pots[3], NetState net) {
  time_t now = time(nullptr);
  bool haveClock = clockValid();
  struct tm local;
  if (haveClock) localtime_r(&now, &local);

  // Header
  char clock[16] = "";
  if (otaBusy()) strcpy(clock, "Updating...");
  else if (haveClock) formatTime(clock, sizeof(clock), "%l:%M %p", &local);
  char key[32];
  snprintf(key, sizeof(key), "%d|%s", net, clock);
  if (strcmp(key, shownHeader) != 0) {
    strcpy(shownHeader, key);
    drawHeader(net, clock);
  }

  // Rows
  for (int i = 0; i < 3; ++i) {
    const PotReport& p = pots[i];
    unsigned long minutes = p.ageMs / 60000UL;
    char age[16], sub[32] = "", word[8] = "";
    uint16_t color = C_GRAY;
    int bar = 0;   // freshness bar length in pixels
    const int barW = W - 24;
    if (p.state == POT_REMOVED) {
      strcpy(age, "-");
      strcpy(sub, "Not on the rack");
    } else if (p.state == POT_UNKNOWN) {
      strcpy(age, "?");
      strcpy(sub, "There since power-on");
    } else {
      formatAge(minutes, age, sizeof(age));
      if (minutes < FRESH_MIN) { color = C_GREEN; strcpy(word, "Fresh"); }
      else if (minutes < OLD_MIN) { color = C_AMBER; strcpy(word, "OK"); }
      else { color = C_RED; strcpy(word, "Old"); }
      bar = minutes >= OLD_MIN ? 0 : (int)(barW - (long)barW * minutes / OLD_MIN);
      if (haveClock) {
        time_t brewed = now - (time_t)(p.ageMs / 1000);
        struct tm b;
        localtime_r(&brewed, &b);
        // The time of day for the last 20 hours, then the date
        formatTime(sub, sizeof(sub), minutes < 20 * 60 ? "Brewed %l:%M %p" : "Brewed %b %e", &b);
      }
    }

    char rowKey[96];
    snprintf(rowKey, sizeof(rowKey), "%s|%s|%s|%d|%d", age, sub, word, bar, color);
    if (strcmp(rowKey, shownRow[i]) == 0) continue;
    strcpy(shownRow[i], rowKey);

    canvas.fillScreen(C_BG);
    canvas.setTextDatum(lgfx::top_left);
    canvas.setFont(&fonts::DejaVu18);
    canvas.setTextColor(C_TEXT, C_BG);
    canvas.drawString(names[i], 12, 10);
    canvas.setTextDatum(lgfx::top_right);
    canvas.setFont(&fonts::FreeSansBold18pt7b);
    canvas.setTextColor(color, C_BG);
    canvas.drawString(age, W - 12, 6);

    canvas.setFont(&fonts::DejaVu12);
    canvas.setTextColor(C_MUTED, C_BG);
    canvas.setTextDatum(lgfx::top_left);
    canvas.drawString(sub, 12, 40);
    canvas.setTextDatum(lgfx::top_right);
    canvas.drawString(word, W - 12, 40);

    canvas.fillRoundRect(12, 57, barW, 4, 2, C_LINE);
    if (bar > 0) canvas.fillRoundRect(12, 57, bar < 4 ? 4 : bar, 4, 2, color);
    if (i < 2) canvas.drawFastHLine(0, ROW_H - 1, W, C_LINE);
    canvas.pushSprite(0, HEADER_H + i * ROW_H);
  }
}

