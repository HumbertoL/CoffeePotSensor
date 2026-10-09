"""Minimal STL reader: triangles, bounding box and volume (binary or ASCII STL)."""
import struct
def load(p):
    d = open(p, 'rb').read()
    n = struct.unpack('<I', d[80:84])[0]
    if 84 + 50 * n == len(d):
        return [struct.unpack('<12f', d[84+50*i:84+50*i+48])[3:] for i in range(n)]
    # ASCII STL (OpenSCAD writes ASCII by default)
    import re
    v = [tuple(map(float, m)) for m in re.findall(r'vertex\s+(\S+)\s+(\S+)\s+(\S+)', d.decode())]
    return [v[i]+v[i+1]+v[i+2] for i in range(0, len(v), 3)]
def bbox(p):
    t = load(p)
    xs = [q for tr in t for q in tr[0::3]]; ys = [q for tr in t for q in tr[1::3]]; zs = [q for tr in t for q in tr[2::3]]
    return (min(xs), min(ys), min(zs)), (max(xs), max(ys), max(zs))
def volume(p):
    s = 0
    for t in load(p):
        a, b, c = t[0:3], t[3:6], t[6:9]
        s += (a[0]*(b[1]*c[2]-b[2]*c[1]) - a[1]*(b[0]*c[2]-b[2]*c[0]) + a[2]*(b[0]*c[1]-b[1]*c[0])) / 6
    return s
