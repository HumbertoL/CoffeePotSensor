// Display box (SolidWorks part 003). Sits on top of the center body and holds the
// Waveshare 2" ST7789 LCD (seen through the front window) plus the microcontroller.
// The back door (display_door.scad) slides down into the grooves from the top.
// Frame: X = width (left->right seen from the front), Y = depth (0 = front face with
// the screen window, 27 = back / wall side), Z = height (0 = bottom of the tabs).

// --- overall shell ---
display_w = 101.6;          // outer width
display_d = 27.0;           // outer depth
display_body_z = 4.2;       // bottom of the box body (the tabs hang below this)
display_h = 80.4;           // overall height including the tabs
display_outer_r = 5.0;      // round on the front vertical edges and the top edges
display_wall = 2.0;         // front / side / top / floor wall thickness

// --- main cavity (LCD + MCU) ---
display_cav_back = 20.8;    // cavity depth ends here (front face of the groove ribs)
display_cav_r = 3.0;        // corner radius of the cavity seen from the back (XZ)
display_cav_front_r = 2.0;  // round where the cavity meets the inside of the front wall

// --- back door grooves ---
display_rib_w = 6.0;        // ribs in front of the groove (x 2..8 and 93.6..99.6)
display_groove_y = 22.8;    // groove front face
display_groove_t = 2.2;     // groove depth in Y (door flange is 2.0)
display_slot_inset = 5.0;   // groove / flange slot spans x 5..96.6
display_opening_inset = 8.0; // back opening for the door lip: x 8..93.6, full height

// --- screen window ---
display_win_w = 50.0;       // window width at the inside face of the front wall
display_win_h = 35.0;       // window height at the inside face
display_win_z = 24.8;       // window bottom (inside face)
display_win_r = 2.0;        // full round on the front edge of the window (= wall)

// --- wire pass-through in the floor ---
display_wire_x = 35.8;      // left edge (right edge = 65.8, centered)
display_wire_w = 30.0;
display_wire_y = 4.0;       // front edge; runs back into the door opening
display_wire_r = 2.0;       // front corner radius

// --- bottom tabs (L-shaped hooks into the center body) ---
display_tab_x = 29.0;       // left tab outer edge (right tab mirrored about center)
display_tab_y = 9.0;
display_tab_len = 16.0;     // Y extent (9..25)
display_tab_foot_w = 7.0;   // foot width, pointing toward the center
display_tab_foot_t = 2.0;   // foot thickness (z 0..2)
display_tab_stem_w = 2.0;   // stem width (z 2..4.2)

display_eps = 0.01;

// Outer shell: box with R5 on the two front vertical edges and on the three top
// edges (front, left, right); back and bottom edges are sharp.
module display_outer() {
  r = display_outer_r; top = display_h - r;
  hull() {
    for (x = [r, display_w - r]) {
      translate([x, r, top]) sphere(r);                                       // top-front corners
      translate([x, r, display_body_z]) cylinder(r = r, h = top - display_body_z); // front vertical edges
      translate([x, r, top]) rotate([-90, 0, 0]) cylinder(r = r, h = display_d - r); // top side edges
    }
    translate([0, r, display_body_z]) cube([display_w, display_d - r, display_eps]);
  }
}

// Main cavity: rounded rectangle (R3) in XZ, with an R2 round where it meets the
// inside of the front wall (torus at each corner).
module display_cavity() {
  R = display_cav_r; fr = display_cav_front_r; w = display_wall;
  z0 = display_body_z + w; z1 = display_h - w;
  y0 = w + fr;
  hull() for (x = [w + R, display_w - w - R], z = [z0 + R, z1 - R]) {
    translate([x, y0, z]) rotate([-90, 0, 0]) {
      rotate_extrude() intersection() { translate([R - fr, 0]) circle(fr); translate([0, -fr]) square([R, 2 * fr]); }
      cylinder(r = R, h = display_cav_back - y0);
    }
  }
}

// Door groove: straight slot x 5..96.6 from the cavity floor up through the top
// (the door flange slides down into it), plus the gap between the two ribs.
module display_door_track() {
  w = display_wall;
  z0 = display_body_z + w; z1 = display_h - w;
  // gap between the ribs, joining cavity and groove
  translate([display_opening_inset, display_cav_back - display_eps, z0])
    cube([display_w - 2 * display_opening_inset, display_groove_y - display_cav_back + 2 * display_eps, z1 - z0]);
  // groove for the door flange, open at the top
  translate([display_slot_inset, display_groove_y, z0])
    cube([display_w - 2 * display_slot_inset, display_groove_t, display_h]);
  // back opening for the door lip (full height, through the floor and top)
  translate([display_opening_inset, display_groove_y + display_groove_t - display_eps, display_body_z - 1])
    cube([display_w - 2 * display_opening_inset, display_d, display_h]);
}

// Screen window: 50 x 35 at the inside face, front edge fully rounded (R2), built
// as a stack of frusta following the quarter-round profile.
module display_window() {
  n = 9; r = display_win_r; // 10 degree steps, like the other rounds
  cx = display_w / 2; cz = display_win_z + display_win_h / 2;
  // point on the quarter round at angle a: depth y = r(1-cos a), flare e = r(1-sin a)
  module layer(a) let(y = r * (1 - cos(a)), e = r * (1 - sin(a)))
    translate([cx - display_win_w / 2 - e, y, cz - display_win_h / 2 - e])
      cube([display_win_w + 2 * e, display_eps, display_win_h + 2 * e]);
  for (i = [0 : n - 1]) hull() { layer(90 * i / n); layer(90 * (i + 1) / n); }
  translate([cx - display_win_w / 2, -display_eps, display_win_z]) cube([display_win_w, display_wall + 1, display_win_h]);
  translate([cx - display_win_w / 2 - r, -1, cz - display_win_h / 2 - r]) cube([display_win_w + 2 * r, 1 + display_eps, display_win_h + 2 * r]);
}

// Wire pass-through: slot in the floor, R2 at the front corners, open to the back.
module display_wire_pass() {
  r = display_wire_r;
  translate([0, 0, display_body_z - 1]) linear_extrude(display_wall + 2)
    hull() {
      for (x = [display_wire_x + r, display_wire_x + display_wire_w - r])
        translate([x, display_wire_y + r]) circle(r);
      translate([display_wire_x, display_groove_y]) square([display_wire_w, display_d - display_groove_y]);
    }
}

// Bottom tab: L-shaped hook, stem on the outside, foot pointing toward the center.
module display_tab() {
  translate([display_tab_x, display_tab_y, 0]) {
    cube([display_tab_foot_w, display_tab_len, display_tab_foot_t]);
    cube([display_tab_stem_w, display_tab_len, display_body_z + display_eps]);
  }
}

module display_box() {
  $fn = 36; // the original mesh uses 10 degree facets on every round
  difference() {
    display_outer();
    display_cavity();
    display_door_track();
    display_window();
    display_wire_pass();
  }
  display_tab();
  translate([display_w, 0, 0]) mirror([1, 0, 0]) display_tab();
}

display_box();
