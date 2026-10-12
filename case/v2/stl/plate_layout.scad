// Every v2 print part on a Prusa MK4S bed (250 x 210 mm), 3 mm apart.
// For checking the layout only; in PrusaSlicer, add the STLs and press A (Arrange).
module at(t, m) translate([t[0] - m[0], t[1] - m[1], 0]) children();
color("#3a3a3a") translate([0, 0, -0.6]) cube([250, 210, 0.5]);
color("whitesmoke") {
  at([0, 0],       [0, 0])        import("bar_left.stl");
  at([124.6, 0],   [0, 0])        import("bar_right.stl");
  at([0, 48.8],    [-6, 0])       import("bar_center.stl");
  at([0, 128.6],   [0, 0])        import("head.stl");
  at([189, 48.8],  [-8, 0])       import("mast_lower.stl");
  at([208, 48.8],  [-8, 0])       import("mast_upper.stl");
}
color("lightsteelblue") {
  at([0, 24.4],    [0, -21.4])    import("bar_cover_left.stl");
  at([124.6, 24.4],[0, -21.4])    import("bar_cover_right.stl");
  at([0, 85.2],    [0, -21.4])    import("bar_cover_center.stl");
  at([66.4, 128.6],[0, -60.7])    import("head_cover.stl");
  at([0, 109.6],   [0, -8])       rotate([0, 0, 90]) import("mast_strip_lower.stl");
  at([227, 48.8],  [-8, -110.8])  import("mast_strip_upper.stl");
}
