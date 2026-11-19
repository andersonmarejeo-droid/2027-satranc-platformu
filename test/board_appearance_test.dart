import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_platform/features/settings/domain/board_appearance.dart';
import 'package:chess_platform/features/settings/data/local_board_appearance_repository.dart';
import 'package:chess_platform/features/settings/presentation/board_appearance_controller.dart';
import 'package:chess_platform/features/game/presentation/widgets/chess_mesh.dart';
import 'package:chess_platform/features/game/presentation/widgets/chess_table_3d.dart';

void main() {
  test(
    'knight bevels face outward so the closed head has no missing edge faces',
    () {
      for (final face in ChessMeshes.of('n')) {
        if (face.points.every((p) => p.y > .20 && p.z >= .08)) {
          expect(face.normals.first.z, greaterThan(0));
        }
        if (face.points.every((p) => p.y > .20 && p.z <= -.08)) {
          expect(face.normals.first.z, lessThan(0));
        }
        expect(face.points.length, lessThanOrEqualTo(4));
      }
    },
  );
  test('board, teams, view and camera survive reopening storage', () async {
    String? stored;
    BoardAppearanceRepository repository() => LocalBoardAppearanceRepository(
      read: () async => stored,
      write: (value) async {
        stored = value;
      },
    );
    final controller = BoardAppearanceController(repository());
    await controller.update(
      view: BoardViewMode.table3d,
      board: BoardStyle.candy,
      pieces: PieceStyle.coralBlue,
      camera: BoardCamera.high,
      shape: PieceShape.carved,
      showLegalMoves: false,
    );
    final reopened = BoardAppearanceController(repository());
    await reopened.load();
    expect(reopened.value, controller.value);
    expect(reopened.value.showLegalMoves, isFalse);
    controller.dispose();
    reopened.dispose();
  });
  test('corrupt and future preferences fall back safely', () async {
    for (final value in [
      '{bad',
      '[]',
      'null',
      '{"version":3,"view":"table3d"}',
    ]) {
      final repository = LocalBoardAppearanceRepository(
        read: () async => value,
        write: (_) async {},
      );
      expect(await repository.load(), const BoardAppearance());
    }
    expect(
      BoardAppearance.fromJson({
        'version': 1,
        'view': 'removed',
        'board': 'deleted',
      }),
      const BoardAppearance(),
    );
  });
  test(
    'rapid preference changes merge; failed writes can be retried',
    () async {
      final gate = Completer<void>();
      var writes = 0;
      var fail = false;
      final controller = BoardAppearanceController(
        LocalBoardAppearanceRepository(
          read: () async => null,
          write: (_) async {
            if (writes++ == 0) await gate.future;
            if (fail) throw StateError('storage unavailable');
          },
        ),
      );
      final first = controller.update(view: BoardViewMode.table3d);
      final second = controller.update(
        board: BoardStyle.meadow,
        pieces: PieceStyle.berryMint,
      );
      gate.complete();
      await Future.wait([first, second]);
      expect(controller.value.view, BoardViewMode.table3d);
      expect(controller.value.board, BoardStyle.meadow);
      fail = true;
      await expectLater(
        controller.update(camera: BoardCamera.low),
        throwsStateError,
      );
      expect(controller.value.camera, BoardCamera.balanced);
      fail = false;
      await controller.update(camera: BoardCamera.high);
      expect(controller.value.camera, BoardCamera.high);
      controller.dispose();
    },
  );
  test('every camera maps all 64 projected cells in both orientations', () {
    for (final camera in BoardCamera.values) {
      final projection = BoardProjection(const Size(360, 360), camera);
      for (final flipped in [false, true]) {
        for (var row = 0; row < 8; row++) {
          for (var col = 0; col < 8; col++) {
            final square = '${String.fromCharCode(97 + col)}${8 - row}';
            final center = projection.project(
              projection.center(square, flipped: flipped),
            );
            expect(
              projection.squareAt(center, flipped),
              square,
              reason: '$camera $flipped $square',
            );
          }
        }
        expect(projection.squareAt(Offset.zero, flipped), isNull);
      }
    }
  });
  test(
    'six chess meshes have volume, finite faces and distinct silhouettes',
    () {
      final sizes = <int>{};
      for (final type in ['p', 'r', 'n', 'b', 'q', 'k']) {
        final faces = ChessMeshes.of(type);
        sizes.add(faces.length);
        final points = faces.expand((f) => f.points).toList();
        expect(points.any((p) => p.x < -.1), isTrue);
        expect(points.any((p) => p.x > .1), isTrue);
        expect(points.any((p) => p.z < -.1), isTrue);
        expect(points.any((p) => p.z > .1), isTrue);
        expect(points.any((p) => p.y > .7), isTrue);
        expect(
          points.every((p) => p.x.isFinite && p.y.isFinite && p.z.isFinite),
          isTrue,
        );
        expect(faces.every((f) => f.normals.length == f.points.length), isTrue);
      }
      expect(sizes.length, 6);
    },
  );
}
