import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_platform/app/chess_app.dart';
import 'package:chess_platform/features/game/domain/saved_game.dart';
import 'package:chess_platform/features/game/domain/computer_difficulty.dart';
import 'package:chess_platform/features/game/presentation/widgets/chess_board.dart';
import 'package:chess_platform/features/game/presentation/game_draft_controller.dart';
import 'package:chess_platform/features/game/presentation/widgets/chess_table_3d.dart';
import 'package:chess_platform/features/game/presentation/widgets/carved_chess_mesh.dart';
import 'package:chess_platform/features/settings/domain/board_appearance.dart';
import 'package:chess_platform/features/game/data/local_chess_rules.dart';
import 'package:chess_platform/features/game/presentation/game_controller.dart';
import 'package:chess_platform/features/game/presentation/move_presentation.dart';

import 'widget_test.dart' show services, memoryDraftRepository;
import 'community_membership_test.dart' show schoolMembership;
import '../tool/test_assets.dart';

void main() {
  testWidgets(
    'difficulty choices and computer player names fit a small phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        ChessApp(services: services(), initialLocation: '/play'),
      );
      await tester.pumpAndSettle();
      for (final level in ComputerDifficulty.values) {
        final choice = find.byKey(ValueKey('difficulty-${level.name}'));
        await tester.ensureVisible(choice);
        await tester.tap(choice);
        await tester.pumpAndSettle();
        expect(find.text('${level.label} · İnternetsiz oyna'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      final start = find.byKey(const ValueKey('start-computer-game'));
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pumpAndSettle();
      expect(find.text('Sen'), findsOneWidget);
      expect(find.text('Bilgisayar'), findsOneWidget);
      expect(find.text('Usta'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'school classes and cross-school groups have separate navigation',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ChessApp(services: services(), initialLocation: '/leaderboard'),
      );
      await tester.pumpAndSettle();
      Future<void> tap(String key) async {
        final f = find.byKey(ValueKey(key));
        await tester.ensureVisible(f);
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      await tap('ranking-city');
      expect(
        find.byKey(const ValueKey('ranking-community-giresun')),
        findsOneWidget,
      );
      await tap('ranking-community-giresun');
      await tap('ranking-school');
      expect(
        find.byKey(const ValueKey('ranking-community-gfl')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('ranking-community-istanbul-demo')),
        findsNothing,
      );
      await tap('ranking-community-gfl');
      await tap('ranking-school-classes');
      await tap('ranking-class-gfl-9a');
      expect(
        (tester.widget<Text>(find.byKey(const ValueKey('ranking-path')))).data,
        'Türkiye › Giresun › Giresun Fen Lisesi › 9-A',
      );
      expect(find.text('Deniz K.'), findsOneWidget);
      expect(find.text('Mert Y.'), findsNothing);
      expect(find.byKey(const ValueKey('ranking-classroom')), findsNothing);
      await tap('ranking-group');
      await tap('ranking-community-friends');
      expect(find.text('Mert Y.'), findsOneWidget);
      expect(find.text('Asya M.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'registration offers classes only beneath their school and updates profile',
    (tester) async {
      final dependencies = services();
      await dependencies.membership.save(schoolMembership());
      await tester.pumpWidget(
        ChessApp(services: dependencies, initialLocation: '/profile'),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('edit-membership')));
      await tester.tap(find.byKey(const ValueKey('edit-membership')));
      await tester.pumpAndSettle();
      final city = find.byKey(const ValueKey('join-city-tr-giresun'));
      await tester.ensureVisible(city);
      await tester.tap(city);
      await tester.pumpAndSettle();
      await tester.tap(find.text('İstanbul').last);
      await tester.pumpAndSettle();
      // The next searchable sheet opens automatically after choosing a city.
      await tester.tap(find.byKey(const ValueKey('community-skip')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('join-classroom-gfl-gfl-9a')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('join-school-istanbul-null')),
        findsOneWidget,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('save-membership')));
      await tester.tap(find.byKey(const ValueKey('save-membership')));
      await tester.pumpAndSettle();
      expect(dependencies.membership.value.cityId, 'istanbul');
      expect(dependencies.membership.value.schoolId, isNull);
      expect(dependencies.membership.value.groupIds, {'friends'});
      expect(find.text('İstanbul'), findsOneWidget);
      expect(find.text('Okul seç'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'computer move, takeback and resume preserve opponent mode; stale replies are ignored',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = memoryDraftRepository(),
          store = GameDraftController(memoryDraftRepository());
      // A shared repository represents a fresh app process reopening its saved draft.
      final draftStore = GameDraftController(repository);
      var pending = Completer<Map<String, String>?>();
      final dependencies = services(
        gameDraft: draftStore,
        computerMove: (_, level) {
          expect(level, ComputerDifficulty.hard);
          return pending.future;
        },
      );
      await tester.pumpWidget(
        ChessApp(services: dependencies, initialLocation: '/play'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('difficulty-hard')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('start-computer-game')));
      await tester.pumpAndSettle();
      expect(find.text('Sen'), findsOneWidget);
      expect(find.text('Bilgisayar'), findsOneWidget);
      expect(find.text('Senin sıran'), findsOneWidget);
      expect(find.text('Sen · Beyaz'), findsNothing);
      expect(find.text('Zor'), findsOneWidget);
      Future<void> tapSquare(String square) async {
        final f = find.byKey(ValueKey('square-$square'));
        await tester.ensureVisible(f);
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      await tapSquare('e2');
      await tapSquare('e4');
      expect(find.text('Bilgisayar düşünüyor…'), findsOneWidget);
      final undo = find.text('Geri al');
      await tester.ensureVisible(undo);
      await tester.tap(undo);
      await tester.pumpAndSettle();
      pending.complete({'from': 'e7', 'to': 'e5', 'promotion': 'q'});
      await tester.pump(MovePresentation.computerDelay + const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChessBoard>(find.byType(ChessBoard))
            .controller
            .rules
            .history,
        isEmpty,
      );
      pending = Completer<Map<String, String>?>();
      await tapSquare('e2');
      await tapSquare('e4');
      pending.complete({'from': 'e7', 'to': 'e5', 'promotion': 'q'});
      await tester.pump(MovePresentation.computerDelay + const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(draftStore.draft!.game.moves, ['e4', 'e5']);
      expect(draftStore.draft!.game.clockEnabled, isFalse);
      expect(draftStore.draft!.game.opponent, GameOpponent.computer);
      expect(draftStore.draft!.game.difficulty, ComputerDifficulty.hard);
      await tester.pumpWidget(const SizedBox.shrink());
      final reopened = GameDraftController(repository);
      await reopened.load();
      await tester.pumpWidget(
        ChessApp(
          services: services(
            gameDraft: reopened,
            computerMove: (_, _) async => null,
          ),
          initialLocation: '/game?resume=1&difficulty=easy',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sen ve Bilgisayar'), findsOneWidget);
      expect(find.text('Zor'), findsOneWidget);
      expect(
        tester
            .widget<ChessBoard>(find.byType(ChessBoard))
            .controller
            .rules
            .history,
        ['e4', 'e5'],
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
    },
  );
  testWidgets(
    'bundled carved geometry loads, paints and accepts an e2-e4 head tap',
    (tester) async {
      await tester.runAsync(
        () => CarvedChessMeshes.load(bundle: SourceAssetBundle()),
      );
      final game = GameController(LocalChessRules());
      const appearance = BoardAppearance(
        view: BoardViewMode.table3d,
        shape: PieceShape.carved,
        board: BoardStyle.candy,
      );
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
                    appearance: appearance,
                    onSquareTap: game.selectOrMove,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<ChessTable3D>(find.byType(ChessTable3D)).detailedMeshes,
        isNotNull,
      );
      final projection = BoardProjection(
        const Size(360, 360),
        BoardCamera.balanced,
      );
      final origin = tester.getTopLeft(find.byKey(const ValueKey('board-3d')));
      await tester.tapAt(
        origin + projection.project(projection.center('e2', height: .65)),
      );
      await tester.pumpAndSettle();
      expect(game.selected, 'e2');
      await tester.tapAt(origin + projection.project(projection.center('e4')));
      await tester.pumpAndSettle();
      expect(game.rules.history, ['e4']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      game.dispose();
    },
  );
}
