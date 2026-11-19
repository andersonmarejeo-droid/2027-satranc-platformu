import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_platform/app/chess_app.dart';
import 'package:chess_platform/features/game/data/local_chess_rules.dart';
import 'package:chess_platform/features/game/data/local_game_draft_repository.dart';
import 'package:chess_platform/features/game/presentation/game_draft_controller.dart';
import 'package:chess_platform/features/game/presentation/game_controller.dart';
import 'package:chess_platform/features/game/presentation/widgets/chess_board.dart';
import 'package:chess_platform/features/game/presentation/widgets/chess_table_3d.dart';
import 'package:chess_platform/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:chess_platform/features/settings/domain/board_appearance.dart';

import 'widget_test.dart' show services;
import 'community_membership_test.dart' show schoolMembership;

class IdentityRankings implements LeaderboardRepository {
  @override
  bool get isDemo => false;
  @override
  String get currentPlayerId => 'me';
  static const players = [
    RankingEntry(
      'Ada',
      1800,
      10,
      playerId: 'another-ada',
      cityId: 'giresun',
      schoolId: 'gfl',
      classId: 'gfl-9a',
    ),
    RankingEntry(
      'Ada',
      1600,
      8,
      playerId: 'me',
      cityId: 'giresun',
      schoolId: 'gfl',
      classId: 'gfl-9a',
    ),
    RankingEntry(
      'Ece',
      2000,
      12,
      playerId: 'ece',
      cityId: 'giresun',
      schoolId: 'gfl',
      classId: 'gfl-9b',
    ),
    RankingEntry(
      'Diğer okul',
      2300,
      14,
      playerId: 'other-school',
      cityId: 'giresun',
      schoolId: 'gl',
      classId: 'gl-9a',
    ),
  ];
  @override
  List<RankingEntry> entries(RankingScope scope, {String? id}) => players
      .where(
        (p) => switch (scope) {
          RankingScope.country => p.countryId == id,
          RankingScope.city => p.cityId == id,
          RankingScope.school => p.schoolId == id,
          RankingScope.classroom => p.classId == id,
          RankingScope.group => p.groupIds.contains(id),
        },
      )
      .toList();
}

void main() {
  testWidgets('saving and turn changes keep controls and clocks in place', (
    tester,
  ) async {
    final gate = Completer<void>();
    final store = GameDraftController(
      LocalGameDraftRepository(
        read: () async => null,
        write: (_) => gate.future,
        remove: () async {},
      ),
    );
    final dependencies = services(gameDraft: store);
    await dependencies.boardAppearance.update(view: BoardViewMode.flat);
    tester.view.physicalSize = const Size(320, 1200);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ChessApp(services: dependencies, initialLocation: '/game'),
    );
    await tester.pumpAndSettle();
    final whiteClockBefore = tester
        .getCenter(find.byKey(const ValueKey('clock-white')))
        .dx;
    final blackClockBefore = tester
        .getCenter(find.byKey(const ValueKey('clock-black')))
        .dx;
    await tester.tap(find.byKey(const ValueKey('square-e2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('square-e4')));
    await tester.pumpAndSettle();
    expect(store.isSaving, isTrue);
    final savingPosition = tester.getTopLeft(
      find.byKey(const ValueKey('pause-local-game')),
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('clock-white'))).dx,
      whiteClockBefore,
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('clock-black'))).dx,
      blackClockBefore,
    );
    gate.complete();
    await tester.pumpAndSettle();
    expect(store.isSaving, isFalse);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('pause-local-game'))),
      savingPosition,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('fast computer replies wait for the preceding 3D move', (
    tester,
  ) async {
    final dependencies = services(
      computerMove: (_, _) async => {
        'from': 'e7',
        'to': 'e5',
        'promotion': 'q',
      },
    );
    await dependencies.boardAppearance.update(
      view: BoardViewMode.table3d,
      board: BoardStyle.candy,
    );
    await tester.pumpWidget(
      ChessApp(
        services: dependencies,
        initialLocation: '/game?clock=off&opponent=computer',
      ),
    );
    await tester.pumpAndSettle();
    final board = tester.widget<ChessBoard>(find.byType(ChessBoard));
    final game = board.controller as GameController;
    final rect = tester.getRect(find.byKey(const ValueKey('board-3d')));
    final projection = BoardProjection(rect.size, BoardCamera.balanced);
    await tester.tapAt(
      rect.topLeft + projection.project(projection.center('e2', height: .67)),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(
      rect.topLeft + projection.project(projection.center('e4')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(game.rules.history, ['e4']);
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();
    expect(game.rules.history, ['e4', 'e5']);
    expect(game.selected, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final enabled in [false, true]) {
    test(
      'turn, last move and selection publish atomically (clock=$enabled)',
      () {
        final game = GameController(LocalChessRules(), clockEnabled: enabled);
        addTearDown(game.dispose);
        game.selectOrMove('e2');
        final frames =
            <
              ({
                bool white,
                bool clockWhite,
                String? from,
                String? to,
                String? selected,
              })
            >[];
        game.addListener(
          () => frames.add((
            white: game.rules.whiteToMove,
            clockWhite: game.clock.activeWhite,
            from: game.lastFrom,
            to: game.lastTo,
            selected: game.selected,
          )),
        );
        expect(game.selectOrMove('e4'), isTrue);
        expect(frames, [
          (
            white: false,
            clockWhite: false,
            from: 'e2',
            to: 'e4',
            selected: null,
          ),
        ]);
        frames.clear();
        expect(game.playMove('e7', 'e5'), isTrue);
        expect(frames, [
          (white: true, clockWhite: true, from: 'e7', to: 'e5', selected: null),
        ]);
        frames.clear();
        game.undo();
        expect(frames, [
          (
            white: false,
            clockWhite: false,
            from: null,
            to: null,
            selected: null,
          ),
        ]);
        frames.clear();
        game.reset();
        expect(frames, [
          (white: true, clockWhite: true, from: null, to: null, selected: null),
        ]);
        frames.clear();
        expect(game.playMove('e2', 'e5'), isFalse);
        expect(frames, isEmpty);
      },
    );
  }

  for (final view in [
    BoardViewMode.flat,
    BoardViewMode.overhead,
    BoardViewMode.table3d,
  ]) {
    testWidgets(
      'move hints can hide and restore without changing legal play: $view',
      (tester) async {
        final game = GameController(LocalChessRules());
        var appearance = BoardAppearance(
          view: view,
          board: BoardStyle.candy,
          showLegalMoves: true,
        );
        Future<void> pump() async {
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
        }

        Future<void> tap(String square) async {
          if (view == BoardViewMode.table3d) {
            final origin = tester.getTopLeft(
              find.byKey(const ValueKey('board-3d')),
            );
            final projection = BoardProjection(
              const Size(360, 360),
              appearance.camera,
            );
            await tester.tapAt(
              origin + projection.project(projection.center(square)),
            );
          } else if (view == BoardViewMode.wizard3d) {
            final boardWidget = tester.widget<ChessBoard>(find.byType(ChessBoard));
            boardWidget.onSquareTap?.call(square);
          } else {
            await tester.tap(find.byKey(ValueKey('square-$square')));
          }
          await tester.pumpAndSettle();
        }

        await pump();
        await tap('e2');
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics && w.properties.label == 'e4 boş, yasal hamle',
          ),
          findsOneWidget,
        );
        appearance = appearance.copyWith(showLegalMoves: false);
        await pump();
        expect(game.selected, 'e2');
        expect(game.targets, contains('e4'));
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                (w.properties.label?.contains('yasal hamle') ?? false),
          ),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('legal-target-e4')), findsNothing);
        appearance = appearance.copyWith(showLegalMoves: true);
        await pump();
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics && w.properties.label == 'e4 boş, yasal hamle',
          ),
          findsOneWidget,
        );
        appearance = appearance.copyWith(showLegalMoves: false);
        await pump();
        await tap('e4');
        expect(game.rules.history, ['e4']);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        game.dispose();
      },
    );
  }

  testWidgets(
    'below-board switch persists and reopens off without clearing a game',
    (tester) async {
      final dependencies = services();
      await dependencies.boardAppearance.update(
        view: BoardViewMode.flat,
        showLegalMoves: true,
      );
      expect(dependencies.boardAppearance.value.showLegalMoves, isTrue);
      await dependencies.boardAppearance.update(showLegalMoves: false);
      expect(dependencies.boardAppearance.value.showLegalMoves, isFalse);
      await dependencies.boardAppearance.load();
      expect(dependencies.boardAppearance.value.showLegalMoves, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'class aggregates are school-scoped; own rank uses identity and can be found',
    (tester) async {
      final dependencies = services(leaderboard: IdentityRankings());
      await dependencies.membership.save(schoolMembership());
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ChessApp(services: dependencies, initialLocation: '/leaderboard'),
      );
      await tester.pumpAndSettle();
      Future<void> tap(String key) async {
        final f = find.byKey(ValueKey(key));
        await tester.ensureVisible(f);
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      await tap('ranking-school');
      await tap('ranking-community-gfl');
      await tap('ranking-school-classes');
      expect(find.byKey(const ValueKey('ranking-class-gl-9a')), findsNothing);
      expect(find.text('Sen 2. sıradasın'), findsNothing);
      final b = tester
          .getTopLeft(find.byKey(const ValueKey('ranking-class-gfl-9b')))
          .dy;
      final a = tester
          .getTopLeft(find.byKey(const ValueKey('ranking-class-gfl-9a')))
          .dy;
      expect(
        b,
        lessThan(a),
        reason: '2000-point class precedes the 1700-point class',
      );
      await tap('ranking-class-gfl-9a');
      expect(find.text('Sen 2. sıradasın'), findsOneWidget);
      expect(find.text('Ada · Sen'), findsOneWidget);
      expect(find.text('Diğer okul'), findsNothing);
      expect(find.text('Ece'), findsNothing);
      await tap('ranking-find-me');
      expect(find.text('Ada · Sen').hitTestable(), findsOneWidget);
      await tap('ranking-back-to-list');
      expect(
        find.byKey(const ValueKey('ranking-class-gfl-9a')),
        findsOneWidget,
      );
      await tap('ranking-school');
      await tap('ranking-community-gl');
      await tap('ranking-school-classes');
      expect(find.byKey(const ValueKey('ranking-class-gfl-9a')), findsNothing);
      await tap('ranking-class-gl-9a');
      expect(find.text('Diğer okul'), findsOneWidget);
      expect(find.text('Ada · Sen'), findsNothing);
      await tap('ranking-my-community');
      expect(find.text('Sen 2. sıradasın'), findsOneWidget);
      expect(
        (tester.widget<Text>(find.byKey(const ValueKey('ranking-path')))).data,
        'Türkiye › Giresun › Giresun Fen Lisesi › 9-A',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'demo rankings never assign the guest a fictitious personal rank',
    (tester) async {
      final dependencies = services();
      await dependencies.membership.save(schoolMembership());
      await tester.pumpWidget(
        ChessApp(services: dependencies, initialLocation: '/leaderboard'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ranking-my-community')));
      await tester.pumpAndSettle();
      expect(find.text('Sıralaman henüz oluşmadı'), findsOneWidget);
      expect(
        find.text('Örnek listede kişisel puanın yer almıyor.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('ranking-find-me')), findsNothing);
      expect(find.text('Mert Y.'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
