#!/usr/bin/env python3
"""slice.py STL AXIS POS [--local]
Cut the mesh with the plane AXIS=POS and print the outline polygons.
AXIS is x, y or z. The plane's 2D coordinates are: z-cut->(x,y), y-cut->(x,z), x-cut->(y,z).
With --local, the mesh is first translated so its bounding-box min is at the origin."""
import re, subprocess, sys, tempfile, os
sys.path.insert(0, os.path.dirname(__file__))
from stlinfo_lib import bbox
stl, axis, pos = sys.argv[1], sys.argv[2], float(sys.argv[3])
local = '--local' in sys.argv
mn = bbox(stl)[0] if local else (0, 0, 0)
# remap axes so the requested axis becomes Z, then cut at z=0
mats = {
  'z': '[[1,0,0,0],[0,1,0,0],[0,0,1,0]]',   # (x,y,z)->(x,y,z)
  'y': '[[1,0,0,0],[0,0,1,0],[0,1,0,0]]',   # (x,y,z)->(x,z,y)
  'x': '[[0,1,0,0],[0,0,1,0],[1,0,0,0]]',   # (x,y,z)->(y,z,x)
}
scad = f'''projection(cut=true) translate([0,0,{-pos}]) multmatrix({mats[axis]}) translate([{-mn[0]},{-mn[1]},{-mn[2]}]) import("{os.path.abspath(stl)}");'''
d = tempfile.mkdtemp()
open(f'{d}/s.scad', 'w').write(scad)
r = subprocess.run(['openscad', '-q', '--backend=manifold', '-o', f'{d}/s.svg', f'{d}/s.scad'], capture_output=True, text=True)
if r.returncode:
    print("EMPTY (no geometry at this plane)" if "empty" in (r.stderr+r.stdout).lower() or not os.path.exists(f"{d}/s.svg") else r.stderr); sys.exit(0)
svg = open(f'{d}/s.svg').read()
paths = re.findall(r'd="([^"]+)"', svg)
for p in paths:
    for sub in re.split(r'(?=M)', p):
        nums = [float(n) for n in re.findall(r'-?\d+\.?\d*(?:e-?\d+)?', sub)]
        pts = list(zip(nums[0::2], [-v for v in nums[1::2]]))  # SVG y is flipped
        if len(pts) < 2: continue
        xs = [q[0] for q in pts]; ys = [q[1] for q in pts]
        a = 0.5 * sum(pts[i][0]*pts[(i+1)%len(pts)][1] - pts[(i+1)%len(pts)][0]*pts[i][1] for i in range(len(pts)))
        print(f"poly n={len(pts):3d} bbox=[{min(xs):.2f},{min(ys):.2f}]-[{max(xs):.2f},{max(ys):.2f}] area={a:+.1f}" + ("" if '--brief' in sys.argv else "\n  " + " ".join(f"({x:.2f},{y:.2f})" for x, y in pts)))
