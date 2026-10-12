#!/usr/bin/env python3
"""overhang.py STL... - report downward-facing surfaces above the bed (they would need supports).

Faces steeper than ~41 degrees from vertical that face down and sit above the part's
lowest point are flagged. Export each print part in its print orientation first, e.g.
  openscad -D 'PART="bar_center"' -o bar_center.stl case/v2/coffee_case_v2.scad
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from stlinfo_lib import load

for p in sys.argv[1:]:
    tris = load(p)
    zmin = min(min(t[2], t[5], t[8]) for t in tris)
    area = 0
    faces = []
    for t in tris:
        a, b, c = t[0:3], t[3:6], t[6:9]
        u = [b[i] - a[i] for i in range(3)]
        v = [c[i] - a[i] for i in range(3)]
        n = [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]]
        L = math.sqrt(sum(x * x for x in n)) or 1
        zlow = min(a[2], b[2], c[2])
        if n[2] / L < -0.75 and zlow > zmin + 0.05:
            A = L / 2
            area += A
            faces.append((A, zlow, (round((a[0] + b[0] + c[0]) / 3, 1), round((a[1] + b[1] + c[1]) / 3, 1))))
    name = os.path.basename(p)
    if area < 0.5:
        print(f"{name:24s} OK (no overhangs)")
    else:
        faces.sort(reverse=True)
        A, z, xy = faces[0]
        print(f"{name:24s} overhang area {area:7.1f} mm2; largest at z={z:.1f} xy={xy} ({A:.1f} mm2)")
