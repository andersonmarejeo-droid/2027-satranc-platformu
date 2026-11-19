"""Build mobile meshes from Poly Haven's CC0 chess_set glTF (offline).

Usage: python tool/import_chess_mesh.py [.dart_tool/asset-sources/chess-set] [grid]
Only geometry is imported; the app supplies its own six material palettes.
"""
import json
import math
import struct
import sys
from pathlib import Path

root = Path(__file__).resolve().parent.parent
source = Path(sys.argv[1]) if len(sys.argv) > 1 else root / '.dart_tool/asset-sources/chess-set'
grid = float(sys.argv[2]) if len(sys.argv) > 2 else 0.06
document = json.loads((source / 'chess-set.gltf').read_text())
buffer = (source / 'chess_set.bin').read_bytes()

def accessor(index):
    a = document['accessors'][index]
    v = document['bufferViews'][a['bufferView']]
    code = {5126: 'f', 5125: 'I', 5123: 'H'}[a['componentType']]
    components = {'SCALAR': 1, 'VEC3': 3}[a['type']]
    fmt = '<' + code * components
    stride = v.get('byteStride', struct.calcsize(fmt))
    offset = v.get('byteOffset', 0) + a.get('byteOffset', 0)
    return [struct.unpack_from(fmt, buffer, offset + i * stride) for i in range(a['count'])]

def unit(v):
    length = math.sqrt(sum(c * c for c in v))
    return tuple(c / length for c in v) if length > 1e-9 else (0., 1., 0.)

names = {'r': 'piece_rook_white_01', 'p': 'piece_pawn_white_01',
         'b': 'piece_bishop_white_01', 'q': 'piece_queen_white',
         'k': 'piece_king_white', 'n': 'piece_knight_white_01'}
scale = 1.25 / 0.095003
output = bytearray(b'CM01')
output.append(len(names))
stats = {}
for piece, name in names.items():
    node = next(n for n in document['nodes'] if n['name'] == name)
    assert not node.get('rotation') and not node.get('scale'), 'Unexpected node transform'
    primitives = document['meshes'][node['mesh']]['primitives']
    minimum = min(p[1] for prim in primitives for p in accessor(prim['attributes']['POSITION']))
    vertices, triangles = [], []
    original = 0
    for prim in primitives:
        points = accessor(prim['attributes']['POSITION'])
        normals = accessor(prim['attributes']['NORMAL'])
        indices = [i[0] for i in accessor(prim['indices'])]
        original += len(indices) // 3
        groups, remap = {}, []
        # Preserve hard edges by clustering only similarly oriented normals.
        for p, n in zip(points, normals):
            p = (p[0] * scale, (p[1] - minimum) * scale, p[2] * scale)
            key = tuple(round(c / grid) for c in p) + tuple(round(c * 2) for c in n)
            if key not in groups:
                groups[key] = [len(groups), [0.] * 6, 0]
            group = groups[key]
            for i, c in enumerate(p + n):
                group[1][i] += c
            group[2] += 1
            remap.append(group[0])
        base = len(vertices)
        clustered = [tuple(s / count for s in sums[:3]) + unit(sums[3:])
                     for _, sums, count in groups.values()]
        vertices.extend(clustered)
        seen = set()
        for i in range(0, len(indices), 3):
            tri = tuple(remap[j] for j in indices[i:i + 3])
            if len(set(tri)) < 3 or tuple(sorted(tri)) in seen:
                continue
            a, b, c = [clustered[j][:3] for j in tri]
            ab, ac = [b[j] - a[j] for j in range(3)], [c[j] - a[j] for j in range(3)]
            cross = (ab[1]*ac[2]-ab[2]*ac[1], ab[2]*ac[0]-ab[0]*ac[2], ab[0]*ac[1]-ab[1]*ac[0])
            if sum(v * v for v in cross) < 1e-12:
                continue
            seen.add(tuple(sorted(tri)))
            triangles.extend(j + base for j in tri)
    # Drop vertices no longer referenced by triangles.
    used = sorted(set(triangles))
    remap = {old: new for new, old in enumerate(used)}
    vertices = [vertices[i] for i in used]
    triangles = [remap[i] for i in triangles]
    assert len(vertices) < 65536
    output.extend(struct.pack('<cII', piece.encode('ascii'), len(vertices), len(triangles)))
    for v in vertices:
        output.extend(struct.pack('<6f', *v))
    output.extend(struct.pack('<' + 'H' * len(triangles), *triangles))
    stats[piece] = {'source_triangles': original, 'mobile_triangles': len(triangles) // 3, 'vertices': len(vertices)}
target = root / 'assets/meshes/polyhaven-chess-mobile-v1.mesh'
target.parent.mkdir(parents=True, exist_ok=True)
target.write_bytes(output)
print(json.dumps({'bytes': len(output), 'grid': grid, 'meshes': stats}, indent=2))
