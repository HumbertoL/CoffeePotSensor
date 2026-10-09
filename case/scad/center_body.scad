// Center body (SolidWorks part 002). Middle module of the coffee-pot timer:
// holds one IR proximity sensor behind a window in the front face, passes
// wires up into the display box through the top, joins a side box at each
// end with dovetail-like notches, and takes a back door that slides up from
// the bottom into grooves at the back.
// Frame: X = width (left->right seen from the front), Y = depth (0 = front
// face toward the pots, 27 = back/wall side), Z = height.

// --- Overall block ---
center_w = 101.6;              // width (X)
center_d = 27.0;               // depth (Y)
center_h = 101.6;              // height (Z)
center_front_edge_r = 5.0;     // outer fillet along the front-bottom edge

// --- Inner cavity (open at the back) ---
center_side_wall = 10.0;       // solid side walls (X 0..10 and 91.6..101.6)
center_front_wall = 2.0;       // front wall thickness
center_floor = 2.0;            // floor thickness
center_roof = 2.0;             // top plate thickness
center_cavity_back = 25.0;     // cavity reaches Y=25 (back lip behind it)
center_cavity_corner_r = 2.0;  // vertical front corners of the cavity
center_cavity_side_r = 3.0;    // fillet floor/roof <-> side walls
center_cavity_front_r = 2.0;   // fillet floor/roof <-> front wall

// --- Back door: grooves + retaining lip (door slides up from the bottom) ---
center_rib_y = 20.75;          // front face of the ribs in front of the door
center_rib_t = 2.0;            // rib thickness (Y)
center_rib_w = 3.0;            // rib width out from each side wall (X)
center_door_slot_y = 22.75;    // door slot Y 22.75..25 (2.25 thick)
center_door_slot_top = 35.8;   // slot cut straight up from the bottom to here (side window above)
center_lip_t = 2.0;            // back lip thickness (Y 25..27)
center_lip_w = 5.0;            // back lip width over each side wall edge (opening X 15..86.6)
center_lip_open_r = 2.0;       // top corners of the back opening

// --- IR sensor window in the front face ---
center_sensor_w = 5.0;         // X width, centered
center_sensor_z0 = 6.0;        // bottom
center_sensor_z1 = 21.0;       // top

// --- Side windows (wires to the side boxes), cut through the full width ---
center_side_win_y = 8.0;       // starts behind the front, open to the back
center_side_win_z0 = 35.8;
center_side_win_z1 = 65.8;
center_side_win_r = 2.0;       // front corners

// --- Joint notches (dovetail-like), same profile at both ends, full depth ---
center_notch_zc = [25.0, 76.6];  // notch centers
center_notch_mouth = 10.4;     // opening height at the end face
center_notch_neck_x = 1.92;    // mouth stays straight this far in
center_notch_mid_x = 5.0;      // widest point of the undercut
center_notch_mid_h = 16.56;    // height at the widest point
center_notch_depth = 8.2;      // depth into the side wall
center_notch_back_h = 10.16;   // height of the flat back face

// --- Top: display-box interface ---
center_wire_hole = [30.0, 16.0]; // wire pass-through X x Y, centered in X
center_wire_hole_y = 4.0;        // front edge of the wire hole
center_wire_hole_r = 2.0;        // corner radius
center_top_groove_w = 2.3;       // two grooves through the top plate
center_top_groove_xc = 30.0;     // left groove center (right one mirrored)
center_top_groove_y = 7.0;       // grooves run from here to the back
center_top_recess_d = 2.0;       // top plate removed at the back between the grooves (Y 25..27)

e = 0.01;

module center_rounded_rect(x0, y0, x1, y1, r) {
  // 2D rectangle with all corners rounded
  translate([x0 + r, y0 + r]) offset(r = r) square([x1 - x0 - 2 * r, y1 - y0 - 2 * r]);
}

// One notch profile in (X,Z) at the left end, extruded through the full depth
module center_notch(zc) {
  m = center_notch_mouth / 2;
  w = center_notch_mid_h / 2;
  b = center_notch_back_h / 2;
  translate([0, center_d + 1, 0]) rotate([90, 0, 0])
    linear_extrude(center_d + 2)
      polygon([[-1, zc - m], [center_notch_neck_x, zc - m], [center_notch_mid_x, zc - w],
               [center_notch_depth, zc - b], [center_notch_depth, zc + b],
               [center_notch_mid_x, zc + w], [center_notch_neck_x, zc + m], [-1, zc + m]]);
}

module center_cavity() {
  x0 = center_side_wall; x1 = center_w - center_side_wall;
  y0 = center_front_wall; y1 = center_cavity_back;
  z0 = center_floor; z1 = center_h - center_roof;
  intersection() {
    // plan view: rounded front corners
    linear_extrude(center_h)
      hull() {
        center_rounded_rect(x0, y0, x1, y0 + 2 * center_cavity_corner_r + 1, center_cavity_corner_r);
        translate([x0, y1 - 1]) square([x1 - x0, 1]);
      }
    // front view: side fillets R3 at floor and roof
    translate([0, y1, 0]) rotate([90, 0, 0]) linear_extrude(y1)
      center_rounded_rect(x0, z0, x1, z1, center_cavity_side_r);
    // side view: front fillets R2 at floor and roof
    rotate([90, 0, 90]) linear_extrude(center_w)
      hull() {
        center_rounded_rect(y0, z0, y0 + 2 * center_cavity_front_r + 1, z1, center_cavity_front_r);
        translate([y1 - 1, z0]) square([1, z1 - z0]);
      }
  }
}

module center_body() {
  $fn = 64;
  difference() {
    union() {
      difference() {
        // shell with rounded front-bottom edge
        rotate([90, 0, 90]) linear_extrude(center_w)
          hull() {
            translate([center_front_edge_r, center_front_edge_r]) circle(r = center_front_edge_r);
            translate([0, center_front_edge_r]) square([center_d, center_h - center_front_edge_r]);
            translate([center_front_edge_r, 0]) square([center_d - center_front_edge_r, center_h]);
          }
        center_cavity();
      }
      // ribs in front of the door (one per side)
      for (mx = [0, 1]) translate([mx * center_w, 0, 0]) mirror([mx, 0, 0])
        translate([center_side_wall, center_rib_y, 0]) cube([center_rib_w, center_rib_t, center_h]);
    }

    // door slot: through the floor and straight up to the side windows
    translate([center_side_wall, center_door_slot_y, -1])
      cube([center_w - 2 * center_side_wall, center_cavity_back - center_door_slot_y + e, center_door_slot_top + 1]);

    // back opening between the retaining lips, rounded top corners
    lx0 = center_side_wall + center_lip_w; lx1 = center_w - center_side_wall - center_lip_w;
    translate([0, center_d + 1, 0]) rotate([90, 0, 0]) linear_extrude(center_lip_t + 1 + e)
      hull() {
        translate([lx0, -1]) square([lx1 - lx0, 1]);
        translate([lx0 + center_lip_open_r, center_h - center_roof - center_lip_open_r]) circle(r = center_lip_open_r);
        translate([lx1 - center_lip_open_r, center_h - center_roof - center_lip_open_r]) circle(r = center_lip_open_r);
      }

    // IR sensor window in the front wall
    translate([(center_w - center_sensor_w) / 2, -1, center_sensor_z0])
      cube([center_sensor_w, center_front_wall + 2, center_sensor_z1 - center_sensor_z0]);

    // side windows, through the full width, open to the back
    rotate([90, 0, 90]) translate([0, 0, -1]) linear_extrude(center_w + 2)
      hull() {
        translate([center_side_win_y + center_side_win_r, center_side_win_z0 + center_side_win_r]) circle(r = center_side_win_r);
        translate([center_side_win_y + center_side_win_r, center_side_win_z1 - center_side_win_r]) circle(r = center_side_win_r);
        translate([center_d - 1, center_side_win_z0]) square([2, center_side_win_z1 - center_side_win_z0]);
      }

    // joint notches, left end modeled, right end mirrored
    for (mx = [0, 1]) translate([mx * center_w, 0, 0]) mirror([mx, 0, 0])
      for (zc = center_notch_zc) center_notch(zc);

    // wire pass-through into the display box
    translate([0, 0, center_h - center_roof - 1]) linear_extrude(center_roof + 2)
      center_rounded_rect((center_w - center_wire_hole[0]) / 2, center_wire_hole_y,
                          (center_w + center_wire_hole[0]) / 2, center_wire_hole_y + center_wire_hole[1],
                          center_wire_hole_r);

    // display-box grooves through the top plate (mirrored pair)
    for (mx = [0, 1]) translate([mx * center_w, 0, 0]) mirror([mx, 0, 0])
      translate([center_top_groove_xc - center_top_groove_w / 2, center_top_groove_y, center_h - center_roof - 1])
        cube([center_top_groove_w, center_d - center_top_groove_y + 1, center_roof + 2]);

    // top plate removed at the back between the grooves
    translate([center_top_groove_xc - center_top_groove_w / 2, center_d - center_top_recess_d, center_h - center_roof - 1])
      cube([center_w - 2 * center_top_groove_xc + center_top_groove_w, center_top_recess_d + 1, center_roof + 2]);
  }
}

center_body();
