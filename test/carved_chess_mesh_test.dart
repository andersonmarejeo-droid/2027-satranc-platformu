import 'dart:typed_data';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:chess_platform/features/game/presentation/widgets/carved_chess_mesh.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'bundled carved pieces have finite geometry and a bounded mobile budget',
    () async {
      final meshes = CarvedChessMeshes.decode(
        ByteData.sublistView(await File(CarvedChessMeshes.asset).readAsBytes()),
      );
      expect(meshes.keys.toSet(), {'p', 'r', 'n', 'b', 'q', 'k'});
      for (final faces in meshes.values) {
        expect(faces.length, inInclusiveRange(100, 2300));
        expect(faces.every((face) => face.points.length == 3), isTrue);
        expect(
          faces.every((face) {
            final cross = (face.points[1] - face.points[0]).cross(
              face.points[2] - face.points[0],
            );
            return cross.dot(cross) > 1e-12;
          }),
          isTrue,
        );
        expect(
          faces
              .expand((f) => f.points)
              .every(
                (p) =>
                    p.y >= -.001 &&
                    p.y <= 1.251 &&
                    p.x.abs() < .4 &&
                    p.z.abs() < .4,
              ),
          isTrue,
        );
        expect(
          faces
              .expand((f) => f.normals)
              .every((n) => (n.dot(n) - 1).abs() < 1e-5),
          isTrue,
        );
      }
    },
  );
  test('bad and truncated mesh data are rejected', () async {
    expect(() => CarvedChessMeshes.decode(ByteData(4)), throwsFormatException);
    final bytes = ByteData.sublistView(
      await File(CarvedChessMeshes.asset).readAsBytes(),
    );
    expect(
      () => CarvedChessMeshes.decode(
        ByteData.sublistView(
          bytes.buffer.asUint8List(),
          0,
          bytes.lengthInBytes - 1,
        ),
      ),
      throwsFormatException,
    );
  });
}
