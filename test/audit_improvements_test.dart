import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:chess_platform/app/app_services.dart';
import 'package:chess_platform/app/chess_app.dart';
import 'package:chess_platform/features/challenges/data/whatsapp_share_service.dart';
import 'package:chess_platform/features/challenges/domain/challenge_invite.dart';
import 'package:chess_platform/features/challenges/domain/online_challenge_repository.dart';
import 'package:chess_platform/features/game/data/local_chess_rules.dart';
import 'package:chess_platform/features/game/data/local_computer_player.dart';
import 'package:chess_platform/features/game/data/local_game_draft_repository.dart';
import 'package:chess_platform/features/game/domain/game_draft.dart';
import 'package:chess_platform/features/game/domain/game_result.dart';
import 'package:chess_platform/features/game/domain/match_repository.dart';
import 'package:chess_platform/features/game/domain/match_snapshot.dart';
import 'package:chess_platform/features/game/domain/saved_game.dart';
import 'package:chess_platform/features/game/domain/time_control.dart';
import 'package:chess_platform/features/game/presentation/game_controller.dart';
import 'package:chess_platform/features/game/presentation/game_draft_controller.dart';
import 'package:chess_platform/features/game/presentation/online_game_controller.dart';
import 'package:chess_platform/features/game/presentation/widgets/chess_board.dart';
import 'package:chess_platform/features/leaderboard/data/demo_leaderboard_repository.dart';
import 'package:chess_platform/features/profile/data/local_community_membership_repository.dart';
import 'package:chess_platform/features/profile/domain/community_membership.dart';
import 'package:chess_platform/features/profile/domain/guest_profile.dart';
import 'package:chess_platform/features/profile/presentation/community_membership_controller.dart';
import 'package:chess_platform/features/profile/presentation/profile_controller.dart';
import 'package:chess_platform/features/safety/domain/safety_repository.dart';
import 'package:chess_platform/features/safety/presentation/safety_preferences_controller.dart';
import 'package:chess_platform/features/settings/domain/board_appearance.dart';
import 'package:chess_platform/features/settings/presentation/board_appearance_controller.dart';
import 'package:chess_platform/features/settings/presentation/theme_controller.dart';

import 'game_presentation_test.dart' show tapKey;
import 'match_actions_test.dart' show SocialMatches;
import 'widget_test.dart'
    show
        MemoryGuestProfile,
        MemorySafetyPreferences,
        MemorySettings,
        memoryAppearance,
        memoryDraftRepository,
        memoryHistory,
        services;

class FakeSafetyRepository implements SafetyRepository {
  final blockedIds = <String>[];
  final reports = <({String playerId, String reason, String? matchId})>[];

  @override
  Future<void> blockPlayer(String playerId) async {
    blockedIds.add(playerId);
  }

  @override
  Future<void> reportPlayer({
    required String playerId,
    required String reason,
    String? matchId,
  }) async {
    reports.add((playerId: playerId, reason: reason, matchId: matchId));
  }
}

class FakeOnlineChallenges implements OnlineChallengeRepository {
  FakeOnlineChallenges(this.summaries);

  final List<OnlineMatchSummary> summaries;
  TimeControl? lastCreatedTime;

  @override
  bool get isLocalDemo => false;

  @override
  Future<ChallengeInvite> create(TimeControl timeControl) async {
    lastCreatedTime = timeControl;
    return ChallengeInvite(
      id: '0123456789abcdef0123456789abcdef01234567',
      timeControl: timeControl,
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );
  }

  @override
  Future<ChallengeInvite?> find(String id) async => null;

  @override
  Future<String> accept(String inviteId) async => 'match-1';

  @override
  Stream<String?> watchMatch(String inviteId) => const Stream.empty();

  @override
  Future<List<String>> recentMatches() async =>
      summaries.map((item) => item.id).toList();

  @override
  Future<List<OnlineMatchSummary>> recentMatchSummaries() async => summaries;

  @override
  Future<void> deleteOnlineData() async {}
}

class RealtimeSocialMatches extends SocialMatches
    implements RealtimeMatchRepository {
  int fetchCalls = 0;
  List<String> sanMoves = const [];
  String customFen = LocalChessRules().fen;
  bool customWhiteToMove = true;

  @override
  MatchSnapshot get snapshot {
    final base = super.snapshot;
    return MatchSnapshot(
      id: base.id,
      status: base.status,
      fen: customFen,
      ply: sanMoves.length,
      whiteToMove: customWhiteToMove,
      players: base.players,
      clocks: base.clocks,
      updatedAt: base.updatedAt,
      sanHistory: sanMoves,
      result: base.result,
      timeoutReason: base.timeoutReason,
      turnRemainingMilliseconds: base.turnRemainingMilliseconds,
      interactions: base.interactions,
    );
  }

  @override
  Future<MatchSnapshot> fetch(String matchId) async {
    fetchCalls++;
    return snapshot;
  }
}

void main() {
  test('Turkish classroom section letters resolve cleanly', () {
    final classroom = CommunityDirectory.classroomFor('gfl', 9, 'Ç');
    expect(classroom.id, 'class:gfl:9:Ç');
    expect(classroom.name, '9-Ç');
    final membership = CommunityMembership()
        .select(CommunityKind.country, 'tr')
        .select(CommunityKind.city, 'giresun')
        .select(CommunityKind.school, 'gfl')
        .select(CommunityKind.classroom, classroom.id);
    expect(
      membership.path,
      'Türkiye › Giresun › Giresun Fen Lisesi › 9-Ç',
    );
  });

  test('local resignation ends game, stops clock and survives restore', () {
    final game = GameController(LocalChessRules(), clockEnabled: true);
    expect(game.playMove('e2', 'e4'), isTrue);
    expect(game.resign(white: true), isTrue);
    expect(game.rules.isOver, isTrue);
    expect(game.rules.resigned, isTrue);
    expect(game.rules.result, GameResult.blackWins);
    expect(game.clock.hasEnded, isTrue);

    final draft = GameDraft(
      game: SavedGame(
        id: '0123456789abcdef0123456789abcdef',
        savedAt: DateTime.now(),
        initialFen: LocalChessRules().fen,
        moves: game.rules.history,
        timeControl: const TimeControl(10, 0),
        clockEnabled: true,
        result: GameResult.blackWins,
        resigned: true,
      ),
      clock: game.clock.exportState(),
      flipped: false,
    );
    final restored = GameController.restore(GameDraft.fromJson(draft.toJson()));
    expect(restored.rules.resigned, isTrue);
    expect(restored.rules.result, GameResult.blackWins);
    expect(restored.clock.hasEnded, isTrue);
    game.dispose();
    restored.dispose();
  });

  test('OnlineGameController replays SAN history for threefold repetition', () async {
    final replay = LocalChessRules();
    const moves = [
      'Nf3',
      'Nf6',
      'Ng1',
      'Ng8',
      'Nf3',
      'Nf6',
      'Ng1',
      'Ng8',
    ];
    for (final san in moves) {
      var moved = false;
      for (var r = 0; r < 8 && !moved; r++) {
        for (var c = 0; c < 8 && !moved; c++) {
          final from = '${String.fromCharCode(97 + c)}${8 - r}';
          for (final to in replay.destinations(from)) {
            final probe = LocalChessRules.fromHistory(
              initialFen: LocalChessRules().fen,
              moves: replay.history,
            );
            if (probe.move(from, to) && probe.history.last == san) {
              replay.move(from, to);
              moved = true;
              break;
            }
          }
        }
      }
    }
    final repo = RealtimeSocialMatches()
      ..sanMoves = moves
      ..customFen = replay.fen
      ..customWhiteToMove = replay.whiteToMove;
    final controller = OnlineGameController(repo, 'fixture');
    await controller.load();
    expect(controller.rules.isOver, isTrue);
    expect(controller.rules.result, GameResult.draw);
    controller.dispose();
    await repo.events.close();
  });

  testWidgets('flat board supports drag-and-drop, check highlight and material strip', (
    tester,
  ) async {
    final deps = services();
    await deps.boardAppearance.update(view: BoardViewMode.flat);
    await tester.pumpWidget(
      ChessApp(services: deps, initialLocation: '/game?clock=off'),
    );
    await tester.pumpAndSettle();

    // Drag e2 to e4
    final e2 = tester.getCenter(find.byKey(const ValueKey('square-e2')));
    final e4 = tester.getCenter(find.byKey(const ValueKey('square-e4')));
    await tester.timedDragFrom(
      e2,
      e4 - e2,
      const Duration(milliseconds: 120),
    );
    await tester.pumpAndSettle();

    final controller =
        tester.widget<ChessBoard>(find.byType(ChessBoard)).controller
            as GameController;
    expect(controller.rules.history, ['e4']);

    // Continue to a capture and check: 1...d5 2.exd5 Qxd5 3.Bb5+
    expect(controller.playMove('d7', 'd5'), isTrue);
    expect(controller.playMove('e4', 'd5'), isTrue);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('captured-white')), findsOneWidget);
    expect(find.textContaining('+1'), findsOneWidget);

    expect(controller.playMove('f7', 'f6'), isTrue);
    expect(controller.playMove('d1', 'h5'), isTrue);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('checked-square-e8')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('playing as Black against computer flips board and lets computer start', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final deps = services(
      computerMove: (_, _) async => {'from': 'e2', 'to': 'e4', 'promotion': 'q'},
    );
    await deps.boardAppearance.update(view: BoardViewMode.flat);
    await tester.pumpWidget(
      ChessApp(services: deps, initialLocation: '/play'),
    );
    await tester.pumpAndSettle();

    await tapKey(tester, 'side-black');
    await tapKey(tester, 'start-computer-game');
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();

    final controller =
        tester.widget<ChessBoard>(find.byType(ChessBoard)).controller
            as GameController;
    expect(controller.flipped, isTrue);
    expect(controller.rules.history, ['e4']);
    expect(find.text('Senin sıran'), findsOneWidget);

    // Resign as Black
    await tapKey(tester, 'resign-game');
    await tapKey(tester, 'confirm-resign');
    expect(find.textContaining('Bilgisayar kazandı'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('online match skips 4s polling when realtime, supports resign, PGN copy and safety menu', (
    tester,
  ) async {
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText = (call.arguments as Map)['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    final repo = RealtimeSocialMatches()
      ..sanMoves = const ['e4', 'e5']
      ..customFen =
          'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2';
    final safety = FakeSafetyRepository();
    final appearance = BoardAppearanceController(memoryAppearance());
    await appearance.update(view: BoardViewMode.flat);

    final deps = AppServices(
      matches: repo,
      safety: safety,
      leaderboard: const DemoLeaderboardRepository(),
      computerMove: requestComputerMove,
      membership: CommunityMembershipController(
        LocalCommunityMembershipRepository(
          read: () async => null,
          write: (_) async {},
        ),
      ),
      boardAppearance: appearance,
      gameHistory: memoryHistory(),
      gameDraft: GameDraftController(
        LocalGameDraftRepository(
          read: () async => null,
          write: (_) async {},
          remove: () async {},
        ),
      ),
      theme: ThemeController(MemorySettings()),
      challenges: FakeOnlineChallenges(const []),
      whatsApp: WhatsAppShareService(),
      profile: ProfileController(
        MemoryGuestProfile(),
        initialProfile: const GuestProfile(
          installId: 'local-test',
          displayName: 'Oyuncu',
        ),
      ),
      safetyPreferences: SafetyPreferencesController(MemorySafetyPreferences()),
    );

    await tester.pumpWidget(
      ChessApp(services: deps, initialLocation: '/online-match/fixture'),
    );
    await tester.pumpAndSettle();
    expect(repo.fetchCalls, 1);

    // 8 seconds pass without redundant 4s polling reads on RealtimeMatchRepository
    await tester.pump(const Duration(seconds: 8));
    expect(repo.fetchCalls, 1);

    // Copy online PGN
    await tapKey(tester, 'copy-online-pgn');
    expect(copiedText, contains('1. e4 e5'));

    // Report and block opponent via safety menu
    await tapKey(tester, 'online-match-menu');
    await tester.tap(find.text('Oyuncuyu bildir'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'confirm-report-opponent');
    expect(safety.reports.single.matchId, 'fixture');

    await tapKey(tester, 'online-match-menu');
    await tester.tap(find.text('Oyuncuyu engelle'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'confirm-block-opponent');
    expect(safety.blockedIds, isNotEmpty);

    // Resign online match
    await tapKey(tester, 'resign-game');
    await tapKey(tester, 'confirm-resign');
    expect(
      find.text('Beyaz oyunu terk etti · Siyah kazandı'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await repo.events.close();
    expect(tester.takeException(), isNull);
  });

  testWidgets('online games screen shows rich match summaries and challenge screen offers increment presets', (
    tester,
  ) async {
    final challenges = FakeOnlineChallenges([
      OnlineMatchSummary(
        id: 'abcdef1234567890',
        timeControl: const TimeControl(5, 3),
        status: MatchStatus.active,
        playerColor: MatchColor.black,
        isMyTurn: true,
        ply: 14,
        updatedAt: DateTime(2026, 11, 4, 15, 30),
        statusLabel: 'Hamle sırası sende',
      ),
    ]);
    SharedPreferences.setMockInitialValues({'onlineConsent.v2': true});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await SharedPreferencesAsync().setBool('onlineConsent.v2', true);

    final deps = AppServices(
      leaderboard: const DemoLeaderboardRepository(),
      computerMove: requestComputerMove,
      membership: CommunityMembershipController(
        LocalCommunityMembershipRepository(
          read: () async => null,
          write: (_) async {},
        ),
      ),
      boardAppearance: BoardAppearanceController(memoryAppearance()),
      gameHistory: memoryHistory(),
      gameDraft: GameDraftController(memoryDraftRepository()),
      theme: ThemeController(MemorySettings()),
      challenges: challenges,
      whatsApp: WhatsAppShareService(),
      profile: ProfileController(
        MemoryGuestProfile(),
        initialProfile: const GuestProfile(
          installId: 'local-test',
          displayName: 'Oyuncu',
        ),
      ),
      safetyPreferences: SafetyPreferencesController(MemorySafetyPreferences()),
    );

    await tester.pumpWidget(
      ChessApp(services: deps, initialLocation: '/online-games'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hamle sırası sende'), findsOneWidget);
    expect(find.textContaining('Siyah · 5 + 3 · 14 yarım hamle'), findsOneWidget);
    expect(find.text('Maç abcdef12'), findsOneWidget);

    await tester.pumpWidget(
      ChessApp(
        key: const ValueKey('challenges-app'),
        services: deps,
        initialLocation: '/challenges',
      ),
    );
    await tester.pumpAndSettle();
    await tapKey(tester, 'challenge-more-time-controls');
    await tapKey(tester, 'challenge-time-15-10');
    await tapKey(tester, 'create-invite');
    expect(challenges.lastCreatedTime, const TimeControl(15, 10));

    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
