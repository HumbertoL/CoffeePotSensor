// Center body back door (SolidWorks part 007; replaces the older part 006).
// Same stepped profile as the other doors, slid in from the top. The top
// corners are rounded and two notches in the top edge leave room for wires
// going up into the display box.
// Frame: X = width, Y = depth (0 = inside face, toward the front), Z = height.

center_door_w = 81.4;          // flange width (rides in the grooves)
center_door_h = 99.6;
center_door_flange_t = 2.0;    // flange thickness
center_door_lip_t = 2.2;       // lip thickness (flush with the back)
center_door_lip_inset = 5.2;   // lip is narrower than the flange by this much on each side
center_door_corner_r = 2.0;    // radius of the rounded top corners
center_door_notch_x = 18.4;    // notch distance from each side
center_door_notch_w = 10.3;
center_door_notch_d = 3.0;     // notch depth down from the top edge

// Plate with its top two corners rounded (drawn in the XZ plane, extruded along +Y)
module center_door_plate(w, t, h, r) {
  rotate([90, 0, 0]) mirror([0, 0, 1]) linear_extrude(t)
    hull() {
      square([w, h - r]);
      for (x = [r, w - r]) translate([x, h - r]) circle(r = r);
    }
}

module center_door() {
  $fn = 48;  // set here, not at file level: a top-level $fn doesn't apply when this file is use<>d
  difference() {
    union() {
      center_door_plate(center_door_w, center_door_flange_t, center_door_h, center_door_corner_r);
      translate([center_door_lip_inset, 0, 0])
        center_door_plate(center_door_w - 2 * center_door_lip_inset, center_door_flange_t + center_door_lip_t,
                          center_door_h, center_door_corner_r);
    }
    // Wire notches in the top edge (symmetric)
    for (x = [center_door_notch_x, center_door_w - center_door_notch_x - center_door_notch_w])
      translate([x, -1, center_door_h - center_door_notch_d])
        cube([center_door_notch_w, center_door_flange_t + center_door_lip_t + 2, center_door_notch_d + 1]);
  }
}

center_door();
