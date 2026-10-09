# Case

The current case is wall-mounted behind the coffee pots. It is about 44 cm wide, 2.7 cm deep and 18 cm tall at the display. It was designed in SolidWorks, and those files remain the original design:
- `coffee timer.SLDASM`: the assembly.
- `coffee timer-00N.SLDPRT`: the individual parts.

[`scad/`](scad) is an OpenSCAD conversion of the same design. It reproduces the SolidWorks parts as they are, without redesigning anything. It was reverse-engineered from the STL exports and checked against them; see Accuracy below.

The conversion makes two deliberate changes, listed under Changes from the SolidWorks design.

STL files are git-ignored. Export them from SolidWorks or OpenSCAD when you need them.

## Parts

| OpenSCAD file | SolidWorks part | Qty | What it is |
|---|---|---|---|
| `side_box.scad` | 001 (+ `Mirrorcoffee timer-001`) | 2 | End module. It holds one sensor behind a 5 × 15 mm front window and has a wire hole in its outer end. Two arrow-shaped tabs on its inner end lock into the center body. The right box is a mirror image of the left. |
| `center_body.scad` | 002 | 1 | Middle module. It holds one sensor behind a 5 × 15 mm front window. Notches on each end receive the side box tabs. Side windows pass wires to the side boxes, and a 30 × 16 mm top hole passes them up to the display box. |
| `display_box.scad` | 003 | 1 | Sits on top of the center body, held by two L-shaped hooks on its bottom. It holds the LCD (50 × 35 mm window) and the microcontroller. |
| `side_door.scad` | 004 | 2 | Back door of a side box. It slides in from the outer end. The right door is the same part rotated 180°. |
| `center_door.scad` | 007 | 1 | Back door of the center body. It slides up from the bottom. Two notches in its top edge let wires pass. (Part 006 is an older version that is no longer used.) |
| `display_door.scad` | 005 | 1 | Back door of the display box. |
| `assembly.scad` | `coffee timer.SLDASM` | — | All parts in their assembly positions. Set `show_doors` and `explode` to show or hide the doors and pull the parts apart. |

All the doors share the same stepped profile:
- a 2.0 mm flange that rides in grooves,
- plus a 2.2 mm lip, inset 3–5.2 mm per side, that fills the opening flush with the back.

**Coordinates (mm):**
- X runs left → right as seen from the front.
- Y is depth: 0 is the front face toward the pots, 27 is the wall side.
- Z is up.
- Each part file uses this orientation with its own bounding-box corner at the origin, and renders on its own when opened. `assembly.scad` uses the SolidWorks assembly coordinates.

**Exporting a part for printing:**

```bash
openscad -o side_box.stl case/scad/side_box.scad
```

The parts are modeled in their assembled orientation, not in a print orientation.

## Accuracy

Each part was compared with the STL exported from the SolidWorks assembly (`case/coffee timer - coffee timer-*.STL`) by measuring the volume of the difference in both directions.

| Part | Original − model | Model − original |
|---|---|---|
| side box (left and mirrored) | 0.06 %† | 0.06 %† |
| center body | 0.03 % | 0.02 % |
| display box | 0.34 % | 0.85 %* |
| side door ×2, display door, center door | 0.00 % | 0.00 % |
| **whole assembly** | **0.05 %** | **0.10 %** |

†This includes the wire hole moved 0.72 mm (see below). Before that change the side box matched at 0.03 %.

The leftovers come from how curves are broken into flat facets: SolidWorks used 10° steps and the models use `$fn = 36` to match.

\*The display box mesh has zero-thickness internal faces at both ends of its door groove. OpenSCAD drops 159 mm³ from the original as soon as it does any boolean operation on it, which is what produces this number. The model's own volume matches the original mesh within 2 mm³. Those faces look like left over from an earlier, wider, rounded groove. The model uses the 91.6 mm groove that fits the 91.4 mm door. It's worth checking against SolidWorks.

### Tools

[`tools/`](tools) contains the Python scripts used for the conversion. They need only Python 3 and the `openscad` command line. Use them to re-check a model after the SolidWorks design changes.
- `compare.py STL SCADFILE "module()"`: reports the volume difference in each direction, as in the table above.
- `slice.py STL x|y|z POS --local`: cuts a mesh at a plane and prints exact outline coordinates. This is how dimensions were measured.

## Changes from the SolidWorks design

- **Left side door position:** the door is now fully inserted at X 9.64, the mirror of the right door. In the SolidWorks assembly it sat 7.41 mm further out (X 2.23) and stuck out past the end of the box. This only changes `assembly.scad`; the door part itself is unchanged.
- **Side box wire hole:** it was at Z 37.28–62.28, centered 1.02 mm below the box's mid-height. It's now at Z 38–63, rounded to whole millimeters and within 0.3 mm of centered.

## Quirks in the original design (kept as-is)

- **Joint tabs:** they are already symmetric, 18.1 mm from the top and bottom of the box (Z 18.1–31.9 and 69.7–83.5). They stop at Y 25 rather than reaching the back face.
- **Center body side windows:** they cut through the door grooves between Z 35.8 and 65.8, so the center door is only held at its top and bottom.
- **Center body walls:** its side walls are solid 10 mm plastic, and the notch back face leaves only 1.8 mm of wall to the cavity.
- **Display box:** it has no posts, ledges or clips to hold the LCD or the board. The window is sized to the 35 mm height of the LCD module rather than to its 30.6 mm active area.
