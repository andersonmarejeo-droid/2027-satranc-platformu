import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_platform/app/chess_app.dart';
import 'package:chess_platform/core/theme/app_theme.dart';
import 'package:chess_platform/core/networking/api_client.dart';
import 'package:chess_platform/features/game/data/local_chess_rules.dart';
import 'package:chess_platform/features/game/domain/game_draft.dart';
import 'package:chess_platform/features/game/domain/game_result.dart';
import 'package:chess_platform/features/game/domain/match_interactions.dart';
import 'package:chess_platform/features/game/domain/match_snapshot.dart';
import 'package:chess_platform/features/game/domain/online_match_timing.dart';
import 'package:chess_platform/features/game/domain/match_stream_event.dart';
import 'package:chess_platform/features/game/domain/saved_game.dart';
import 'package:chess_platform/features/game/domain/time_control.dart';
import 'package:chess_platform/features/game/presentation/game_controller.dart';
import 'package:chess_platform/features/game/presentation/online_game_controller.dart';
import 'package:chess_platform/features/game/presentation/widgets/chess_board.dart';
import 'package:chess_platform/features/settings/domain/board_appearance.dart';
import 'package:chess_platform/features/settings/presentation/theme_controller.dart';

import 'widget_test.dart' show services, MemorySettings;
import 'game_presentation_test.dart' show TestMatches, tapKey;

class SocialMatches extends TestMatches implements MatchSocialRepository {
  final events = StreamController<MatchStreamEvent>.broadcast();
  MatchInteractions interactions = const MatchInteractions();
  int revision = 0;
  bool completed = false;
  int? turnRemainingMilliseconds;
  MatchTimeoutReason? timeoutReason;
  @override
  String get playerId => 'white';
  @override
  MatchSnapshot get snapshot {
    final base = super.snapshot;
    return MatchSnapshot(
      id: base.id,
      status: completed ? MatchStatus.completed : MatchStatus.active,
      fen: base.fen,
      ply: base.ply,
      whiteToMove: base.whiteToMove,
      players: base.players,
      clocks: base.clocks,
      updatedAt: base.updatedAt.add(Duration(milliseconds: revision)),
      result: completed
          ? (interactions.resignedBy != null
                ? (interactions.resignedBy == 'white'
                      ? MatchResult.black
                      : MatchResult.white)
                : timeoutReason == MatchTimeoutReason.inactivity
                ? MatchResult.black
                : MatchResult.draw)
          : null,
      timeoutReason: timeoutReason,
      turnRemainingMilliseconds: turnRemainingMilliseconds,
      interactions: interactions,
    );
  }

  void publish(MatchInteractions next, {bool end = false}) {
    interactions = next;
    completed = end || completed;
    events.add(
      MatchStreamEvent(
        type: 'match.snapshot',
        matchId: 'fixture',
        sequence: ++revision,
        serverTime: snapshot.updatedAt,
        payload: const {},
      ),
    );
  }

  @override
  Stream<MatchStreamEvent> watchEvents(
    String matchId, {
    required int afterSequence,
  }) => events.stream;
  @override
  Future<MatchSnapshot> offerDraw(String matchId) async {
    publish(const MatchInteractions(drawOfferedBy: 'white', drawOfferPly: 0));
    return snapshot;
  }

  @override
  Future<MatchSnapshot> respondToDraw(
    String matchId, {
    required bool accept,
  }) async {
    publish(MatchInteractions(drawAccepted: accept), end: accept);
    return snapshot;
  }

  @override
  Future<MatchSnapshot> resign(String matchId) async {
    publish(MatchInteractions(resignedBy: playerId), end: true);
    return snapshot;
  }

  @override
  Future<MatchSnapshot> requestRematch(String matchId) async {
    publish(
      MatchInteractions(
        rematchOfferedBy: 'white',
        rematchInviteId: 'new',
        messages: interactions.messages,
      ),
    );
    return snapshot;
  }

  @override
  Future<String> acceptRematch(String matchId) async => 'new';
  @override
  Future<MatchSnapshot> sendQuickMessage(
    String matchId,
    QuickMessageCode code,
  ) async {
    publish(
      MatchInteractions(
        messages: [
          ...interactions.messages,
          MatchQuickMessage(
            senderId: playerId,
            code: code,
            sentAt: DateTime.now(),
          ),
        ],
      ),
    );
    return snapshot;
  }
}

class ExpiringMatches extends SocialMatches {
  @override
  Future<MatchSnapshot> submitMove(
    String matchId, {
    required int expectedPly,
    required String uci,
  }) async {
    completed = true;
    timeoutReason = MatchTimeoutReason.inactivity;
    turnRemainingMilliseconds = 0;
    throw const ApiFailure(
      'Maç sona erdi.',
      kind: ApiFailureKind.http,
      statusCode: 409,
    );
  }
}

void main() {
  test('a move reaching an expired match refreshes the outcome without retry advice', () async {
    final repo = ExpiringMatches()..turnRemainingMilliseconds = 180000;
    final controller = OnlineGameController(repo, 'fixture');
    await controller.load();
    await controller.submitMove('e2', 'e4');
    expect(controller.snapshot!.status, MatchStatus.completed);
    expect(controller.snapshot!.result, MatchResult.black);
    expect(controller.error, isNull);
    controller.dispose();
    await repo.events.close();
  });

  testWidgets('online turn countdown ends with the correct inactivity winner', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = SocialMatches()..turnRemainingMilliseconds = 180000;
    final deps = services(matches: repo);
    await deps.boardAppearance.update(view: BoardViewMode.flat);
    await tester.pumpWidget(
      ChessApp(services: deps, initialLocation: '/online-match/fixture'),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Bu hamle için kalan: 3:00'), findsOneWidget);
    repo.turnRemainingMilliseconds = 117000;
    repo.publish(const MatchInteractions());
    await tester.pumpAndSettle();
    expect(find.textContaining('Bu hamle için kalan: 1:57'), findsOneWidget);
    repo.timeoutReason = MatchTimeoutReason.inactivity;
    repo.turnRemainingMilliseconds = 0;
    repo.publish(const MatchInteractions(), end: true);
    await tester.pumpAndSettle();
    expect(
      find.text('3 dakika hamle yapılmadı · Siyah kazandı'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('online-turn-countdown')), findsNothing);
    expect(find.byKey(const ValueKey('offer-draw')), findsNothing);
    expect(find.byKey(const ValueKey('request-rematch')), findsOneWidget);
    final controller =
        tester.widget<ChessBoard>(find.byType(ChessBoard)).controller
            as OnlineGameController;
    controller.select('e2');
    expect(controller.selected, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await repo.events.close();
  });

  test('agreed draw freezes clocks, survives restoration and preserves legal rules', () {
    final game = GameController(LocalChessRules(), clockEnabled: true);
    expect(game.playMove('e2', 'e4'), isTrue);
    expect(game.agreeDraw(), isTrue);
    expect(game.rules.result, GameResult.draw);
    expect(game.playMove('e7', 'e5'), isFalse);
    final draft = GameDraft(
      game: SavedGame(
        id: '0123456789abcdef0123456789abcdef',
        savedAt: DateTime.now(),
        initialFen: LocalChessRules().fen,
        moves: game.rules.history,
        timeControl: const TimeControl(10, 0),
        clockEnabled: true,
        result: GameResult.draw,
        agreedDraw: true,
      ),
      clock: game.clock.exportState(),
      flipped: false,
      lastFrom: 'e2',
      lastTo: 'e4',
    );
    final restored = GameController.restore(GameDraft.fromJson(draft.toJson()));
    expect(restored.rules.agreedDraw, isTrue);
    expect(restored.clock.hasEnded, isTrue);
    restored.reset();
    expect(restored.rules.result, GameResult.unfinished);
    expect(restored.clock.hasEnded, isFalse);
    expect(restored.rules.history, isEmpty);
    game.dispose();
    restored.dispose();
    final pinned = LocalChessRules(fen: '4r1k1/8/8/8/8/8/4R3/4K3 w - - 0 1');
    expect(pinned.move('e2', 'd2'), isFalse);
  });

  test('fresh palette defaults, persists separately from brightness and migrates hints', () async {
    final memory = MemorySettings();
    final theme = ThemeController(memory);
    await theme.load();
    expect(theme.mode, ThemeMode.light);
    expect(theme.colorTheme, AppColorTheme.fresh);
    await theme.setColorTheme(AppColorTheme.forest);
    await theme.setMode(ThemeMode.dark);
    final reopened = ThemeController(memory);
    await reopened.load();
    expect(reopened.mode, ThemeMode.dark);
    expect(reopened.colorTheme, AppColorTheme.forest);
    final old = BoardAppearance.fromJson({
      ...const BoardAppearance().toJson(),
      'version': 1,
      'showLegalMoves': true,
      'board': 'blackWhite',
    });
    expect(old.showLegalMoves, isFalse);
    expect(old.board, BoardStyle.blackWhite);
    expect(const BoardAppearance().showLegalMoves, isFalse);
    expect(
      BoardAppearance.fromJson(
        const BoardAppearance(showLegalMoves: true).toJson(),
      ).showLegalMoves,
      isTrue,
    );
    final scheme = AppTheme.build(Brightness.light).colorScheme;
    final contrast =
        (scheme.onPrimary.computeLuminance() + .05) /
        (scheme.primary.computeLuminance() + .05);
    expect(contrast, greaterThanOrEqualTo(4.5));
    theme.dispose();
    reopened.dispose();
  });

  testWidgets('local draw, fixed message and rematch preserve previous game', (
    tester,
  ) async {
    final deps = services();
    await deps.boardAppearance.update(view: BoardViewMode.flat);
    await tester.pumpWidget(
      ChessApp(services: deps, initialLocation: '/game?clock=off'),
    );
    await tester.pumpAndSettle();
    await tapKey(tester, 'square-e2');
    await tapKey(tester, 'square-e4');
    await tapKey(tester, 'offer-draw');
    await tapKey(tester, 'accept-local-draw');
    expect(find.text('Anlaşmayla berabere'), findsOneWidget);
    if (find.byKey(const ValueKey('open-match-actions')).evaluate().isNotEmpty) {
      await tapKey(tester, 'open-match-actions');
    }
    await tapKey(tester, 'quick-message-wellPlayed');
    expect(find.text('İyi oynadın!'), findsNWidgets(2));
    await tester.tap(find.byKey(const ValueKey('request-rematch')).last);
    await tester.pumpAndSettle();
    final game =
        tester.widget<ChessBoard>(find.byType(ChessBoard)).controller
            as GameController;
    expect(game.rules.history, isEmpty);
    final saved = await deps.gameHistory.list();
    expect(saved.single.result, GameResult.draw);
    expect(saved.single.agreedDraw, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'online offers and end messages sync at the same ply with hints hidden',
    (tester) async {
      final repo = SocialMatches();
      final deps = services(matches: repo);
      await deps.boardAppearance.update(
        view: BoardViewMode.flat,
        showLegalMoves: true,
      );
      await tester.pumpWidget(
        ChessApp(services: deps, initialLocation: '/online-match/fixture'),
      );
      await tester.pumpAndSettle();
      final board = tester.widget<ChessBoard>(find.byType(ChessBoard));
      expect(board.allowMoveHints, isFalse);
      await tapKey(tester, 'offer-draw');
      expect(find.text('Beraberlik yanıtı bekleniyor'), findsOneWidget);
      repo.publish(
        const MatchInteractions(drawOfferedBy: 'black', drawOfferPly: 0),
      );
      await tester.pumpAndSettle();
      await tapKey(tester, 'decline-draw');
      expect(find.byKey(const ValueKey('offer-draw')), findsOneWidget);
      repo.publish(
        const MatchInteractions(drawOfferedBy: 'black', drawOfferPly: 0),
      );
      await tester.pumpAndSettle();
      await tapKey(tester, 'accept-draw');
      await tapKey(tester, 'quick-message-congratulations');
      expect(find.text('Sen · Tebrikler!'), findsOneWidget);
      repo.publish(
        MatchInteractions(
          drawAccepted: true,
          messages: [
            MatchQuickMessage(
              senderId: 'black',
              code: QuickMessageCode.wellPlayed,
              sentAt: DateTime.now(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rakibin · İyi oynadın!'), findsOneWidget);
      final controller = board.controller as OnlineGameController;
      expect(controller.snapshot!.ply, 0);
      await tapKey(tester, 'request-rematch');
      expect(find.textContaining('Rövanş teklifi gönderildi'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await repo.events.close();
      expect(tester.takeException(), isNull);
    },
  );
}
