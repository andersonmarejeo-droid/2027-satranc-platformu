import 'dart:math' as math;

class Vec3 {
  const Vec3(this.x, this.y, this.z);
  final double x, y, z;
  Vec3 operator +(Vec3 v) => Vec3(x + v.x, y + v.y, z + v.z);
  Vec3 operator -(Vec3 v) => Vec3(x - v.x, y - v.y, z - v.z);
  Vec3 operator *(double s) => Vec3(x * s, y * s, z * s);
  double dot(Vec3 v) => x * v.x + y * v.y + z * v.z;
  Vec3 cross(Vec3 v) =>
      Vec3(y * v.z - z * v.y, z * v.x - x * v.z, x * v.y - y * v.x);
  Vec3 get unit {
    final length = math.sqrt(dot(this));
    return length < 1e-8 ? const Vec3(0, 1, 0) : this * (1 / length);
  }
}

class MeshFace {
  MeshFace(this.points, {List<Vec3>? normals})
    : normals =
          normals ??
          List.filled(
            points.length,
            (points[1] - points[0]).cross(points[2] - points[0]).unit,
          );
  final List<Vec3> points, normals;
  late final Vec3 surfaceNormal = (points[1] - points[0])
      .cross(points[2] - points[0])
      .unit;
}

/// Actual three dimensional lathed and extruded geometry in board-square units.
/// Cached meshes are independent of camera, theme and game state.
class ChessMeshes {
  static final _cache = <String, List<MeshFace>>{};
  static List<MeshFace> of(String type) =>
      _cache.putIfAbsent(type, () => _make(type));
  static List<MeshFace> _lathe(
    List<(double, double)> profile, {
    int segments = 20,
  }) {
    final faces = <MeshFace>[];
    Vec3 point(int ring, int segment) {
      final (r, y) = profile[ring];
      final angle = segment * 2 * math.pi / segments;
      return Vec3(r * math.cos(angle), y, r * math.sin(angle));
    }

    Vec3 normal(int ring, int segment) {
      final before = profile[math.max(0, ring - 1)],
          after = profile[math.min(profile.length - 1, ring + 1)];
      final dr = after.$1 - before.$1, dy = after.$2 - before.$2;
      final angle = segment * 2 * math.pi / segments;
      return Vec3(dy * math.cos(angle), -dr, dy * math.sin(angle)).unit;
    }

    for (var i = 0; i < profile.length - 1; i++) {
      for (var j = 0; j < segments; j++) {
        final rings = [(i, j), (i + 1, j), (i + 1, j + 1), (i, j + 1)];
        final p = rings.map((v) => point(v.$1, v.$2)).toList();
        // A zero-radius ring becomes a triangle, avoiding a degenerate cull normal.
        final n = rings.map((v) => normal(v.$1, v.$2)).toList();
        if (profile[i].$1 == 0) {
          p.removeLast();
          n.removeLast();
        }
        if (profile[i + 1].$1 == 0) {
          p.removeAt(2);
          n.removeAt(2);
        }
        if ((p[1] - p[0])
                .cross(p[2] - p[0])
                .dot((p[1] - p[0]).cross(p[2] - p[0])) >
            1e-10) {
          faces.add(MeshFace(p, normals: n));
        }
      }
    }
    return faces;
  }

  static List<MeshFace> box(Vec3 center, Vec3 half) {
    final x = center.x, y = center.y, z = center.z;
    final a = half.x, b = half.y, c = half.z;
    final p = [
      Vec3(x - a, y - b, z - c),
      Vec3(x + a, y - b, z - c),
      Vec3(x + a, y + b, z - c),
      Vec3(x - a, y + b, z - c),
      Vec3(x - a, y - b, z + c),
      Vec3(x + a, y - b, z + c),
      Vec3(x + a, y + b, z + c),
      Vec3(x - a, y + b, z + c),
    ];
    return [
      for (final indices in const [
        [0, 3, 2, 1],
        [4, 5, 6, 7],
        [0, 4, 7, 3],
        [1, 2, 6, 5],
        [3, 7, 6, 2],
        [0, 1, 5, 4],
      ])
        MeshFace(indices.map((i) => p[i]).toList()),
    ];
  }

  // Ear clipping preserves the concave horse outline without filling its neck cutout.
  static List<List<int>> _triangulate(List<(double, double)> outline) {
    double cross(int a, int b, int c) =>
        (outline[b].$1 - outline[a].$1) * (outline[c].$2 - outline[a].$2) -
        (outline[b].$2 - outline[a].$2) * (outline[c].$1 - outline[a].$1);
    final remaining = List.generate(outline.length, (i) => i),
        triangles = <List<int>>[];
    while (remaining.length > 3) {
      var found = false;
      for (var i = 0; i < remaining.length; i++) {
        final a = remaining[(i + remaining.length - 1) % remaining.length],
            b = remaining[i],
            c = remaining[(i + 1) % remaining.length];
        if (cross(a, b, c) <= 1e-9) continue;
        final contains = remaining.any(
          (p) =>
              p != a &&
              p != b &&
              p != c &&
              cross(a, b, p) >= -1e-9 &&
              cross(b, c, p) >= -1e-9 &&
              cross(c, a, p) >= -1e-9,
        );
        if (contains) continue;
        triangles.add([a, b, c]);
        remaining.removeAt(i);
        found = true;
        break;
      }
      if (!found) throw StateError('Invalid chess mesh outline');
    }
    triangles.add(remaining);
    return triangles;
  }

  static List<MeshFace> _make(String type) {
    final base = <(double, double)>[
      (0, 0),
      (.30, 0),
      (.34, .035),
      (.34, .08),
      (.30, .115),
      (.28, .14),
      (.28, .17),
      (.23, .19),
    ];
    final body = <(double, double)>[
      (.23, .19),
      (.19, .25),
      (.145, .34),
      (.11, .49),
      (.13, .58),
      (.22, .61),
      (.23, .64),
      (.19, .675),
    ];
    switch (type) {
      case 'p':
        return _lathe([
          ...base,
          (.19, .25),
          (.13, .37),
          (.11, .43),
          (.18, .46),
          (.18, .50),
          (.11, .53),
          (.16, .57),
          (.195, .64),
          (.19, .72),
          (.14, .80),
          (.07, .84),
          (0, .855),
        ]);
      case 'r':
        final result = _lathe([
          ...base,
          (.22, .25),
          (.185, .55),
          (.24, .60),
          (.26, .64),
          (.26, .76),
          (0, .76),
        ]);
        for (var i = 0; i < 6; i++) {
          final angle = i * math.pi / 3;
          result.addAll(
            box(
              Vec3(.215 * math.cos(angle), .805, .215 * math.sin(angle)),
              const Vec3(.075, .07, .075),
            ),
          );
        }
        return result;
      case 'b':
        return _lathe([
          ...base,
          ...body.skip(1),
          (.13, .70),
          (.22, .76),
          (.22, .83),
          (.17, .91),
          (.09, 1.02),
          (.04, 1.055),
          (.07, 1.08),
          (.065, 1.13),
          (0, 1.155),
        ]);
      case 'q':
        final result = _lathe([
          ...base,
          ...body.skip(1),
          (.16, .74),
          (.22, .85),
          (.27, .94),
          (.26, .98),
          (.17, .96),
          (0, .94),
        ]);
        for (var i = 0; i < 8; i++) {
          final angle = i * math.pi / 4;
          final x = .235 * math.cos(angle), z = .235 * math.sin(angle);
          final spike = _lathe([
            (0, 0),
            (.052, 0),
            (.035, .16),
            (0, .19),
          ], segments: 8);
          result.addAll(
            spike.map(
              (face) => MeshFace(
                face.points.map((p) => p + Vec3(x, .94, z)).toList(),
                normals: face.normals,
              ),
            ),
          );
        }
        return result;
      case 'k':
        return [
          ..._lathe([
            ...base,
            ...body.skip(1),
            (.14, .74),
            (.24, .79),
            (.24, .83),
            (.16, .87),
            (0, .90),
          ]),
          ...box(const Vec3(0, 1.04, 0), const Vec3(.055, .18, .055)),
          ...box(const Vec3(0, 1.075, 0), const Vec3(.165, .05, .055)),
        ];
      default:
        final result = _lathe([...base, (.24, .23), (0, .23)]);
        const silhouette = [
          (-.23, .23),
          (.23, .23),
          (.25, .51),
          (.20, .79),
          (.09, .95),
          (-.03, 1.0),
          (-.13, 1.12),
          (-.18, .92),
          (-.32, .75),
          (-.36, .67),
          (-.27, .60),
          (-.10, .64),
          (-.13, .46),
        ];
        for (final sign in [-1.0, 1.0]) {
          final front = <Vec3>[];
          for (var i = 0; i < silhouette.length; i++) {
            final p = silhouette[i],
                prev =
                    silhouette[(i + silhouette.length - 1) % silhouette.length],
                next = silhouette[(i + 1) % silhouette.length];
            final before = Vec3(-(p.$2 - prev.$2), p.$1 - prev.$1, 0).unit;
            final after = Vec3(-(next.$2 - p.$2), next.$1 - p.$1, 0).unit;
            var offset =
                (before + after) *
                (.014 / math.max(.05, 1 + before.dot(after)));
            if (offset.dot(offset) > .045 * .045) offset = offset.unit * .045;
            front.add(Vec3(p.$1 + offset.x, p.$2 + offset.y, sign * .145));
          }
          for (final triangle in _triangulate(
            front.map((p) => (p.x, p.y)).toList(),
          )) {
            final points = triangle.map((i) => front[i]).toList();
            result.add(MeshFace(sign > 0 ? points : points.reversed.toList()));
          }
          for (var i = 0; i < silhouette.length; i++) {
            final j = (i + 1) % silhouette.length;
            final a = silhouette[i], b = silhouette[j];
            final bevel = [
              Vec3(a.$1, a.$2, sign * .085),
              Vec3(b.$1, b.$2, sign * .085),
              front[j],
              front[i],
            ];
            result.add(MeshFace(sign > 0 ? bevel : bevel.reversed.toList()));
          }
        }
        for (var i = 0; i < silhouette.length; i++) {
          final a = silhouette[i], b = silhouette[(i + 1) % silhouette.length];
          result.add(
            MeshFace([
              Vec3(a.$1, a.$2, -.085),
              Vec3(b.$1, b.$2, -.085),
              Vec3(b.$1, b.$2, .085),
              Vec3(a.$1, a.$2, .085),
            ]),
          );
        }
        return result;
    }
  }
}
