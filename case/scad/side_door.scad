// Side box back door (SolidWorks part 004). Slides into the grooves on the
// back of a side box. Same stepped profile as the display door: the wide flange
// rides in the grooves and the narrow lip fills the opening flush with the back.
// A full-thickness tab sticks out of the inner end (toward the center body).
// The same part is used for both side boxes (the right one is rotated 180°).
// Frame: X = length, Y = depth (0 = inside face, toward the front), Z = height.

side_door_l = 163.1;          // length without the tab
side_door_h = 91.4;           // flange height (rides in the grooves)
side_door_flange_t = 2.0;     // flange thickness
side_door_lip_t = 2.2;        // lip thickness (flush with the back)
side_door_lip_inset = 3.0;    // lip is shorter than the flange by this much at top and bottom
side_door_tab_l = 11.8;       // tab length past the end of the door
side_door_tab_z = 30.8;       // tab bottom edge
side_door_tab_h = 29.8;       // tab height

module side_door() {
  // Flange
  cube([side_door_l, side_door_flange_t, side_door_h]);
  // Lip
  translate([0, 0, side_door_lip_inset])
    cube([side_door_l, side_door_flange_t + side_door_lip_t, side_door_h - 2 * side_door_lip_inset]);
  // Tab
  translate([side_door_l, 0, side_door_tab_z])
    cube([side_door_tab_l, side_door_flange_t + side_door_lip_t, side_door_tab_h]);
}

side_door();
