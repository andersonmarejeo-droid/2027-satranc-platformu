import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_platform/app/chess_app.dart';
import 'package:chess_platform/features/settings/domain/board_appearance.dart';
import 'package:chess_platform/features/game/data/local_chess_rules.dart';
import 'package:chess_platform/features/game/presentation/game_controller.dart';
import 'package:chess_platform/features/game/presentation/widgets/chess_board.dart';
import 'package:chess_platform/features/game/presentation/widgets/chess_table_3d.dart';

import 'widget_test.dart' show services, memoryHistory, previewGame;

void main() {
  testWidgets(
    '3D capture taps on an opposing piece head make the legal capture',
    (tester) async {
      final game = GameController(
        LocalChessRules(fen: '4k3/8/8/3p4/4P3/8/8/4K3 w - - 0 1'),
      );
      for (final camera in BoardCamera.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  height: 360,
                  child: ListenableBuilder(
                    listenable: game,
                    builder: (context, _) => ChessBoard(
                      controller: game,
                      appearance: BoardAppearance(
                        view: BoardViewMode.table3d,
                        camera: camera,
                        board: BoardStyle.candy,
                        showLegalMoves: false,
                      ),
                      onSquareTap: game.selectOrMove,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final p = BoardProjection(const Size(360, 360), camera);
        final origin = tester.getTopLeft(
          find.byKey(const ValueKey('board-3d')),
        );
        await tester.tapAt(origin + p.project(p.center('e4', height: .67)));
        await tester.pumpAndSettle();
        expect(game.targets, contains('d5'));
        await tester.tapAt(origin + p.project(p.center('d5', height: .67)));
        await tester.pumpAndSettle();
        expect(game.rules.history, ['exd5']);
        expect(game.rules.pieceAt('d5')!.isWhite, isTrue);
        game.undo();
        await tester.pumpAndSettle();
      }
      await tester.pumpWidget(const SizedBox.shrink());
      game.dispose();
    },
  );
  testWidgets(
    '3D piece head taps select its own square at every camera angle',
    (tester) async {
      final game = GameController(LocalChessRules());
      for (final camera in BoardCamera.values) {
        for (final flipped in [false, true]) {
          game.flipped = flipped;
          game.selected = null;
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 360,
                    height: 360,
                    child: ListenableBuilder(
                      listenable: game,
                      builder: (context, _) => ChessBoard(
                        controller: game,
                        appearance: BoardAppearance(
                          view: BoardViewMode.table3d,
                          camera: camera,
                          board: BoardStyle.candy,
                        ),
                        onSquareTap: game.selectOrMove,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final p = BoardProjection(const Size(360, 360), camera);
          final origin = tester.getTopLeft(
            find.byKey(const ValueKey('board-3d')),
          );
          await tester.tapAt(
            origin + p.project(p.center('e2', flipped: flipped, height: .67)),
          );
          await tester.pumpAndSettle();
          expect(game.selected, 'e2', reason: '$camera flipped=$flipped');
          await tester.tapAt(
            origin + p.project(p.center('e3', flipped: flipped)),
          );
          await tester.pumpAndSettle();
          expect(game.rules.history, [
            'e3',
          ], reason: 'adjacent move $camera flipped=$flipped');
          game.reset();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
      game.dispose();
    },
  );
  for (final view in BoardViewMode.values) {
    testWidgets('$view supports e2-e4 and flipped e7-e5 without losing state', (
      tester,
    ) async {
      final game = GameController(LocalChessRules());
      var appearance = BoardAppearance(
        view: view,
        board: BoardStyle.candy,
        pieces: PieceStyle.coralBlue,
      );
      Future<void> pump() => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 360,
                child: ListenableBuilder(
                  listenable: game,
                  builder: (context, _) => ChessBoard(
                    controller: game,
                    appearance: appearance,
                    onSquareTap: game.selectOrMove,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await pump();
      await tester.pumpAndSettle();
      Future<void> tap(String square) async {
        if (view == BoardViewMode.table3d) {
          final origin = tester.getTopLeft(
            find.byKey(const ValueKey('board-3d')),
          );
          final p = BoardProjection(const Size(360, 360), appearance.camera);
          await tester.tapAt(
            origin + p.project(p.center(square, flipped: game.flipped)),
          );
        } else if (view == BoardViewMode.wizard3d) {
          game.selectOrMove(square);
        } else {
          await tester.tap(find.byKey(ValueKey('square-$square')));
        }
        await tester.pumpAndSettle();
      }

      await tap('e2');
      expect(game.selected, 'e2');
      expect(game.targets, contains('e4'));
      await tap('e4');
      expect(game.rules.history, ['e4']);
      game.flip();
      await tester.pumpAndSettle();
      await tap('e7');
      expect(game.selected, 'e7');
      await tap('e5');
      expect(game.rules.history, ['e4', 'e5']);
      final fen = game.rules.fen;
      appearance = appearance.copyWith(
        pieces: PieceStyle.sunViolet,
        board: BoardStyle.lavender,
      );
      await pump();
      await tester.pumpAndSettle();
      expect(game.rules.fen, fen);
      expect(game.flipped, isTrue);
      for (final mode in BoardViewMode.values) {
        appearance = appearance.copyWith(view: mode);
        await pump();
        await tester.pumpAndSettle();
        expect(game.rules.fen, fen);
        expect(game.rules.history, ['e4', 'e5']);
        if (mode == BoardViewMode.wizard3d) {
          expect(find.byKey(const ValueKey('wizard-chess-3d')), findsOneWidget);
        } else {
          expect(find.byKey(const ValueKey('square-e4')), findsOneWidget);
        }
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      game.dispose();
    });
  }
  testWidgets('game picker applies colorful 3D; replay remains read only', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dependencies = services();
    await tester.pumpWidget(
      ChessApp(services: dependencies, initialLocation: '/game?clock=0'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('board-appearance')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('view-table3d')));
    await tester.pumpAndSettle();
    final candy = find.byKey(const ValueKey('board-candy'));
    await tester.ensureVisible(candy);
    await tester.tap(candy);
    await tester.pumpAndSettle();
    expect(dependencies.boardAppearance.value.pieces, PieceStyle.coralBlue);
    await tester.ensureVisible(find.byTooltip('Kapat'));
    await tester.tap(find.byTooltip('Kapat'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('board-3d')), findsOneWidget);
    final history = memoryHistory();
    await history.save(previewGame());
    await tester.pumpWidget(
      ChessApp(
        key: const ValueKey('replay'),
        services: services(
          gameHistory: history,
          boardAppearance: dependencies.boardAppearance,
        ),
        initialLocation: '/history/0123456789abcdef0123456789abcdef',
      ),
    );
    await tester.pumpAndSettle();
    final detector = tester.widget<GestureDetector>(
      find.byKey(const ValueKey('board-3d')),
    );
    expect(detector.onTapUp, isNull);
    expect(find.byKey(const ValueKey('square-e2')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('3D appearance controls fit small phone and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final dependencies = services();
    await dependencies.boardAppearance.update(
      view: BoardViewMode.table3d,
      board: BoardStyle.meadow,
    );
    await tester.pumpWidget(
      ChessApp(services: dependencies, initialLocation: '/settings'),
    );
    await tester.pumpAndSettle();
    for (final key in [
      'camera-low',
      'board-marble',
      'board-lavender',
      'pieces-sunViolet',
      'appearance-reset',
    ]) {
      final target = find.byKey(ValueKey(key));
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: key);
    }
    expect(dependencies.boardAppearance.value, const BoardAppearance());
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
