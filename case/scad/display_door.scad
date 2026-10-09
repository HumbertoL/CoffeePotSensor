// Display box back door (SolidWorks part 005). Slides into the grooves on the
// back of the display box: the wide flange rides in the grooves, the narrow
// lip fills the opening flush with the back of the box.
// Frame: X = width, Y = depth (0 = inside face, toward the front), Z = height.

display_door_w = 91.4;       // flange width (rides in the grooves)
display_door_h = 74.2;
display_door_flange_t = 2.0; // flange thickness
display_door_lip_t = 2.2;    // lip thickness (flush with the back)
display_door_lip_inset = 3.0; // lip is narrower than the flange by this much on each side

module display_door() {
  cube([display_door_w, display_door_flange_t, display_door_h]);
  translate([display_door_lip_inset, 0, 0])
    cube([display_door_w - 2 * display_door_lip_inset, display_door_flange_t + display_door_lip_t, display_door_h]);
}

display_door();
