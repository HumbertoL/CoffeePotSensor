// brew-em-all case: all parts positioned as in the SolidWorks assembly
// (coffee timer.SLDASM). Coordinates are the assembly's own, in mm.
// X = left→right seen from the front, Y = depth (0 = front face toward the
// pots, 27 = back against the wall), Z = up.
//
// Open a single part file to see or export just that part.

use <side_box.scad>
use <center_body.scad>
use <display_box.scad>
use <side_door.scad>
use <display_door.scad>
use <center_door.scad>

show_doors = true;  // the back doors that slide into each module
explode = 0;        // > 0 pulls the modules and doors apart, e.g. 30

side_l = 173.10;    // side box length (X)
side_door_l = 174.90;
side_door_h = 91.40;

module assembly(show_doors = show_doors, explode = explode) {
  // Side box (left) and its mirror image (right)
  color("tan") translate([9.40 - explode, 0, 0.51]) side_box();
  color("tan") translate([268.10 + side_l + explode, 0, 0.51]) mirror([1, 0, 0]) side_box();

  // Center body, with the display box on top
  color("lightblue") translate([174.50, 0, 0.51]) center_body();
  color("lightgreen") translate([174.50, 0, 97.91 + explode]) display_box();

  if (show_doors) {
    // Left side door, fully inserted (mirror of the right door's position). The
    // SolidWorks assembly had it 7.41 mm further out (X 2.23), sticking out past the end.
    color("salmon") translate([9.64 - explode, 22.80 + explode, 5.61]) side_door();
    // Right side door: the same part rotated 180° so its tab points at the center
    color("salmon") translate([266.06 + side_door_l + explode, 22.80 + explode, 5.61 + side_door_h])
      rotate([0, 180, 0]) side_door();
    color("orange") translate([179.60, 22.80 + explode, 102.80 + explode]) display_door();
    color("orchid") translate([184.60, 22.75 + explode, 1.21]) center_door();
  }
}

assembly();
