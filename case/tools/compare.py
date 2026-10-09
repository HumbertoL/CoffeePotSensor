#!/usr/bin/env python3
"""compare.py ORIGINAL.STL MODEL.scad [module-call]
Translate the original so its bbox min is at the origin, then report the volumes of
original-minus-model and model-minus-original (mm^3). Both ~0 means a match."""
import subprocess, sys, tempfile, os
sys.path.insert(0, os.path.dirname(__file__))
from stlinfo_lib import bbox, volume
stl, model = os.path.abspath(sys.argv[1]), os.path.abspath(sys.argv[2])
call = sys.argv[3] if len(sys.argv) > 3 else None
mn = bbox(stl)[0]
d = tempfile.mkdtemp()
orig = f'translate([{-mn[0]},{-mn[1]},{-mn[2]}]) import("{stl}");'
mod = (f'use <{model}>\n{call};' if call else f'include <{model}>')
res = {}
for name, body in (('orig-model', f'difference() {{ {orig} {{ MODEL(); }} }}'), ('model-orig', f'difference() {{ MODEL(); {orig} }}'), ('model', 'MODEL();')):
    src = (f'use <{model}>\nmodule MODEL() {call};\n' if call else f'module MODEL() {{ include <{model}> }}\n') + body.replace('{ MODEL(); }', 'MODEL();')
    open(f'{d}/{name}.scad', 'w').write(src)
    r = subprocess.run(['openscad', '-q', '--backend=manifold', '-o', f'{d}/{name}.stl', f'{d}/{name}.scad'], capture_output=True, text=True)
    if r.returncode or not os.path.exists(f'{d}/{name}.stl'):
        res[name] = 0.0 if 'empty' in (r.stderr + r.stdout).lower() else f'ERR {r.stderr.strip()[:300]}'
    else:
        res[name] = volume(f'{d}/{name}.stl')
ov = volume(stl)
print(f"original vol={ov:.1f}  model vol={res['model'] if isinstance(res['model'], str) else round(res['model'],1)}")
for k in ('orig-model', 'model-orig'):
    v = res[k]
    print(f"  {k}: {v if isinstance(v, str) else f'{v:.1f} mm3 ({100*v/ov:.2f}%)'}")
if not isinstance(res['model'], str):
    print("  model bbox:", bbox(f'{d}/model.stl'))
