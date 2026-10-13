// brew-em-all case v2: a sensor bar along the pots, a mast, and a head with
// the LCD, the ESP32-S3-Zero and the Porcupine power board.
//
// Frame (mm): X runs left -> right as seen from the front, Y runs up the wall,
// Z points out of the wall (Z = 0 is the wall). The center sensor's LEDs are at
// X = 0, and the mast and head are centered on it.
//
// Every body has a flat, solid back (for Velcro) and is open to the front.
// Bodies print back-down exactly as modeled; covers and strips print face-down.
// Nothing needs supports: everything rises from the bed, and the only holes
// through vertical walls are open-topped notches or 45° gables.
//
// The boards, LEDs and wires are drawn only in preview (F5) with SHOW_PARTS on.
// Rendering (F6) or exporting never includes them.

// What to show or export:
//   Views (preview with F5; the boards and wires show only here):
//     "assembly"          everything, closed (default)
//     "assembly_open"     covers and strips removed, to see the boards inside
//     "exploded"          covers and strips pulled forward by EXPLODE (default 30 mm)
//   Print parts (each laid out on the bed, ready to export with F6):
//     "bar_left", "bar_center", "bar_right"                    bar bodies, on their backs
//     "bar_cover_left", "bar_cover_center", "bar_cover_right"  bar covers, face down
//     "mast_lower", "mast_upper"                               mast pieces, on their backs
//     "mast_strip_lower", "mast_strip_upper"                   mast strips, face down
//     "head", "head_cover"                                     head body (back) and cover (face down)
//   Test prints:
//     "sensor_test"   a piece of the center bar around its sensor, plus its cover
//     "esp_test"      the bottom strip of the head: ESP32 and Porcupine board mounts
//     "joint_test"    the bar dovetail, the mast socket, the mast dovetail and a strip, all in one print
//     "joint_test_view"  the joint_test pieces fitted together (EXPLODE pulls them apart)
PART = "assembly";
SHOW_PARTS = true;  // preview only; never in an STL
EXPLODE = 0;        // pulls covers and strips forward in the assembly views

/* ---------- Fit (from office_ac_controller: tune after test prints) ---------- */
clr       = 0.3;   // general clearance per side
cover_clr = 0.1;   // gap between a cover's lip and the body's rebate (0.2 printed loose)
rib       = 0.35;  // crush ribs stand this far out (0.25 mm interference with cover_clr 0.1)
rib_pitch = 20;    // crush ribs every this far along each edge
wall      = 2.4;
plate     = 1.6;   // front cover plate thickness
lip_h     = 3.0;   // how far a cover's lip reaches down over the body
lip_t     = 1.2;   // lip thickness = depth of the body's rebate
$fn = 48;

/* ---------- Placement ---------- */
velcro_w       = 20;          // Velcro strip width; the backs are at least this tall
screen_h       = 12.5 * 25.4; // center sensor's LEDs -> bottom of the visible image
sensor_spacing = 203.2;       // pot spacing, same as the old case
joint          = 87;          // bar segments meet at X = ±joint

/* ---------- FC-51 IR sensor (measured) ---------- */
// Board coordinates [u, v]: u from the header end, v down from the long edge
// nearest the emitter (photo orientation: header left, clear emitter on top).
fc_l      = 32.1;
fc_w      = 14.1;
fc_t      = 1.0;
fc_back   = 2.0;           // solder joints on the back
fc_led_d  = 5.0;
fc_led_h  = 11.0;          // board surface to LED tip
fc_em     = [29.7, 2.3];   // IR emitter (clear)
fc_rx     = [30.0, 9.9];   // IR receiver (black)
fc_hole   = [8.4, 6.0];
fc_hole_d = 3.0;
fc_pot    = [17.4, 9.4];   // sensitivity screw
fc_pot_sz = [6.6, 7.0, 4.8];
fc_hdr_out = 6.0;          // right-angle header pins past the board's end
fc_hdr_v  = 6.3;           // header's middle pin (GND), down from the emitter-side edge
dupont_l  = 14.5;
sensor_flip = [true, false, false]; // left sensor turned 180° so its header faces the center

led_clr   = 0.2;   // LED hole clearance per side
// The LED tips stick out through one slot in the cover, like the old case's window.
// Covers that sat the tips behind the front face (3 mm deep holes or slot, or tubes
// around each LED) read "present" all the time: the IR reflected inside the cover.
led_out   = 1.5;   // LED tips stick out this far past the front face
tune_d    = 4.0;   // tuning hole for the sensitivity screw
channel   = 5.0;   // wire channel behind the sensor boards
post_d    = 5.0;   // post under the board's mounting hole (keep it clear of solder joints)

/* ---------- Mast ---------- */
mast_w     = 16;
mast_side  = 2;
mast_back  = 2;
mast_body_d = 12;  // back + channel; the strip adds `plate` in front
cheek_t    = 3;    // sockets on the bar's top and the head's bottom
cheek_h    = 12;
sock_clr   = 0.1;  // mast to socket cheek, per side (0.3 printed loose); the cheeks' crush ribs grip it
strip_over = 30;   // the strips split this far above the mast joint, tying the two pieces together

/* ---------- Dovetails in the back walls (bar segments and mast pieces) ---------- */
dt_clr  = 0.05;            // clearance per side (0.15 printed loose)
dt_rib  = 0.15;            // crush rib on each slanted side of a tab (0.1 mm interference)
bar_dt  = [8, 12, 6];      // root width, tip width, length
mast_dt = [6, 9, 5];

/* ---------- Head: LCD (Waveshare 2", measured) ---------- */
lcd_pcb       = [58, 35, 1.5];
lcd_glass     = 2.0;          // glass (and front screw heads) proud of the PCB
lcd_panel     = [49, 34.5];   // glass outline, centered on the PCB
lcd_img       = [40.8, 30.6]; // lit image (datasheet)
lcd_img_dx    = 1.7;          // image center sits this far right of the PCB center (away from the header)
lcd_hole_in   = [2.4, 2.75];  // corner holes, in from the PCB's edges
lcd_standoff  = 6.0;          // brass standoffs on the back
lcd_standoff_d = 4.0;
lcd_hdr_x     = 2.3;          // header pins from the PCB's left edge (front view), pointing back
lcd_back_clear = 24;          // PCB back to the wall: header + Dupont housings + bend
win_margin    = 0.6;          // window margin around the lit image
screw_relief_d = 6.0;
lcd_post_gap  = 0.0;          // raise if the cover won't close over the LCD

/* ---------- Head: ESP32-S3-Zero and the "Porcupine" power board (measured) ---------- */
esp       = [23.5, 18, 1.7];
esp_top   = 3.0;     // USB-C height above the PCB
esp_stack = 24;      // USB-C top to the jumper bend
usb_over  = 1.0;     // USB-C past the board's end
usb_w     = 9.0;
usb_plug  = [13, 7.5]; // opening for the cable's plug (width along Y, height along Z)
esp_jaw   = [2.5, 10]; // supports under the board's short ends (X length, Y width)
pwr       = [20, 13.8, 1.6]; // Porcupine board, pin rows along X (13.8 measured with calipers)
pwr_feet  = 2.0;           // clears the solder bridges underneath

/* ---------- Bar: the "spider" power board (measured) ---------- */
// Splits the mast's 3V3 and GND to the three sensors. Two rows of 5 right-angle
// pins, one row per rail, pointing out of opposite ends: 3V3 to the left, GND to the right.
sp        = [20, 16.1, 1.5]; // PCB: X (pin direction) x Y x thickness
sp_x0     = 20;              // left edge of the board, in the center segment
sp_row_in = 4.0;             // pin rows, in from the left and right edges
sp_pin_h  = 7.0;             // bottom of the solder to the top of the pins' bend
sp_solder = 1.0;             // solder bridges underneath
sp_feet   = 1.5;             // corner feet that clear them

/* =================================================================== */
/* Derived dimensions                                                   */
/* =================================================================== */

fc_mid = [(fc_em[0] + fc_rx[0]) / 2, (fc_em[1] + fc_rx[1]) / 2];
function P(p) = [p[0] - fc_mid[0], fc_mid[1] - p[1]]; // board -> local XY around the LEDs
fc_half_h = max(fc_mid[1], fc_w - fc_mid[1]);       // covers both orientations

bar_h   = max(2 * (fc_half_h + clr + wall), velcro_w);
y_s     = bar_h / 2;                         // LED midpoint height
z_board = wall + channel + fc_back;          // PCB back face
z_btop  = z_board + fc_t;                    // PCB component face
z_tip   = z_btop + fc_led_h;                 // LED tips
bar_d   = z_tip - led_out;                   // front face
bar_top = bar_d - plate;                     // top of the body walls

sx = [-sensor_spacing, 0, sensor_spacing];
// How far the board or its LEDs reach past the LED midpoint, away from the header
board_reach = max(fc_l - fc_mid[0], max(abs(fc_em[0] - fc_mid[0]), abs(fc_rx[0] - fc_mid[0])) + fc_led_d / 2);
bar_x0 = -sensor_spacing - board_reach - clr - wall;
bar_x1 =  sensor_spacing + board_reach + clr + wall;
seg_x  = [[bar_x0, -joint], [-joint, joint], [joint, bar_x1]];

mast_in_w = mast_w - 2 * mast_side;
mast_d    = mast_body_d + plate;

head_w   = lcd_pcb[0] + 2 * (clr + wall);
esp_x0   = wall + clr + usb_over;
esp_x1   = esp_x0 + esp[0];
esp_y0   = wall + clr;
esp_y1   = esp_y0 + esp[1];
esp_cy   = (esp_y0 + esp_y1) / 2;
esp_z1   = wall + esp_stack - esp_top;       // PCB top
esp_z0   = esp_z1 - esp[2];
usb_cz   = esp_z1 + esp_top / 2;
pwr_x1   = head_w - wall - clr;
pwr_x0   = pwr_x1 - pwr[0];
pwr_y0   = wall + clr;
pwr_z0   = wall + pwr_feet;
lcd_x0   = wall + clr;
lcd_y0   = esp_y1 + 2 + clr;
head_h   = lcd_y0 + lcd_pcb[1] + clr + wall;
head_top = wall + lcd_back_clear + lcd_pcb[2] + lcd_glass; // glass face = cover's inner face
head_d   = head_top + plate;
lcd_zf   = head_top - lcd_glass;                // PCB front face
lcd_zb   = lcd_zf - lcd_pcb[2];                 // PCB back face
img_c    = [lcd_x0 + lcd_pcb[0] / 2 + lcd_img_dx, lcd_y0 + lcd_pcb[1] / 2];
img_bot  = img_c[1] - lcd_img[1] / 2;
lcd_holes = [for (i = [0, 1], j = [0, 1])
  [lcd_x0 + (i ? lcd_pcb[0] - lcd_hole_in[0] : lcd_hole_in[0]),
   lcd_y0 + (j ? lcd_pcb[1] - lcd_hole_in[1] : lcd_hole_in[1])]];

z_sp0   = wall + sp_feet;                       // spider PCB bottom
sp_pin_z = z_sp0 - sp_solder + sp_pin_h - 0.32; // center of its horizontal pins

y_hb    = y_s + screen_h - img_bot;            // head bottom
mast_y0 = bar_h;
mast_y1 = y_hb;
mast_ys = (mast_y0 + mast_y1) / 2;             // joint between the two mast pieces
strip_ys = mast_ys + strip_over;

echo(str("Bar ", bar_x1 - bar_x0, " x ", bar_h, " x ", bar_d, " mm (segments ",
         -joint - bar_x0, " / ", 2 * joint, " / ", bar_x1 - joint, ")"));
echo(str("Head ", head_w, " x ", head_h, " x ", head_d, " mm; mast ", mast_y1 - mast_y0,
         " mm in two ", (mast_y1 - mast_y0) / 2, " mm pieces"));

/* =================================================================== */
/* Helpers                                                              */
/* =================================================================== */

module box(a, b) translate(a) cube([b[0] - a[0], b[1] - a[1], b[2] - a[2]]);

// Polygon in the XZ plane, extruded along Y from y0 to y1
module prism_xz(pts, y0, y1) multmatrix([[1, 0, 0, 0], [0, 0, 1, y0], [0, 1, 0, 0]])
  linear_extrude(y1 - y0) polygon(pts);

// Gable-topped opening through a horizontal wall (no bridging when printed back-down)
module gable_hole(xc, half_w, z0, z1, y0, y1)
  prism_xz([[xc - half_w, z0], [xc + half_w, z0], [xc + half_w, z1],
            [xc, z1 + half_w], [xc - half_w, z1]], y0, y1);

// Crush rib along Z on a face. `n` is the face's outward normal.
module rib_z(x, y, z0, z1, n) {
  c = [x + n[0] * (rib - 0.5), y + n[1] * (rib - 0.5)];
  translate([c[0], c[1], z0]) cylinder(r = 0.5, h = z1 - z0, $fn = 12);
}
// Crush rib along X on a face (normal ±Y)
module rib_x(x0, x1, y, z, ny) translate([x0, y + ny * (rib - 0.5), z])
  rotate([0, 90, 0]) cylinder(r = 0.5, h = x1 - x0, $fn = 12);

// Cut the rebate that a cover's lip slides over, on the given sides
module rebate_cut(x0, x1, h, top, cl, cr) translate([0, 0, top - lip_h]) difference() {
  translate([x0 - 1, -1, 0]) cube([x1 - x0 + 2, h + 2, lip_h + 1]);
  translate([cl ? x0 + lip_t : x0 - 2, lip_t, -1])
    cube([(cr ? x1 - lip_t : x1 + 2) - (cl ? x0 + lip_t : x0 - 2), h - 2 * lip_t, lip_h + 3]);
}
module rebate_ribs(x0, x1, h, top, cl, cr) {
  z0 = top - lip_h; z1 = top - 0.6;
  n = max(2, round((x1 - x0) / rib_pitch));
  for (k = [0 : n - 1]) {
    x = x0 + (x1 - x0) * (k + 0.5) / n;
    rib_z(x, lip_t, z0, z1, [0, -1]);
    rib_z(x, h - lip_t, z0, z1, [0, 1]);
  }
  m = max(1, round(h / rib_pitch));
  for (k = [0 : m - 1]) {
    y = h * (k + 0.5) / m;
    if (cl) rib_z(x0 + lip_t, y, z0, z1, [-1, 0]);
    if (cr) rib_z(x1 - lip_t, y, z0, z1, [1, 0]);
  }
}
// A cover's lip: a frame on the given sides, hanging below the plate
module cover_lip(x0, x1, h, top, cl, cr) {
  t = lip_t - cover_clr;
  translate([0, 0, top - lip_h + cover_clr]) difference() {
    translate([x0, 0, 0]) cube([x1 - x0, h, lip_h - cover_clr + 0.01]);
    translate([cl ? x0 + t : x0 - 1, t, -1])
      cube([(cr ? x1 - t : x1 + 1) - (cl ? x0 + t : x0 - 1), h - 2 * t, lip_h + 2]);
  }
}

// Dovetail outline: root at u = 0 (width a), widening to b at u = L.
// dir = +1 points along +X, -1 along -X; "axis" picks X or Y as the length direction.
module dovetail_2d(a, b, L, grow = 0) offset(delta = grow)
  polygon([[0, -a / 2], [L, -b / 2], [L, b / 2], [0, a / 2]]);

// Dovetail tab of height h, with a crush rib on each slanted side
module dovetail_tab(a, b, L, h) {
  linear_extrude(h) dovetail_2d(a, b, L + 0.01);
  d = [L, (b - a) / 2];                     // upper slanted side, from root to tip
  n = [-d[1], d[0]] / norm(d);              // its outward normal
  for (sy = [-1, 1]) {
    c = [L / 2, sy * (a + b) / 4] + [n[0], sy * n[1]] * (dt_rib - 0.5);
    translate([c[0], c[1], 0]) cylinder(r = 0.5, h = h - 0.4, $fn = 12);
  }
}

module at_sensor(i) translate([sx[i], y_s, 0]) rotate([0, 0, sensor_flip[i] ? 180 : 0]) children();

/* =================================================================== */
/* Sensor bar                                                           */
/* =================================================================== */

module bar_body(i) {
  x0 = seg_x[i][0]; x1 = seg_x[i][1];
  cl = i == 0; cr = i == 2;
  difference() {
    box([x0, 0, 0], [x1, bar_h, bar_top]);
    box([cl ? x0 + wall : x0 - 1, wall, wall], [cr ? x1 - wall : x1 + 1, bar_h - wall, bar_top + 1]);
    rebate_cut(x0, x1, bar_h, bar_top, cl, cr);
    // Dovetail notches in the end segments' back walls
    if (i != 1) translate([i == 0 ? x1 : x0, bar_h / 2, -1]) rotate([0, 0, i == 0 ? 180 : 0])
      translate([-0.01, 0, 0]) linear_extrude(wall + 2) dovetail_2d(bar_dt[0], bar_dt[1], bar_dt[2] + dt_clr + 0.01, dt_clr);
    // Wire opening up into the mast
    if (i == 1) gable_hole(0, mast_in_w / 2 - 0.5, wall, 8, bar_h - wall - 1, bar_h + 1);
  }
  rebate_ribs(x0, x1, bar_h, bar_top, cl, cr);

  // Post under the sensor's mounting hole, with a pin through the hole
  at_sensor(i) translate(concat(P(fc_hole), [0])) {
    translate([0, 0, wall - 0.01]) cylinder(d = post_d, h = z_board - wall + 0.01);
    translate([0, 0, z_board - 0.01]) cylinder(d = fc_hole_d - 0.4, h = fc_t + 0.8);
  }

  // Spider board: feet at its corners and stops at its ends (the bar's walls locate it top and bottom)
  if (i == 1) {
    for (x = [sp_x0, sp_x0 + sp[0] - 2.5], y = [y_s - sp[1] / 2, y_s + sp[1] / 2 - 2.5])
      translate([x, y, wall - 0.01]) cube([2.5, 2.5, sp_feet + 0.01]);
    for (x = [sp_x0 - clr - 1.6, sp_x0 + sp[0] + clr])
      box([x, y_s - 3, wall - 0.01], [x + 1.6, y_s + 3, z_sp0 + sp[2] + 1]);
  }

  // Dovetail tabs on the center segment's back wall
  if (i == 1) for (s = [-1, 1])
    translate([s * joint, bar_h / 2, 0]) rotate([0, 0, s > 0 ? 0 : 180])
      translate([-0.01, 0, 0]) dovetail_tab(bar_dt[0], bar_dt[1], bar_dt[2], wall);

  if (i == 1) {
    // Socket cheeks for the mast
    for (s = [-1, 1]) {
      x = s > 0 ? mast_w / 2 + sock_clr : -(mast_w / 2 + sock_clr + cheek_t);
      translate([x, bar_h - 0.01, 0]) cube([cheek_t, cheek_h, mast_d]);
      for (y = [bar_h + cheek_h * 0.3, bar_h + cheek_h * 0.7])
        rib_z(s * (mast_w / 2 + sock_clr), y, 0, mast_d - 0.6, [-s, 0]);
    }
  }
}

module bar_cover(i) {
  x0 = seg_x[i][0]; x1 = seg_x[i][1];
  cl = i == 0; cr = i == 2;
  bore = fc_led_d + 2 * led_clr;
  ring_z0 = z_btop + 0.2;
  pot_top = z_btop + fc_pot_sz[2];
  difference() {
    union() {
      box([x0, 0, bar_top], [x1, bar_h, bar_d]);
      cover_lip(x0, x1, bar_h, bar_top, cl, cr);
      // Clipped to the inside of the bar
      intersection() {
        box([cl ? x0 + wall + cover_clr : x0 - 1, wall + cover_clr, 0], [cr ? x1 - wall - cover_clr : x1 + 1, bar_h - wall - cover_clr, bar_d]);
        at_sensor(i) {
        // Guide tube over the sensitivity screw
        translate(concat(P(fc_pot), [pot_top + 0.5])) cylinder(d = tune_d + 2.4, h = bar_top - pot_top - 0.49);
        // Ring that presses the board onto its post
        translate(concat(P(fc_hole), [ring_z0])) cylinder(d = 6, h = bar_top - ring_z0 + 0.01);
        }
      }
      // Post that holds the spider board down, on its empty middle
      if (i == 1) translate([sp_x0 + sp[0] / 2, y_s, z_sp0 + sp[2] + 0.2]) cylinder(d = 4, h = bar_top - z_sp0 - sp[2] - 0.19);
    }
    at_sensor(i) {
      // One slot for both LEDs, with no plastic between them
      hull() for (p = [fc_em, fc_rx]) translate(concat(P(p), [bar_top - 1])) cylinder(d = bore, h = bar_d);
      translate(concat(P(fc_pot), [0])) cylinder(d = tune_d, h = bar_d + 1);
      translate(concat(P(fc_hole), [ring_z0 - 1])) cylinder(d = 3.6, h = bar_top - ring_z0 + 1);
    }
  }
}

/* =================================================================== */
/* Mast                                                                 */
/* =================================================================== */

// A mast piece. tab_below: dovetail tab hanging below y0; notch_above: notch at y1.
module mast_piece(y0, y1, tab_below, notch_above) {
  difference() {
    box([-mast_w / 2, y0, 0], [mast_w / 2, y1, mast_body_d]);
    box([-mast_in_w / 2, y0 - 1, mast_back], [mast_in_w / 2, y1 + 1, mast_body_d + 1]);
    if (notch_above) translate([0, y1 + 0.01, -1]) rotate([0, 0, -90])
      linear_extrude(mast_back + 2) dovetail_2d(mast_dt[0], mast_dt[1], mast_dt[2] + dt_clr + 0.01, dt_clr);
  }
  if (tab_below) translate([0, y0 + 0.01, 0]) rotate([0, 0, -90])
    dovetail_tab(mast_dt[0], mast_dt[1], mast_dt[2], mast_back);
}

module mast_strip(y0, y1) {
  t = lip_t;
  xo = mast_in_w / 2 - cover_clr;
  translate([-mast_w / 2, y0, mast_body_d]) cube([mast_w, y1 - y0, plate]);
  for (s = [-1, 1]) {
    translate([s > 0 ? xo - t : -xo, y0 + 2, mast_body_d - 2.5]) cube([t, y1 - y0 - 4, 2.51]);
    for (y = [y0 + rib_pitch / 2 : rib_pitch : y1 - 2])
      translate([s * xo - s * (0.5 - rib), y, mast_body_d - 2.5]) cylinder(r = 0.5, h = 2.5, $fn = 12);
  }
}

/* =================================================================== */
/* Head (built at the origin, placed by head_place)                     */
/* =================================================================== */

module head_place() translate([-head_w / 2, y_hb, 0]) children();

module head_body() {
  difference() {
    box([0, 0, 0], [head_w, head_h, head_top]);
    box([wall, wall, wall], [head_w - wall, head_h - wall, head_top + 1]);
    rebate_cut(0, head_w, head_h, head_top, true, true);
    // USB-C opening in the left wall (open at the top; the cover closes it)
    box([-1, esp_cy - usb_plug[0] / 2, usb_cz - usb_plug[1] / 2], [wall + 1, esp_cy + usb_plug[0] / 2, head_top + 1]);
    // Wire opening down into the mast
    gable_hole(head_w / 2, mast_in_w / 2 - 0.5, wall, 8, -1, wall + 1);
  }
  difference() {   // no ribs inside the USB-C opening
    rebate_ribs(0, head_w, head_h, head_top, true, true);
    box([-1, esp_cy - usb_plug[0] / 2 - 1, 0], [wall + 1, esp_cy + usb_plug[0] / 2 + 1, head_top + 1]);
  }

  // LCD: posts under the standoffs, each with a pin into the standoff's bore
  for (h = lcd_holes) translate([h[0], h[1], 0]) {
    zt = lcd_zb - lcd_standoff - lcd_post_gap;
    translate([0, 0, wall - 0.01]) cylinder(d = lcd_standoff_d + 1, h = zt - wall + 0.01);
    translate([0, 0, zt - 0.01]) cylinder(d = 1.5, h = 1.5);
  }

  // ESP32: supports under both short ends, between the header rows
  for (x = [esp_x0, esp_x1 - esp_jaw[0]])
    box([x, esp_cy - esp_jaw[1] / 2, wall - 0.01], [x + esp_jaw[0], esp_cy + esp_jaw[1] / 2, esp_z0]);
  // Stop at the far end and along the top edge (the left wall and the floor do the rest)
  box([esp_x1 + clr, esp_cy - 3, wall - 0.01], [esp_x1 + clr + 2, esp_y1 + clr + 2, esp_z1 + 1]);
  box([esp_x1 - 5, esp_y1 + clr, wall - 0.01], [esp_x1 + clr + 2, esp_y1 + clr + 2, esp_z1 + 1]);

  // Porcupine board: feet at the corners and corner fences with crush ribs
  for (i = [0, 1], j = [0, 1]) {
    cx = i ? pwr_x1 : pwr_x0; cy = j ? pwr_y0 + pwr[1] : pwr_y0;
    sx_ = i ? -1 : 1; sy_ = j ? -1 : 1;
    translate([cx + (i ? -2.5 : 0), cy + (j ? -2.5 : 0), wall - 0.01]) cube([2.5, 2.5, pwr_feet + 0.01]);
    // L-shaped fence just outside the corner
    fz = pwr_z0 + pwr[2] + 1.2;
    translate([cx + (i ? clr : -clr - 1.6), cy + (j ? -5 : 0) - (j ? 0 : 0), wall - 0.01])
      cube([1.6, 5 + (j ? clr + 1.6 : 0), fz - wall + 0.01]);
    translate([cx + (i ? -5 : 0), cy + (j ? clr : -clr - 1.6), wall - 0.01])
      cube([5 + (i ? clr + 1.6 : 0), 1.6, fz - wall + 0.01]);
  }

  // Socket cheeks for the mast, under the head
  for (s = [-1, 1]) {
    x = head_w / 2 + (s > 0 ? mast_w / 2 + sock_clr : -(mast_w / 2 + sock_clr + cheek_t));
    translate([x, -cheek_h, 0]) cube([cheek_t, cheek_h + 0.01, mast_d]);
    for (y = [-cheek_h * 0.3, -cheek_h * 0.7])
      rib_z(head_w / 2 + s * (mast_w / 2 + sock_clr), y, 0, mast_d - 0.6, [-s, 0]);
  }
}

module head_cover() {
  ch = 1.0; // window chamfer on the front face
  difference() {
    union() {
      box([0, 0, head_top], [head_w, head_h, head_d]);
      difference() {
        cover_lip(0, head_w, head_h, head_top, true, true);
        box([-1, esp_cy - usb_plug[0] / 2, head_top - lip_h - 1], [lip_t + 1, esp_cy + usb_plug[0] / 2, head_top]);
      }
      // Posts that hold the ESP32 down at its corners
      for (x = [esp_x0 + 1.5, esp_x1 - 1.5], y = [esp_y0 + 1.5, esp_y1 - 1.5])
        translate([x, y, esp_z1 + 0.1]) cylinder(d = 2.5, h = head_top - esp_z1 - 0.09);
    }
    // Window over the lit image, chamfered toward the front
    hull() {
      translate([img_c[0] - lcd_img[0] / 2 - win_margin, img_c[1] - lcd_img[1] / 2 - win_margin, head_top - 1])
        cube([lcd_img[0] + 2 * win_margin, lcd_img[1] + 2 * win_margin, plate - ch + 1.01]);
      translate([img_c[0] - lcd_img[0] / 2 - win_margin - ch, img_c[1] - lcd_img[1] / 2 - win_margin - ch, head_d - 0.01])
        cube([lcd_img[0] + 2 * (win_margin + ch), lcd_img[1] + 2 * (win_margin + ch), 1]);
    }
    // Reliefs for the LCD's front screw heads
    for (h = lcd_holes) translate([h[0], h[1], head_top - 0.01]) cylinder(d = screw_relief_d, h = 0.8);
  }
}

/* =================================================================== */
/* Parts (preview only)                                                 */
/* =================================================================== */

module fc51() {
  // PCB
  color("royalblue") translate([P([0, 0])[0], P([0, fc_w])[1], z_board]) cube([fc_l, fc_w, fc_t]);
  // LEDs
  color("white", 0.8) translate(concat(P(fc_em), [z_btop])) cylinder(d = fc_led_d, h = fc_led_h);
  color("black") translate(concat(P(fc_rx), [z_btop])) cylinder(d = fc_led_d, h = fc_led_h);
  // Sensitivity screw
  color("deepskyblue") translate(concat(P(fc_pot) - [fc_pot_sz[0], fc_pot_sz[1]] / 2, [z_btop])) cube(fc_pot_sz);
  // Header, pins and jumpers
  hy = P([0, fc_hdr_v])[1];
  color("black") translate([P([0, 0])[0], hy - 3.8, z_btop]) cube([2.5, 7.6, 2.5]);
  for (k = [-1, 0, 1]) {
    color("gold") translate([P([0, 0])[0] - fc_hdr_out, hy + k * 2.54 - 0.32, z_btop + 0.9]) cube([fc_hdr_out, 0.64, 0.64]);
    color("dimgray") translate([P([0, 0])[0] - dupont_l, hy + k * 2.54 - 1.27, z_btop]) cube([dupont_l, 2.54, 2.54]);
  }
  // Solder joints
  color("silver") translate([P([0, 0])[0] + 1, P([0, fc_w])[1] + 1, z_board - fc_back]) cube([fc_l - 2, fc_w - 2, fc_back]);
}

module lcd() {
  color("steelblue") translate([lcd_x0, lcd_y0, lcd_zb]) cube(lcd_pcb);
  color("white") translate([lcd_x0 + (lcd_pcb[0] - lcd_panel[0]) / 2, lcd_y0 + (lcd_pcb[1] - lcd_panel[1]) / 2, lcd_zf])
    cube([lcd_panel[0], lcd_panel[1], lcd_glass - 0.05]);
  color("midnightblue") translate([img_c[0] - lcd_img[0] / 2, img_c[1] - lcd_img[1] / 2, head_top - 0.06]) cube([lcd_img[0], lcd_img[1], 0.05]);
  for (h = lcd_holes) {
    color("gold") translate([h[0], h[1], lcd_zb - lcd_standoff]) cylinder(d = lcd_standoff_d, h = lcd_standoff, $fn = 6);
    color("silver") translate([h[0], h[1], lcd_zf]) cylinder(d = 4.5, h = lcd_glass - 0.1);
  }
  for (k = [0 : 7]) {
    y = lcd_pin(k)[1];
    color("gold") translate([lcd_x0 + lcd_hdr_x - 0.32, y - 0.32, lcd_zb - 8.5]) cube([0.64, 0.64, 8.5]);
    color("dimgray") translate([lcd_x0 + lcd_hdr_x - 1.27, y - 1.27, lcd_zb - 2.5 - dupont_l]) cube([2.54, 2.54, dupont_l]);
  }
  color("black") translate([lcd_x0 + lcd_hdr_x - 1.27, img_c[1] - 4 * 2.54, lcd_zb - 2.5]) cube([2.54, 8 * 2.54, 2.5]);
}

module esp32() {
  color("navy") translate([esp_x0, esp_y0, esp_z0]) cube(esp);
  color("silver") translate([esp_x0 - usb_over, esp_cy - usb_w / 2, esp_z1]) cube([7.5, usb_w, esp_top]);
  for (e = [0, 1]) {
    color("black") translate([esp_x0 + 0.3, e ? esp_y1 - 2.5 : esp_y0, esp_z0 - 2.5]) cube([esp[0] - 0.6, 2.5, 2.5]);
    for (k = esp_used[e]) color("dimgray")
      translate(esp_pin(e, k) - [1.2, 1.25, 0]) cube([2.4, 2.5, dupont_l]);
  }
}

module pwr_board() {
  color("seagreen") translate([pwr_x0, pwr_y0, pwr_z0]) cube(pwr);
  for (r = [0, 1], k = [0 : 5]) {
    x = pwr_x0 + pwr[0] / 2 + (k - 2.5) * 2.54;
    y = pwr_y0 + pwr[1] / 2 + (r - 0.5) * 2 * 2.54;
    color("black") translate([x - 1.27, y - 1.27, pwr_z0 + pwr[2]]) cube([2.54, 2.54, 2.5]);
    color("dimgray") translate([x - 1.2, y - 1.2, pwr_z0 + pwr[2] + 2.5]) cube([2.4, 2.4, dupont_l]);
  }
}

// Spider board in the bar
module spider() {
  color("seagreen") translate([sp_x0, y_s - sp[1] / 2, z_sp0]) cube(sp);
  color("silver") translate([sp_x0 + sp_row_in - 0.5, y_s - 6, z_sp0 - sp_solder]) cube([1, 12, sp_solder]);
  color("silver") translate([sp_x0 + sp[0] - sp_row_in - 0.5, y_s - 6, z_sp0 - sp_solder]) cube([1, 12, sp_solder]);
  for (side = [-1, 1], k = [0 : 4]) {
    p = sp_pin(side, k);
    row = side < 0 ? sp_x0 + sp_row_in : sp_x0 + sp[0] - sp_row_in;
    color("black") translate([row - 1.25, p[1] - 1.27, z_sp0 + sp[2]]) cube([2.5, 2.54, sp_pin_z - z_sp0 - sp[2] + 1.27]);
    color("dimgray") translate([side < 0 ? p[0] : row + 1.25, p[1] - 1.27, sp_pin_z - 1.27]) cube([dupont_l, 2.54, 2.54]);
  }
}

/* ---------- Wire end points (where each wire leaves its Dupont housing) ---------- */
// Sensor i's header: k = +1 OUT, 0 GND, -1 VCC
function sens_pin(i, k) = let(f = sensor_flip[i], lx = -fc_mid[0] - dupont_l, ly = fc_mid[1] - fc_hdr_v + k * 2.54)
  [sx[i] + (f ? -lx : lx), y_s + (f ? -ly : ly), z_btop + 1.27];
// Spider: side -1 = 3V3 row (left), +1 = GND row (right); k = 0 mast feed, 1-3 sensors 0-2, 4 spare
function sp_pin(side, k) = [side < 0 ? sp_x0 + sp_row_in - 1.25 - dupont_l : sp_x0 + sp[0] - sp_row_in + 1.25 + dupont_l,
                            y_s + (k - 2) * 2.54, sp_pin_z];
// ESP32 (head coordinates). It's turned so USB-C faces left: edge 0 (bottom) reads
// 5V, GND, 3V3, 1, 2, 3, 4, 5, 6 from the left; edge 1 (top) reads TX, RX, 13, 12 ... 7.
esp_used = [[1, 2, 6, 7, 8], [3, 4, 5, 6, 7, 8]];
function esp_pin(e, k) = [esp_x0 + esp[0] / 2 + (k - 4) * 2.54, e ? esp_y1 - 1.25 : esp_y0 + 1.25, esp_z0 - 2.5 - dupont_l];
// Porcupine board (head coordinates): row 1 = 3V3, row 0 = GND; k = 0 ESP32, 1 LCD, 2 mast
function pwr_pin(r, k) = [pwr_x0 + pwr[0] / 2 + (k - 2.5) * 2.54, pwr_y0 + pwr[1] / 2 + (r - 0.5) * 2 * 2.54, pwr_z0 + pwr[2] + 2.5 + dupont_l];
// LCD header (head coordinates), top to bottom: VCC, GND, DIN, CLK, CS, DC, RST, BL
function lcd_pin(k) = [lcd_x0 + lcd_hdr_x, img_c[1] + (3.5 - k) * 2.54, lcd_zb - 2.5 - dupont_l];
function H(p) = [p[0] - head_w / 2, p[1] + y_hb, p[2]];
function Hs(ps) = [for (p = ps) H(p)];

module wire(pts, col, d = 1.4) color(col) for (i = [0 : len(pts) - 2])
  hull() { translate(pts[i]) sphere(d = d, $fn = 8); translate(pts[i + 1]) sphere(d = d, $fn = 8); }

// Every wire, along its planned route
module wires() {
  zc = wall + 2;        // channel behind the sensor boards
  zf = 15;              // in front, to pass over the spider board
  out_col = ["blue", "yellow", "teal"];
  mx = [-3, -1.5, 0, 1.5, 3];   // positions in the mast: 3 OUTs, 3V3, GND
  zm = mast_back + 3;
  for (i = [0 : 2]) {
    f = sensor_flip[i];
    away = sens_pin(i, 0)[0] + (sens_pin(i, 0)[0] > sx[i] ? 5 : -5); // just past the jumpers
    // OUT -> mast
    o = sens_pin(i, 1);
    lane_o = y_s - 5 + i * 0.9;
    wire(concat([o, [away, o[1], o[2]], [away, lane_o, zc]],
                 i == 2 ? [[sp_x0 + sp[0] + 20, lane_o, zc], [sp_x0 + sp[0] + 20, lane_o, zf], [mx[i] + 4, lane_o, zf], [mx[i], lane_o, zm]]
                        : [[mx[i], lane_o, zc]],
                 [[mx[i], bar_h + 2, zm]]), out_col[i]);
    // VCC -> spider's 3V3 row; GND -> its GND row
    v = sens_pin(i, -1); g = sens_pin(i, 0);
    pv = sp_pin(-1, i + 1); pg = sp_pin(1, i + 1);
    lane_v = y_s + 4 + i * 0.7; lane_g = y_s + 5.8 + i * 0.4;
    wire(i == 2 ? [v, [away, v[1], v[2]], [away, lane_v, zf], [pv[0] - 4, lane_v, zf], [pv[0] - 4, pv[1], pv[2]], pv]
                : [v, [away, v[1], v[2]], [away, lane_v, zc], [pv[0] - 4, lane_v, zc], [pv[0] - 4, pv[1], pv[2]], pv], "red");
    wire(i == 2 ? [g, [away, g[1], g[2]], [away, lane_g, zc], [pg[0] + 4, lane_g, zc], [pg[0] + 4, pg[1], pg[2]], pg]
                : [g, [away, g[1], g[2]], [away, lane_g, zc], [4, lane_g, zc], [4, lane_g, zf], [pg[0] + 4, lane_g, zf],
                   [pg[0] + 4, pg[1], pg[2]], pg], "black");
  }
  // Mast feed -> spider
  f3 = sp_pin(-1, 0); fg = sp_pin(1, 0);
  wire([[mx[3], bar_h + 2, zm], [mx[3], y_s - 6.5, zc], [f3[0] - 3, y_s - 6.5, zc], [f3[0] - 3, f3[1], f3[2]], f3], "red");
  wire([[mx[4], bar_h + 2, zm], [mx[4], y_s - 7.4, zc], [5, y_s - 7.4, zc], [5, y_s - 7.4, zf], [fg[0] + 3, y_s - 7.4, zf],
        [fg[0] + 3, fg[1], fg[2]], fg], "black");
  // Up the mast
  mcol = concat(out_col, ["red", "black"]);
  for (k = [0 : 4]) wire([[mx[k], bar_h + 2, zm], [mx[k], y_hb + 1, zm]], mcol[k]);

  // In the head
  hm = head_w / 2;
  for (k = [0 : 2]) {          // OUTs -> GP4, GP5, GP6
    e = esp_pin(0, 6 + k);
    wire(Hs([[hm + mx[k], 1, zm], [hm + mx[k], 3.9, 3.6], [e[0], 3.9, 3.6], e]), out_col[k]);
  }
  for (r = [1, 0]) {           // mast 3V3 / GND -> Porcupine board
    p = pwr_pin(r, 2);
    wire(Hs([[hm + mx[r ? 3 : 4], 1, zm], [hm + mx[r ? 3 : 4], 3.9, zm], [36, 3.9, zm], [36, 3.9, head_top - 3],
             [p[0], p[1], head_top - 3], p]), r ? "red" : "black");
  }
  for (r = [1, 0]) {           // ESP32 3V3 / GND -> Porcupine board
    e = esp_pin(0, r ? 2 : 1); p = pwr_pin(r, 0);
    wire(Hs([e, [e[0], 3.9, 3.4], [35, 3.9, 3.4], [35, 3.9, head_top - 4.5], [p[0], p[1], head_top - 4.5], p]), r ? "red" : "black");
  }
  for (r = [1, 0]) {           // LCD VCC / GND -> Porcupine board
    l = lcd_pin(r ? 0 : 1); p = pwr_pin(r, 1);
    wire(Hs([l, [l[0] + 3, l[1], l[2]], [36.5, 30, l[2]], [36.5, 30, head_top - 6], [p[0], p[1], head_top - 6], p]), r ? "red" : "saddlebrown");
  }
  sig = [[2, 4, "orange"], [3, 3, "yellow"], [4, 5, "green"], [5, 6, "purple"], [6, 7, "blue"], [7, 8, "gray"]];
  for (s_ = sig) {             // LCD signals -> GP11, 12, 10, 9, 8, 7
    l = lcd_pin(s_[0]); e = esp_pin(1, s_[1]); xl = 9 + s_[0] * 0.8;
    wire(Hs([l, [xl, l[1], l[2]], [xl, l[1], 3.4], [xl, 19.45, 3.4], [e[0], 19.45, 3.4], e]), s_[2]);
  }
}

module all_parts() {
  for (i = [0 : 2]) at_sensor(i) fc51();
  head_place() { lcd(); esp32(); pwr_board(); }
  spider();
  wires();
}

/* =================================================================== */
/* Assembly and print layouts                                           */
/* =================================================================== */

module assembly(covers = true, e = EXPLODE) {
  for (i = [0 : 2]) {
    color("whitesmoke") bar_body(i);
    if (covers) color("lightgray") translate([0, 0, e]) bar_cover(i);
  }
  color("whitesmoke") { mast_piece(mast_y0, mast_ys, false, true); mast_piece(mast_ys, mast_y1, true, false); }
  if (covers) color("lightgray") translate([0, 0, e]) { mast_strip(mast_y0, strip_ys); mast_strip(strip_ys, mast_y1); }
  head_place() {
    color("whitesmoke") head_body();
    if (covers) color("lightgray") translate([0, 0, e]) head_cover();
  }
  if ($preview && SHOW_PARTS) all_parts();
}

// Face-down for printing: rotate about X (no mirroring), drop onto the bed
module face_down(top) translate([0, 0, top]) rotate([180, 0, 0]) children();

module print_bar_body(i) translate([-seg_x[i][0], 0, 0]) bar_body(i);
module print_bar_cover(i) face_down(bar_d) translate([-seg_x[i][0], 0, 0]) bar_cover(i);

// Sensor test: a short piece of the center segment around its sensor, and the
// matching piece of its cover, side by side
module sensor_test() {
  xa = -fc_mid[0] - dupont_l / 2 - 6; xb = fc_l - fc_mid[0] + 6;
  translate([-xa, 0, 0]) intersection() {
    bar_body(1);
    box([xa, -1, -1], [xb, bar_h + 0.01, bar_d]);
  }
  translate([-xa, bar_h + 8 + bar_h, 0]) face_down(bar_d) intersection() {
    bar_cover(1);
    box([xa, -1, -1], [xb, bar_h + 1, bar_d + 1]);
  }
}

// Joint test: short pieces cut from the real parts, laid out in a row.
//   1, 2  the center segment's end (dovetail tab) and the left segment's end (notch)
//   3     the middle of the center segment: mast socket cheeks and wire opening
//         (the head's socket uses the same cheeks)
//   4, 5  a short lower mast piece (plugs into 3, notch on top) and a short upper piece (tab)
//   6     a short mast strip that presses onto 4
module joint_test() {
  translate([joint + 7, 0, 0]) intersection() {
    bar_body(1);
    box([-joint - bar_dt[2] - 1, -1, -1], [-joint + 12, bar_h + 1, bar_d]);
  }
  translate([joint + 14 + 25, 0, 0]) intersection() {
    bar_body(0);
    box([-joint - 14, -1, -1], [-joint + 1, bar_h + 1, bar_d]);
  }
  translate([65, 0, 0]) intersection() {
    bar_body(1);
    box([-15, -1, -1], [15, bar_h + cheek_h + 1, bar_d]);
  }
  translate([95, -mast_y0, 0]) mast_piece(mast_y0, mast_y0 + 25, false, true);
  translate([115, -(mast_y0 + 25 - mast_dt[2]), 0]) mast_piece(mast_y0 + 25, mast_y0 + 40, true, false);
  translate([135, 25, 0]) face_down(mast_d) translate([0, -mast_y0, 0]) mast_strip(mast_y0, mast_y0 + 25);
}

// The joint_test pieces in their real positions, to show how they go together
module joint_test_view(e = EXPLODE) {
  // Bar dovetail: the left segment's end presses onto the center segment's tab from the front
  translate([joint + 10, 0, 0]) {
    color("whitesmoke") intersection() { bar_body(1); box([-joint - bar_dt[2] - 1, -1, -1], [-joint + 12, bar_h + 1, bar_d]); }
    color("lightsteelblue") translate([0, 0, e]) intersection() { bar_body(0); box([-joint - 14, -1, -1], [-joint + 1, bar_h + 1, bar_d]); }
  }
  // Mast socket, mast pieces and strip
  translate([60, 0, 0]) {
    color("whitesmoke") intersection() { bar_body(1); box([-15, -1, -1], [15, bar_h + cheek_h + 1, bar_d]); }
    color("lightsteelblue") translate([0, e, 0]) mast_piece(mast_y0, mast_y0 + 25, false, true);
    color("lightgreen") translate([0, 2 * e, e]) mast_piece(mast_y0 + 25, mast_y0 + 40, true, false);
    color("orange") translate([0, e, 2 * e]) mast_strip(mast_y0, mast_y0 + 25);
  }
}

// ESP32 / Porcupine board test: the bottom strip of the head body
module esp_test() intersection() {
  head_body();
  box([-1, -1, -1], [head_w + 1, lcd_y0 - 1, head_top + 1]);
}

if (PART == "assembly") assembly();
else if (PART == "assembly_open") assembly(covers = false);
else if (PART == "exploded") assembly(e = EXPLODE == 0 ? 30 : EXPLODE);
else if (PART == "bar_left") print_bar_body(0);
else if (PART == "bar_center") print_bar_body(1);
else if (PART == "bar_right") print_bar_body(2);
else if (PART == "bar_cover_left") print_bar_cover(0);
else if (PART == "bar_cover_center") print_bar_cover(1);
else if (PART == "bar_cover_right") print_bar_cover(2);
else if (PART == "mast_lower") translate([0, -mast_y0, 0]) mast_piece(mast_y0, mast_ys, false, true);
else if (PART == "mast_upper") translate([0, -mast_ys + mast_dt[2], 0]) mast_piece(mast_ys, mast_y1, true, false);
else if (PART == "mast_strip_lower") face_down(mast_d) translate([0, -mast_y0, 0]) mast_strip(mast_y0, strip_ys);
else if (PART == "mast_strip_upper") face_down(mast_d) translate([0, -strip_ys, 0]) mast_strip(strip_ys, mast_y1);
else if (PART == "head") translate([0, cheek_h, 0]) head_body();
else if (PART == "head_cover") face_down(head_d) head_cover();
else if (PART == "sensor_test") sensor_test();
else if (PART == "esp_test") esp_test();
else if (PART == "joint_test") joint_test();
else if (PART == "joint_test_view") joint_test_view();
else echo(str("Unknown PART: ", PART));
