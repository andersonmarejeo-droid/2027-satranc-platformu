import 'package:flutter/material.dart';
import 'package:chess_platform/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:chess_platform/features/leaderboard/data/demo_leaderboard_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_platform/app/app_services.dart';
import 'package:chess_platform/app/chess_app.dart';
import 'package:chess_platform/features/challenges/data/whatsapp_share_service.dart';
import 'package:chess_platform/features/challenges/domain/challenge_invite.dart';
import 'package:chess_platform/features/challenges/domain/challenge_repository.dart';
import 'package:chess_platform/features/game/domain/time_control.dart';
import 'package:chess_platform/features/game/domain/match_repository.dart';
import 'package:chess_platform/features/game/data/local_game_history_repository.dart';
import 'package:chess_platform/features/game/data/local_computer_player.dart';
import 'package:chess_platform/features/game/domain/game_history_repository.dart';
import 'package:chess_platform/features/game/domain/saved_game.dart';
import 'package:chess_platform/features/game/domain/computer_difficulty.dart';
import 'package:chess_platform/features/game/domain/game_result.dart';
import 'package:chess_platform/features/game/data/local_game_draft_repository.dart';
import 'package:chess_platform/features/game/presentation/game_draft_controller.dart';
import 'package:chess_platform/features/game/domain/game_draft_repository.dart';
import 'package:chess_platform/features/game/domain/game_draft.dart';
import 'package:chess_platform/features/game/domain/clock_state.dart';

import 'game_draft_test.dart' show draftFixture;

import 'package:chess_platform/features/settings/domain/settings_repository.dart';
import 'package:chess_platform/features/settings/presentation/theme_controller.dart';
import 'package:chess_platform/features/settings/data/local_board_appearance_repository.dart';
import 'package:chess_platform/features/settings/domain/board_appearance.dart';
import 'package:chess_platform/features/settings/presentation/board_appearance_controller.dart';
import 'package:chess_platform/features/profile/domain/guest_profile.dart';
import 'package:chess_platform/features/profile/domain/guest_profile_repository.dart';
import 'package:chess_platform/features/profile/presentation/profile_controller.dart';
import 'package:chess_platform/features/profile/presentation/community_membership_controller.dart';
import 'package:chess_platform/features/profile/data/local_community_membership_repository.dart';
import 'package:chess_platform/features/safety/domain/safety_preferences.dart';
import 'package:chess_platform/features/safety/domain/safety_preferences_repository.dart';
import 'package:chess_platform/features/safety/presentation/safety_preferences_controller.dart';

class MemorySettings implements SettingsRepository {
  String? theme;
  String? colorTheme;
  @override
  Future<String?> readTheme() async => theme;
  @override
  Future<void> saveTheme(String value) async {
    theme = value;
  }

  @override
  Future<String?> readColorTheme() async => colorTheme;
  @override
  Future<void> saveColorTheme(String value) async {
    colorTheme = value;
  }
}

class MemoryChallenges implements ChallengeRepository {
  final values = <String, ChallengeInvite>{};
  @override
  bool get isLocalDemo => true;

  @override
  Future<ChallengeInvite> create(TimeControl time) async {
    final invite = ChallengeInvite(
      id: '0123456789abcdef0123456789abcdef',
      timeControl: time,
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );
    values[invite.id] = invite;
    return invite;
  }

  @override
  Future<ChallengeInvite?> find(String id) async => values[id];
}

class MemoryGuestProfile implements GuestProfileRepository {
  GuestProfile value = const GuestProfile(
    installId: 'local-test-install',
    displayName: 'Misafir oyuncu',
  );

  @override
  Future<GuestProfile> loadOrCreate() async => value;

  @override
  Future<void> saveDisplayName(String displayName) async {
    value = value.copyWith(displayName: displayName);
  }
}

class MemorySafetyPreferences implements SafetyPreferencesRepository {
  SafetyPreferences value = const SafetyPreferences();

  @override
  Future<SafetyPreferences> load() async => value;

  @override
  Future<void> save(SafetyPreferences preferences) async {
    value = preferences;
  }
}

GameHistoryRepository memoryHistory() {
  String? stored;
  return LocalGameHistoryRepository(
    read: () async => stored,
    write: (value) async {
      stored = value;
    },
  );
}

SavedGame previewGame({
  List<String> moves = const ['e4', 'e5', 'Nf3', 'Nc6', 'Bc4', 'Bc5'],
}) => SavedGame(
  id: '0123456789abcdef0123456789abcdef',
  savedAt: DateTime(2026, 10, 3, 12, 30),
  initialFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
  moves: moves,
  timeControl: const TimeControl(10, 0),
  clockEnabled: false,
  result: GameResult.unfinished,
);

GameDraftRepository memoryDraftRepository() {
  String? stored;
  return LocalGameDraftRepository(
    read: () async => stored,
    write: (value) async {
      stored = value;
    },
    remove: () async {
      stored = null;
    },
  );
}

AppServices services({
  MatchRepository? matches,
  LeaderboardRepository? leaderboard,
  GameHistoryRepository? gameHistory,
  GameDraftController? gameDraft,
  BoardAppearanceController? boardAppearance,
  CommunityMembershipController? membership,
  Future<Map<String, String>?> Function(String, ComputerDifficulty)?
  computerMove,
}) => AppServices(
  matches: matches,
  leaderboard: leaderboard ?? const DemoLeaderboardRepository(),
  computerMove: computerMove ?? requestComputerMove,
  membership:
      membership ??
      CommunityMembershipController(
        LocalCommunityMembershipRepository(
          read: () async => null,
          write: (_) async {},
        ),
      ),
  boardAppearance:
      boardAppearance ??
      BoardAppearanceController(
        memoryAppearance(),
        initialValue: const BoardAppearance(view: BoardViewMode.flat),
      ),
  gameHistory: gameHistory ?? memoryHistory(),
  gameDraft: gameDraft ?? GameDraftController(memoryDraftRepository()),
  theme: ThemeController(MemorySettings()),
  challenges: MemoryChallenges(),
  whatsApp: WhatsAppShareService(),
  profile: ProfileController(
    MemoryGuestProfile(),
    initialProfile: const GuestProfile(
      installId: 'local-test-install',
      displayName: 'Misafir oyuncu',
    ),
  ),
  safetyPreferences: SafetyPreferencesController(MemorySafetyPreferences()),
);

BoardAppearanceRepository memoryAppearance() {
  String? stored =
      '{"version":2,"view":"flat","board":"candy","pieces":"staunton","camera":"balanced","shape":"classic","showLegalMoves":true}';
  return LocalBoardAppearanceRepository(
    read: () async => stored,
    write: (value) async {
      stored = value;
    },
  );
}

void main() {
  testWidgets(
    'background pauses, leaving preserves the game and a fresh app resumes it',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = memoryDraftRepository();
      final store = GameDraftController(repository);
      await tester.pumpWidget(
        ChessApp(
          services: services(gameDraft: store),
          initialLocation: '/game',
        ),
      );
      await tester.pumpAndSettle();
      for (final square in ['e2', 'e4', 'e7', 'e5']) {
        final target = find.byKey(ValueKey('square-$square'));
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }
      final id = store.draft!.game.id;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Devam et'), findsOneWidget);
      final clock = store.draft!.clock.toJson();
      await tester.pump(const Duration(seconds: 10));
      expect(store.draft!.clock.toJson(), clock);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Devam et'), findsOneWidget);
      for (final square in ['g1', 'f3']) {
        final target = find.byKey(ValueKey('square-$square'));
        await tester.ensureVisible(target);
        final detector = tester.widget<GestureDetector>(target);
        expect(detector.onTap, isNull);
      }
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('resume-local-game')), findsOneWidget);
      expect((await repository.load())!.game.moves, ['e4', 'e5']);
      await tester.pumpWidget(const SizedBox.shrink());
      final reopened = GameDraftController(repository);
      await reopened.load();
      await tester.pumpWidget(
        ChessApp(
          key: const ValueKey('reopened'),
          services: services(gameDraft: reopened),
          initialLocation: '/play',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('resume-local-game')));
      await tester.pumpAndSettle();
      expect(find.text('Beyazın sırası'), findsOneWidget);
      for (final square in ['g1', 'f3']) {
        final target = find.byKey(ValueKey('square-$square'));
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }
      expect(reopened.draft!.game.id, id);
      expect((await repository.load())!.game.moves, ['e4', 'e5', 'Nf3']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'new game requires confirming replacement of the resumable draft',
    (tester) async {
      final store = GameDraftController(
        memoryDraftRepository(),
        initialDraft: draftFixture(),
      );
      await tester.pumpWidget(
        ChessApp(
          services: services(gameDraft: store),
          initialLocation: '/play',
        ),
      );
      await tester.pumpAndSettle();
      final start = find.byKey(const ValueKey('start-game'));
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pumpAndSettle();
      expect(find.text('Yeni yerel oyun?'), findsOneWidget);
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(store.draft!.game.moves, ['e4', 'e5', 'Nf3']);
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yeni oyun'));
      await tester.pumpAndSettle();
      expect(find.text('İki kişilik oyun'), findsOneWidget);
      expect(store.draft, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('missing and inconsistent resumable games show a useful error', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChessApp(services: services(), initialLocation: '/game?resume=1'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kayıtlı tahta yok · Oyna ekranına dön'), findsOneWidget);
    final base = draftFixture();
    final wrong = GameDraft(
      game: base.game,
      flipped: false,
      clock: ClockState(
        position: ClockSnapshot(
          whiteMilliseconds: 180000,
          blackMilliseconds: 180000,
          activeWhite: !base.clock.position.activeWhite,
        ),
        flagged: false,
        endedByRules: false,
        undo: base.clock.undo,
      ),
    );
    await tester.pumpWidget(
      ChessApp(
        key: const ValueKey('invalid-resume'),
        services: services(
          gameDraft: GameDraftController(
            memoryDraftRepository(),
            initialDraft: wrong,
          ),
        ),
        initialLocation: '/game?resume=1',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tahta açılamadı.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('autosave failure is visible and retry keeps the played move', (
    tester,
  ) async {
    String? stored;
    var fail = true;
    final repository = LocalGameDraftRepository(
      read: () async => stored,
      write: (value) async {
        if (fail) throw StateError('Storage unavailable');
        stored = value;
      },
      remove: () async {
        stored = null;
      },
    );
    final store = GameDraftController(repository);
    await tester.pumpWidget(
      ChessApp(
        services: services(gameDraft: store),
        initialLocation: '/game?clock=off',
      ),
    );
    await tester.pumpAndSettle();
    for (final square in ['e2', 'e4']) {
      final target = find.byKey(ValueKey('square-$square'));
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }
    expect(store.hasError, true);
    fail = false;
    await store.save(store.draft!);
    await tester.pumpAndSettle();
    expect(store.hasError, false);
    expect((await repository.load())!.game.moves, ['e4']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('save, update and replay a local game through the profile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final history = memoryHistory();
    await tester.pumpWidget(
      ChessApp(
        services: services(gameHistory: history),
        initialLocation: '/play',
      ),
    );
    await tester.pumpAndSettle();
    final clock = find.byKey(const ValueKey('time-unlimited'));
    await tester.ensureVisible(clock);
    expect(tester.widget<ChoiceChip>(clock).selected, isTrue);
    await tester.pumpAndSettle();
    final start = find.byKey(const ValueKey('start-game'));
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();
    final save = find.byKey(const ValueKey('save-local-game'));
    expect(tester.widget<IconButton>(save).onPressed, isNull);
    for (final square in ['e2', 'e4']) {
      final target = find.byKey(ValueKey('square-$square'));
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect((await history.list()).single.moves, ['e4']);
    await tester.pump(const Duration(seconds: 4));
    for (final square in ['e7', 'e5']) {
      final target = find.byKey(ValueKey('square-$square'));
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect((await history.list()).single.moves, ['e4', 'e5']);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    final historyLink = find.text('Maç geçmişi');
    await tester.ensureVisible(historyLink);
    await tester.tap(historyLink);
    await tester.pumpAndSettle();
    expect(find.text('Kaydedilmiş pratik'), findsOneWidget);
    await tester.tap(find.text('Kaydedilmiş pratik'));
    await tester.pumpAndSettle();
    expect(find.text('Başlangıç konumu'), findsOneWidget);
    final next = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == 'Sonraki hamle',
    );
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('1 / 2 · e4'), findsOneWidget);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('2 / 2 · e5'), findsOneWidget);
    expect(tester.widget<IconButton>(next).onPressed, isNull);
    await tester.tap(find.byTooltip('İlk konum'));
    await tester.pumpAndSettle();
    expect(find.text('Başlangıç konumu'), findsOneWidget);
    expect((await history.list()).single.moves, ['e4', 'e5']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('history handles empty and unknown local games', (tester) async {
    await tester.pumpWidget(
      ChessApp(services: services(), initialLocation: '/history'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Henüz kaydedilmiş oyun yok.'), findsOneWidget);
    await tester.pumpWidget(
      ChessApp(
        key: const ValueKey('missing'),
        services: services(),
        initialLocation: '/history/missing',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bu oyun bu cihazda bulunamadı.'), findsOneWidget);
    final history = memoryHistory();
    final invalid = previewGame(moves: ['e5']);
    await history.save(invalid);
    await tester.pumpWidget(
      ChessApp(
        key: const ValueKey('corrupt'),
        services: services(gameHistory: history),
        initialLocation: '/history/${invalid.id}',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Oyun açılamadı.'), findsOneWidget);
    expect(
      find.text(
        'Kayıt okunamadı veya hamle bilgisi geçersiz. Diğer kayıtlarını geçmiş ekranından açabilirsin.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('all five tabs work and the local board accepts a move', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChessApp(services: services(), initialLocation: '/'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hamle sırası sende.'), findsOneWidget);
    for (final label in ['Liderlik', 'Sosyal', 'Profil', 'Oyna']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    final timedSwitch = find.byKey(const ValueKey('time-10-0'));
    await tester.ensureVisible(timedSwitch);
    await tester.tap(timedSwitch);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('start-game')));
    await tester.tap(find.byKey(const ValueKey('start-game')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('clock-white')),
        matching: find.text('10:00'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('square-e2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('square-e4')));
    await tester.pumpAndSettle();
    expect(find.text('Siyahın sırası'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('clock can be switched off for relaxed practice', (tester) async {
    await tester.pumpWidget(
      ChessApp(services: services(), initialLocation: '/play'),
    );
    await tester.pumpAndSettle();
    final clockSwitch = find.byKey(const ValueKey('time-10-0'));
    await tester.ensureVisible(clockSwitch);
    await tester.tap(clockSwitch);
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(clockSwitch).selected, isTrue);
    final unlimitedChip = find.byKey(const ValueKey('time-unlimited'));
    await tester.ensureVisible(unlimitedChip);
    await tester.tap(unlimitedChip);
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(unlimitedChip).selected, isTrue);
    final startButton = find.byKey(const ValueKey('start-game'));
    await tester.ensureVisible(startButton);
    await tester.tap(startButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('clock-white')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('theme persists through its repository and applies immediately', (
    tester,
  ) async {
    final dependencies = services();
    await tester.pumpWidget(
      ChessApp(services: dependencies, initialLocation: '/settings'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('theme-dark')));
    await tester.pumpAndSettle();
    expect(dependencies.theme.mode, ThemeMode.dark);
    expect(await dependencies.theme.repository.readTheme(), 'dark');
    expect(
      Theme.of(tester.element(find.text('Koyu'))).brightness,
      Brightness.dark,
    );
  });
  testWidgets('known and unknown invite links render useful states', (
    tester,
  ) async {
    final dependencies = services();
    final invite = await dependencies.challenges.create(
      const TimeControl(5, 0),
    );
    await tester.pumpWidget(
      ChessApp(
        key: const ValueKey('known'),
        services: dependencies,
        initialLocation: '/challenge/${invite.id}',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('WhatsApp ile paylaş'), findsOneWidget);
    await tester.pumpWidget(
      ChessApp(
        key: const ValueKey('unknown'),
        services: dependencies,
        initialLocation: '/challenge/missing',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bu davet bulunamadı.'), findsOneWidget);
  });
  testWidgets('social sections distinguish previews from live membership', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChessApp(services: services(), initialLocation: '/social'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Örnek Anadolu Lisesi'), findsOneWidget);

    final groupsTab = find.byKey(const ValueKey('social-tab-groups'));
    await tester.ensureVisible(groupsTab);
    await tester.tap(groupsTab);
    await tester.pumpAndSettle();
    expect(find.text('Hafta Sonu Satranç Kulübü'), findsOneWidget);

    final groupCard = find.byKey(
      const ValueKey('community-preview-sample-group-open'),
    );
    await tester.ensureVisible(groupCard);
    await tester.tap(groupCard);
    await tester.pumpAndSettle();
    expect(find.text('Tasarım örneği · gerçek üyelik değil'), findsOneWidget);
    expect(find.text('Kapat'), findsOneWidget);
    await tester.tap(find.text('Kapat'));
    await tester.pumpAndSettle();

    final tournamentsTab = find.byKey(const ValueKey('social-tab-tournaments'));
    await tester.ensureVisible(tournamentsTab);
    await tester.tap(tournamentsTab);
    await tester.pumpAndSettle();
    expect(find.text('Turnuva takvimi henüz hazır değil.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('small phone and larger text have no layout exceptions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final history = memoryHistory();
    await history.save(previewGame());
    for (final path in [
      '/',
      '/play',
      '/leaderboard',
      '/social',
      '/profile',
      '/settings',
      '/challenges',
      '/game',
      '/history',
      '/history/missing',
      '/history/0123456789abcdef0123456789abcdef',
    ]) {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: ChessApp(
            key: ValueKey(path),
            services: services(
              gameHistory: history,
              gameDraft: GameDraftController(
                memoryDraftRepository(),
                initialDraft: draftFixture(),
              ),
            ),
            initialLocation: path,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: path);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}


