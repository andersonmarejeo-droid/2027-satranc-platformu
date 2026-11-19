import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'chess_mesh.dart';

/// Offline, simplified Poly Haven CC0 geometry. No network or GPU plugin needed.
class CarvedChessMeshes {
  static const asset = 'assets/meshes/polyhaven-chess-mobile-v1.mesh';
  static Future<Map<String, List<MeshFace>>>? _pending;
  static Map<String, List<MeshFace>>? _loaded;
  static Map<String, List<MeshFace>>? get cached => _loaded;
  static Future<Map<String, List<MeshFace>>> load({AssetBundle? bundle}) =>
      _pending ??= (bundle ?? rootBundle)
          .load(asset)
          .then((data) => _loaded = decode(data))
          .catchError((Object error) {
            _pending =
                null; // A transient asset error must not poison future loads.
            throw error;
          });

  static Map<String, List<MeshFace>> decode(ByteData data) {
    var offset = 0;
    void require(int count) {
      if (offset + count > data.lengthInBytes) {
        throw const FormatException('Truncated chess mesh');
      }
    }

    int byte() {
      require(1);
      return data.getUint8(offset++);
    }

    int integer() {
      require(4);
      final value = data.getUint32(offset, Endian.little);
      offset += 4;
      return value;
    }

    double number() {
      require(4);
      final value = data.getFloat32(offset, Endian.little);
      offset += 4;
      if (!value.isFinite) throw const FormatException('Invalid chess vertex');
      return value;
    }

    Vec3 vector() => Vec3(number(), number(), number());
    if (String.fromCharCodes(List.generate(4, (_) => byte())) != 'CM01' ||
        byte() != 6) {
      throw const FormatException('Unsupported chess mesh');
    }
    final meshes = <String, List<MeshFace>>{};
    for (var mesh = 0; mesh < 6; mesh++) {
      final type = String.fromCharCode(byte());
      final vertices = integer(), indices = integer();
      if (!['p', 'r', 'n', 'b', 'q', 'k'].contains(type) ||
          meshes.containsKey(type) ||
          vertices < 3 ||
          vertices > 65535 ||
          indices < 3 ||
          indices > 30000 ||
          indices % 3 != 0) {
        throw const FormatException('Invalid chess mesh counts');
      }
      final points = <Vec3>[], normals = <Vec3>[];
      for (var i = 0; i < vertices; i++) {
        points.add(vector());
        normals.add(vector().unit);
      }
      final faces = <MeshFace>[];
      for (var i = 0; i < indices; i += 3) {
        final triangle = <int>[];
        for (var j = 0; j < 3; j++) {
          require(2);
          final index = data.getUint16(offset, Endian.little);
          offset += 2;
          if (index >= vertices) {
            throw const FormatException('Invalid chess index');
          }
          triangle.add(index);
        }
        faces.add(
          MeshFace(
            [for (final index in triangle) points[index]],
            normals: [for (final index in triangle) normals[index]],
          ),
        );
      }
      meshes[type] = List.unmodifiable(faces);
    }
    if (offset != data.lengthInBytes) {
      throw const FormatException('Unexpected mesh payload');
    }
    return Map.unmodifiable(meshes);
  }
}
