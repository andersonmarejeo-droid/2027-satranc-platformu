import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../core/networking/firebase_chess_service.dart';
import '../core/networking/firebase_match_authority_client.dart';

import '../features/game/data/local_chess_rules.dart';
import '../features/game/data/local_computer_player.dart';
import '../features/game/domain/game_rules.dart';
import '../features/game/domain/computer_difficulty.dart';
import '../features/game/data/local_game_history_repository.dart';
import '../features/game/domain/game_history_repository.dart';
import '../features/game/data/local_game_draft_repository.dart';
import '../features/game/presentation/game_draft_controller.dart';
import '../features/game/presentation/quick_play_controller.dart';
import '../features/settings/presentation/comfort_controller.dart';
import '../features/settings/presentation/daily_reminder_controller.dart';
import '../features/auth/presentation/account_controller.dart';
import '../features/leaderboard/data/firebase_leaderboard_repository.dart';
import '../features/leaderboard/data/firebase_competition_repository.dart';
import '../features/leaderboard/domain/competition_score.dart';
import '../features/groups/data/firebase_small_team_repository.dart';
import '../features/leaderboard/data/demo_leaderboard_repository.dart';
import '../features/leaderboard/domain/leaderboard_repository.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../features/challenges/data/local_challenge_repository.dart';
import '../features/challenges/data/api_challenge_repository.dart';
import '../features/challenges/data/whatsapp_share_service.dart';
import '../features/challenges/domain/challenge_repository.dart';
import '../features/matchmaking/data/api_matchmaking_repository.dart';
import '../features/matchmaking/domain/matchmaking_repository.dart';
import '../features/game/data/api_match_repository.dart';
import '../features/game/domain/match_repository.dart';
import '../features/settings/data/preferences_settings_repository.dart';
import '../features/settings/presentation/theme_controller.dart';
import '../features/settings/presentation/board_appearance_controller.dart';
import '../features/settings/data/local_board_appearance_repository.dart';
import '../features/profile/data/preferences_guest_profile_repository.dart';
import '../features/profile/presentation/profile_controller.dart';
import '../features/profile/presentation/community_membership_controller.dart';
import '../features/profile/data/local_community_membership_repository.dart';
import '../features/profile/domain/community_membership.dart';
import '../features/schools/data/school_catalog_repository.dart';
import '../features/safety/data/preferences_safety_preferences_repository.dart';
import '../features/safety/presentation/safety_preferences_controller.dart';
import '../features/safety/domain/safety_repository.dart';
import '../features/safety/data/firebase_safety_repository.dart';
import '../features/auth/data/api_auth_repository.dart';
import '../features/auth/domain/auth_repository.dart';
import '../core/constants/app_config.dart';
import '../core/networking/api_client.dart';
import '../core/networking/api_transport_factory.dart';
import '../core/notifications/notification_service.dart';
import '../core/localization/app_language.dart';

class AppServices {
  AppServices({
    required this.theme,
    required this.boardAppearance,
    LanguageController? language,
    required this.challenges,
    required this.whatsApp,
    required this.profile,
    required this.membership,
    required this.safetyPreferences,
    required this.gameHistory,
    required this.gameDraft,
    this.auth,
    this.quickPlay,
    this.comfort,
    this.dailyReminder,
    this.account,
    this.notifications,
    this.safety,
    this.competition,
    this.api,
    this.matchmaking,
    this.matches,
    this.gameRules = LocalChessRules.new,
    this.computerMove = requestComputerMove,
    this.leaderboard = const DemoLeaderboardRepository(),
  }) : language = language ?? DefaultLanguageController();
  final ThemeController theme;
  final BoardAppearanceController boardAppearance;
  final LanguageController language;
  final ChallengeRepository challenges;
  final WhatsAppShareService whatsApp;
  final ProfileController profile;
  final CommunityMembershipController membership;
  final SafetyPreferencesController safetyPreferences;
  final GameHistoryRepository gameHistory;
  final GameDraftController gameDraft;
  final AuthRepository? auth;
  final QuickPlayController? quickPlay;
  final ComfortController? comfort;
  final DailyReminderController? dailyReminder;
  final AccountController? account;
  final NotificationService? notifications;
  final SafetyRepository? safety;
  final CompetitionRepository? competition;
  final ApiClient? api;
  final MatchmakingRepository? matchmaking;
  final MatchRepository? matches;
  final GameRules Function() gameRules;
  final Future<Map<String, String>?> Function(String, ComputerDifficulty)
  computerMove;
  final LeaderboardRepository leaderboard;

  /// Requests push permission only from an explicit settings/action flow.
  /// Startup never shows a system permission prompt.
  Future<NotificationRegistration?> enableNotifications({
    void Function(RemoteMessage message)? onForegroundMessage,
  }) async {
    final service = notifications;
    if (service == null) return null;
    final firebase = matches;
    return service.enable(
      onToken: (token) async {
        if (firebase is FirebaseChessService) {
          await firebase.saveNotificationToken(token);
        }
      },
      onForegroundMessage: onForegroundMessage,
    );
  }

  Future<void> disableNotifications() async {
    await notifications?.disable();
    if (matches is FirebaseChessService) {
      await (matches! as FirebaseChessService).removeNotificationToken();
    }
  }

  static Future<AppServices> create({
    AccessTokenProvider? accessTokenProvider,
    AuthIdentityProvider? authIdentityProvider,
  }) async {
    try {
      await const SchoolCatalogRepository().load();
    } catch (e) {
      debugPrint('Okul kataloğu yüklenemedi: $e');
    }
    final preferences = SharedPreferencesAsync();
    final quickPlay = QuickPlayController.preferences(preferences);
    await quickPlay.load();
    final comfort = ComfortController(preferences);
    await comfort.load();
    final dailyReminder = DailyReminderController(preferences);
    await dailyReminder.load();
    final boardAppearance = BoardAppearanceController(
      LocalBoardAppearanceRepository.preferences(preferences),
    );
    await boardAppearance.load();
    final gameDraft = GameDraftController(
      LocalGameDraftRepository.preferences(preferences),
    );
    await gameDraft.load();
    final theme = ThemeController(PreferencesSettingsRepository(preferences));
    await theme.load();
    final profile = ProfileController(
      PreferencesGuestProfileRepository(preferences),
    );
    await profile.load();
    final membership = CommunityMembershipController(
      LocalCommunityMembershipRepository.preferences(preferences),
    );
    await membership.load();
    if (!membership.value.hasCountry) {
      await membership.save(
        membership.value.select(CommunityKind.country, 'tr'),
      );
    }
    final safetyPreferences = SafetyPreferencesController(
      PreferencesSafetyPreferencesRepository(preferences),
    );
    await safetyPreferences.load();
    final tokenProvider =
        authIdentityProvider?.getAccessToken ?? accessTokenProvider;
    final api = AppConfig.apiBaseUrl.trim().isEmpty
        ? null
        : RestApiClient(
            baseUrl: AppConfig.apiBaseUrl,
            transport: createPlatformApiTransport(),
            accessTokenProvider: tokenProvider,
          );
    final firebase = Firebase.apps.isNotEmpty
        ? FirebaseChessService(
            FirebaseAuth.instance,
            FirebaseFirestore.instance,
            authority: AppConfig.serverAuthorityEnabled
                ? FirebaseMatchAuthorityClient()
                : null,
          )
        : null;
    final account = firebase == null
        ? null
        : AccountController(
            firebase.auth,
            firebase.db,
            profile,
            membership,
            teams: FirebaseSmallTeamRepository(firebase.db),
          );
    firebase?.beforeDelete = account?.prepareDeletion;
    if (account?.permanent == true) {
      try {
        await account!.restoreOrBackup();
      } catch (_) {
        account!.error =
            'Hesap yedeği yüklenemedi. Cihazdaki profil kullanılacak.';
      }
    }
    return AppServices(
      account: account,
      notifications: firebase == null ? null : NotificationService(),
      safety: firebase == null
          ? null
          : FirebaseSafetyRepository(firebase.auth, firebase.db),
      competition: firebase == null
          ? null
          : FirebaseCompetitionRepository(firebase.auth, firebase.db),
      leaderboard: firebase == null
          ? const DemoLeaderboardRepository()
          : FirebaseLeaderboardRepository(firebase.auth, firebase.db),
      quickPlay: quickPlay,
      comfort: comfort,
      dailyReminder: dailyReminder,
      auth: api != null && authIdentityProvider != null
          ? ApiAuthRepository(api, authIdentityProvider)
          : null,
      theme: theme,
      boardAppearance: boardAppearance,
      language: await LanguageController.load(),
      gameHistory: LocalGameHistoryRepository.preferences(preferences),
      gameDraft: gameDraft,
      challenges:
          firebase ??
          (api != null && tokenProvider != null
              ? ApiChallengeRepository(api)
              : LocalChallengeRepository(preferences)),
      matchmaking:
          firebase ??
          (api != null && tokenProvider != null
              ? ApiMatchmakingRepository(api)
              : null),
      matches:
          firebase ??
          (api != null && tokenProvider != null
              ? ApiMatchRepository(api, baseUrl: AppConfig.apiBaseUrl)
              : null),
      whatsApp: WhatsAppShareService(),
      profile: profile,
      membership: membership,
      safetyPreferences: safetyPreferences,
      api: api,
    );
  }
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});
  final AppServices services;
  static AppServices of(BuildContext context, {bool listen = true}) {
    if (listen) {
      return context.dependOnInheritedWidgetOfExactType<AppScope>()!.services;
    }
    return context.getInheritedWidgetOfExactType<AppScope>()!.services;
  }
  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}
