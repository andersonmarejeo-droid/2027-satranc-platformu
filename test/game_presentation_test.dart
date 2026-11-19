import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_platform/app/chess_app.dart';
import 'package:chess_platform/core/platform/game_device.dart';
import 'package:chess_platform/features/game/data/local_chess_rules.dart';
import 'package:chess_platform/features/game/domain/match_repository.dart';
import 'package:chess_platform/features/game/domain/match_snapshot.dart';
import 'package:chess_platform/features/game/domain/match_stream_event.dart';
import 'package:chess_platform/features/game/presentation/game_controller.dart';
import 'package:chess_platform/features/game/presentation/widgets/chess_board.dart';
import 'package:chess_platform/features/settings/domain/board_appearance.dart';

import 'widget_test.dart' show services;

Future<void> tapKey(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

List<MethodCall> deviceCalls(WidgetTester tester) {
  final calls = <MethodCall>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    GameDevice.channel,
    (call) async {
      calls.add(call);
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      GameDevice.channel,
      null,
    ),
  );
  return calls;
}

class TestMatches implements MatchRepository {
  final rules = LocalChessRules();
  String? lastMove;
  MatchSnapshot get snapshot => MatchSnapshot(
    id: 'fixture',
    status: MatchStatus.active,
    fen: rules.fen,
    ply: rules.history.length,
    whiteToMove: rules.whiteToMove,
    updatedAt: DateTime.utc(
      2026,
      10,
      3,
    ).add(Duration(seconds: rules.history.length)),
    lastMoveUci: lastMove,
    sanHistory: rules.history,
    players: const [
      MatchPlayer(id: 'white', displayName: 'Sen', color: MatchColor.white),
      MatchPlayer(id: 'black', displayName: 'Rakip', color: MatchColor.black),
    ],
    clocks: MatchClocks(
      whiteMilliseconds: 300000,
      blackMilliseconds: 300000,
      serverTime: DateTime.utc(2026, 10, 3),
    ),
  );
  @override
  Future<MatchSnapshot> fetch(String matchId) async => snapshot;
  @override
  Future<MatchSnapshot> submitMove(
    String matchId, {
    required int expectedPly,
    required String uci,
  }) async {
    if (expectedPly != rules.history.length ||
        !rules.move(uci.substring(0, 2), uci.substring(2, 4))) {
      throw StateError('Invalid fixture move');
    }
    lastMove = uci;
    return snapshot;
  }

  @override
  Future<MatchStreamTicket> createStreamTicket(String matchId) async =>
      throw UnimplementedError();
  @override
  Stream<MatchStreamEvent> watchEvents(
    String matchId, {
    required int afterSequence,
  }) => const Stream.empty();
}

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(320, 740),
    const Size(844, 390),
  ]) {
    testWidgets(
      'fullscreen keeps the game and back first exits focus at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final calls = deviceCalls(tester);
        final dependencies = services();
        await dependencies.boardAppearance.update(view: BoardViewMode.flat);
        await tester.pumpWidget(
          ChessApp(
            services: dependencies,
            initialLocation: '/game?minutes=5&increment=2',
          ),
        );
        await tester.pumpAndSettle();
        await tapKey(tester, 'square-e2');
        await tapKey(tester, 'square-e4');
        final game =
            tester.widget<ChessBoard>(find.byType(ChessBoard)).controller
                as GameController;
        final clock = game.clock;
        await tapKey(tester, 'game-fullscreen');
        expect(find.byKey(const ValueKey('focused-game')), findsOneWidget);
        expect(
          tester.widget<ChessBoard>(find.byType(ChessBoard)).controller,
          same(game),
        );
        expect(game.clock, same(clock));
        expect(game.rules.history, ['e4']);
        expect(game.clock.isPaused, isFalse);
        expect(
          calls.where((c) => c.method == 'fullscreen').last.arguments,
          true,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('focused-game')), findsNothing);
        expect(find.byType(ChessBoard), findsOneWidget);
        expect(game.clock.isPaused, isFalse);
        expect(game.rules.history, ['e4']);
        expect(
          calls.where((c) => c.method == 'fullscreen').last.arguments,
          false,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('resume-local-game')), findsOneWidget);
        expect(dependencies.gameDraft.draft!.game.moves, ['e4']);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'sound plays once per legal move and mute remains effective in fullscreen',
    (tester) async {
      final calls = deviceCalls(tester);
      final dependencies = services();
      await dependencies.boardAppearance.update(view: BoardViewMode.flat);
      await tester.pumpWidget(
        ChessApp(services: dependencies, initialLocation: '/game?clock=off'),
      );
      await tester.pumpAndSettle();
      await tapKey(tester, 'square-e2');
      expect(calls.where((c) => c.method == 'slideSound'), isEmpty);
      await tapKey(tester, 'square-e4');
      expect(calls.where((c) => c.method == 'slideSound').length, 1);
      await tapKey(tester, 'square-e7');
      await tapKey(tester, 'square-e4');
      expect(calls.where((c) => c.method == 'slideSound').length, 1);
      await tapKey(tester, 'game-sound');
      await tapKey(tester, 'square-e7');
      await tapKey(tester, 'square-e5');
      expect(calls.where((c) => c.method == 'slideSound').length, 1);
      await tapKey(tester, 'game-fullscreen');
      await tapKey(tester, 'focused-game-sound');
      await tapKey(tester, 'square-g1');
      await tapKey(tester, 'square-f3');
      expect(calls.where((c) => c.method == 'slideSound').length, 2);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(
        calls.where((c) => c.method == 'fullscreen').last.arguments,
        false,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final view in [BoardViewMode.flat, BoardViewMode.overhead]) {
    testWidgets(
      '$view shows a moving piece midway, including a flipped board',
      (tester) async {
        final game = GameController(LocalChessRules(), clockEnabled: false)
          ..flip();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  height: 360,
                  child: ListenableBuilder(
                    listenable: game,
                    builder: (_, _) => ChessBoard(
                      controller: game,
                      appearance: BoardAppearance(
                        view: view,
                        board: BoardStyle.candy,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final from = tester.getCenter(find.byKey(const ValueKey('square-e2')));
        final to = tester.getCenter(find.byKey(const ValueKey('square-e4')));
        game.playMove('e2', 'e4');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 190));
        final moving = tester.getCenter(
          find.byKey(const ValueKey('moving-piece')),
        );
        expect(moving.dx, closeTo((from.dx + to.dx) / 2, .1));
        expect(
          (moving.dy - from.dy).abs() / (to.dy - from.dy).abs(),
          inExclusiveRange(.25, .75),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('moving-piece')), findsNothing);
        expect(game.rules.pieceAt('e4')?.type, 'p');
        await tester.pumpWidget(const SizedBox.shrink());
        game.dispose();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('reduced motion places the piece without sliding', (
    tester,
  ) async {
    final game = GameController(LocalChessRules(), clockEnabled: false);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: ListenableBuilder(
              listenable: game,
              builder: (_, _) => ChessBoard(
                controller: game,
                appearance: const BoardAppearance(view: BoardViewMode.flat),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    game.playMove('e2', 'e4');
    await tester.pump();
    expect(find.byKey(const ValueKey('moving-piece')), findsNothing);
    expect(game.rules.pieceAt('e4')?.type, 'p');
    await tester.pumpWidget(const SizedBox.shrink());
    game.dispose();
  });

  testWidgets('quick computer reply has a pause and a visible arrival in 2D', (
    tester,
  ) async {
    deviceCalls(tester);
    final dependencies = services(
      computerMove: (_, _) async => {'from': 'e7', 'to': 'e5'},
    );
    await dependencies.boardAppearance.update(view: BoardViewMode.flat);
    await tester.pumpWidget(
      ChessApp(
        services: dependencies,
        initialLocation: '/game?clock=off&opponent=computer',
      ),
    );
    await tester.pumpAndSettle();
    await tapKey(tester, 'square-e2');
    await tapKey(tester, 'square-e4');
    final game =
        tester.widget<ChessBoard>(find.byType(ChessBoard)).controller
            as GameController;
    expect(game.rules.history, ['e4']);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(game.rules.history, ['e4', 'e5']);
    expect(find.byKey(const ValueKey('moving-piece')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 190));
    expect(find.byKey(const ValueKey('moving-piece')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('moving-piece')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'online focus and sound preserve server position and remote slide',
    (tester) async {
      final calls = deviceCalls(tester);
      final repository = TestMatches();
      final dependencies = services(matches: repository);
      await dependencies.boardAppearance.update(view: BoardViewMode.flat);
      await tester.pumpWidget(
        ChessApp(
          services: dependencies,
          initialLocation: '/online-match/fixture',
        ),
      );
      await tester.pumpAndSettle();
      expect(calls.where((c) => c.method == 'slideSound'), isEmpty);
      await tapKey(tester, 'game-fullscreen');
      await tapKey(tester, 'square-e2');
      await tapKey(tester, 'square-e4');
      expect(repository.rules.history, ['e4']);
      expect(calls.where((c) => c.method == 'slideSound').length, 1);
      repository.rules.move('e7', 'e5');
      repository.lastMove = 'e7e5';
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 190));
      expect(find.byKey(const ValueKey('moving-piece')), findsOneWidget);
      expect(calls.where((c) => c.method == 'slideSound').length, 2);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('focused-game')), findsNothing);
      expect(find.byType(ChessBoard), findsOneWidget);
      expect(repository.rules.history, ['e4', 'e5']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
