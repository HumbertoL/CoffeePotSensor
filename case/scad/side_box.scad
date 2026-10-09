// Side box (SolidWorks part 001), left/original copy. Holds one IR proximity
// sensor that reads through the window in the front face. The back door slides
// in from the open left end along the top/bottom grooves; the right end joins
// the center body with two dovetail tabs and a wire notch.
// Frame: X = width (left->right seen from the front), Y = depth (0 = front,
// facing the coffee pots; 27 = back/wall side), Z = height.

side_w = 165.1;          // box width (without joint tabs)
side_d = 27.0;           // box depth
side_h = 101.6;          // box height
side_r = 5.0;            // outer fillet on the front edges and the left end edges
side_wall = 2.0;         // wall thickness (front, top, bottom, left, right)
side_in_r_front = 2.0;   // inner fillet where the cavity meets the front wall
side_in_r_corner = 3.0;  // inner fillet on the cavity's X-Z corners (edges along Y)
side_fn = 36;            // facets per circle (the STL uses 36, i.e. 10 deg steps)

// Back: rail, door groove, lip (same at bottom and top, mirrored)
side_rail_y = 20.8;      // inner face of the rail (= back end of the rounded cavity)
side_rail_t = 2.0;       // rail thickness (Y)
side_rail_h = 8.0;       // rail/lip height from the outer bottom (top/bottom face)
side_groove_t = 2.2;     // door groove width (Y), 22.8..25
side_groove_h = 5.0;     // groove floor height from the outer bottom (3 deep into the 8 high rail)
side_lip_y = 25.0;       // back lip starts here (25..27); right wall also stops here

// Sensor window (front face, sharp rectangle straight through)
side_win_x = 10.2;
side_win_z = 6.0;
side_win_w = 5.0;
side_win_h = 15.0;

// Wire hole (left end wall, rounded rectangle)
side_wire_y = 5.8;
side_wire_z = 38.0;      // was 37.28 in SolidWorks; rounded to 1 mm, about centered (hole 38..63, box mid-height 50.8)
side_wire_w = 15.0;      // along Y (5.8..20.8)
side_wire_h = 25.0;      // along Z
side_wire_r = 2.0;

// Right-end notch (pass-through to the center body, open at the back)
side_notch_y = 10.0;     // notch runs from here to the back of the right wall
side_notch_z = 35.8;
side_notch_h = 30.0;
side_notch_r = 2.0;      // fillet on the two front corners

// Joint tabs (dovetail-like arrows on the right end, full depth 0..25)
side_tab_z = [20.0, 71.6]; // bottom of each tab's root
side_tab_root = 10.0;      // root height at the box face
side_tab_neck = 2.0;       // straight neck length before the flare
side_tab_flare = 3.0;      // flare: 45 deg out by 3 then 45 deg back in by 3
side_tab_len = 8.0;        // total tab length (165.1 -> 173.1)
side_tab_d = 25.0;         // tab depth (Y)

// Outer shell: R5 on the front edges and the left-end edges, square at right/back
module side_outer() {
  r = side_r;
  hull() {
    for (z = [r, side_h - r]) {
      translate([r, r, z]) sphere(r);
      translate([r, r, z]) rotate([0, 90, 0]) cylinder(r = r, h = side_w - r);   // front edges along X
      translate([r, r, z]) rotate([-90, 0, 0]) cylinder(r = r, h = side_d - r);  // left edges along Y
    }
    translate([r, r, 0]) cube([side_w - r, side_d - r, side_h]);
  }
}

// Main cavity: R2 where it meets the front wall, R3 on the X-Z corners.
// Hull of four corner pieces: a half torus (front R2 fillet swept around the
// R3 corner) plus an R3 cylinder running back to the rails.
module side_cavity() {
  rf = side_in_r_front;
  rc = side_in_r_corner - rf;
  x0 = side_wall + side_in_r_corner;
  z0 = side_wall + side_in_r_corner;
  hull()
    for (cx = [x0, side_w - x0], cz = [z0, side_h - z0])
      translate([cx, side_wall + rf, cz]) rotate([-90, 0, 0]) {
        rotate_extrude()
          intersection() {
            translate([rc, 0]) circle(rf);
            translate([0, -rf]) square([rc + rf, rf]);
          }
        cylinder(r = side_in_r_corner, h = side_rail_y - side_wall - rf);
      }
}

module side_box() {
  $fn = side_fn;
  e = 0.01;
  difference() {
    union() {
      side_outer();
      // Joint tabs
      for (z0 = side_tab_z)
        translate([0, side_tab_d, 0]) rotate([90, 0, 0])
          linear_extrude(side_tab_d)
            polygon([
              [side_w - e, z0],
              [side_w + side_tab_neck, z0],
              [side_w + side_tab_neck + side_tab_flare, z0 - side_tab_flare],
              [side_w + side_tab_len, z0],
              [side_w + side_tab_len, z0 + side_tab_root],
              [side_w + side_tab_neck + side_tab_flare, z0 + side_tab_root + side_tab_flare],
              [side_w + side_tab_neck, z0 + side_tab_root],
              [side_w - e, z0 + side_tab_root]]);
    }
    // Rounded cavity (front part, up to the rails)
    side_cavity();
    // Between the rails (behind the cavity)
    translate([side_wall, side_rail_y - e, side_rail_h])
      cube([side_w - 2 * side_wall, side_rail_t + 2 * e, side_h - 2 * side_rail_h]);
    // Door grooves + slot, open through the left end
    translate([-1, side_rail_y + side_rail_t, side_groove_h])
      cube([side_w - side_wall + 1, side_groove_t + e, side_h - 2 * side_groove_h]);
    // Behind the grooves: open between the lips, right wall stops at Y=25
    translate([-1, side_lip_y, side_rail_h])
      cube([side_w + 2, side_d, side_h - 2 * side_rail_h]);
    // Sensor window
    translate([side_win_x, -1, side_win_z]) cube([side_win_w, side_wall + 2, side_win_h]);
    // Wire hole in the left end wall
    translate([-1, 0, 0]) rotate([90, 0, 90]) linear_extrude(side_wall + 2)
      translate([side_wire_y, side_wire_z])
        offset(r = side_wire_r) offset(delta = -side_wire_r) square([side_wire_w, side_wire_h]);
    // Notch in the right end wall (rounded front corners, open at the back)
    translate([side_w - side_wall - 1, 0, 0]) rotate([90, 0, 90]) linear_extrude(side_wall + 2)
      translate([side_notch_y, side_notch_z]) hull() {
        translate([side_notch_r, side_notch_r]) circle(side_notch_r);
        translate([side_notch_r, side_notch_h - side_notch_r]) circle(side_notch_r);
        translate([side_notch_r, 0]) square([side_d, side_notch_h]);
      }
  }
}

side_box();
