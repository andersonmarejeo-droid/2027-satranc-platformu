import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'menu_back.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/game/presentation/play_screen.dart';
import '../../features/game/presentation/game_screen.dart';
import '../../features/game/domain/time_control.dart';
import '../../features/game/domain/saved_game.dart';
import '../../features/game/domain/computer_difficulty.dart';
import '../../features/leaderboard/presentation/leaderboard_screen.dart';
import '../../features/social/presentation/social_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/challenges/presentation/challenge_screen.dart';
import '../../features/legal/presentation/safety_screen.dart';
import '../../features/matchmaking/presentation/matchmaking_screen.dart';
import '../../features/game/presentation/online_match_screen.dart';
import '../../features/game/presentation/online_games_screen.dart';
import '../../features/game/presentation/game_history_screen.dart';
import '../../features/game/presentation/game_replay_screen.dart';
import '../../app/app_services.dart';
import '../../features/auth/presentation/community_registration_screen.dart';
import '../../features/auth/presentation/account_screen.dart';
import '../../features/profile/domain/community_membership.dart';
import '../../features/schools/presentation/school_feedback_screen.dart';
import '../localization/app_language.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(String? initialLocation) => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: initialLocation,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/', builder: (c, s) => const HomeScreen())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/play', builder: (c, s) => const PlayScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/leaderboard',
              builder: (c, s) => const LeaderboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/social', builder: (c, s) => const SocialScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
          ],
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/game',
      builder: (c, s) {
        final resuming = s.uri.queryParameters['resume'] == '1';
        // A direct local-board link also preserves an existing board. The Play
        // screen explicitly clears it after confirming a new game.
        final draft = AppScope.of(c).gameDraft.draft;
        if (resuming && draft == null) {
          return MenuBackScope(
            child: Scaffold(
              appBar: AppBar(
                leading: const MenuBackButton(),
                title: const Text('Yerel oyun'),
              ),
              body: Center(
                child: FilledButton(
                  onPressed: () => c.go('/play'),
                  child: const Text('Kayıtlı tahta yok · Oyna ekranına dön'),
                ),
              ),
            ),
          );
        }
        return GameScreen(
          timeControl:
              draft?.game.timeControl ??
              TimeControl.fromQuery(s.uri.queryParameters),
          clockEnabled:
              draft?.game.clockEnabled ??
              (s.uri.queryParameters['clock'] != 'off'),
          draft: draft,
          difficulty:
              draft?.game.difficulty ??
              ComputerDifficulty.fromQuery(s.uri.queryParameters['difficulty']),
          opponent:
              draft?.game.opponent ??
              (s.uri.queryParameters['opponent'] == 'computer'
                  ? GameOpponent.computer
                  : GameOpponent.twoPlayers),
          humanPlaysWhite:
              draft?.game.humanPlaysWhite ??
              (s.uri.queryParameters['playerColor'] != 'black'),
          matchmakingFallback: s.uri.queryParameters['fallback'] == '1',
        );
      },
    ),
    _menuRoute(path: '/challenges', builder: (c, s) => const ChallengeScreen()),
    _menuRoute(
      path: '/matchmaking',
      builder: (c, s) => MatchmakingScreen(
        timeControl: TimeControl.fromQuery(s.uri.queryParameters),
        autostart: s.uri.queryParameters['start'] == '1',
      ),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/online-match/:matchId',
      builder: (c, s) =>
          OnlineMatchScreen(matchId: s.pathParameters['matchId']!),
    ),
    _menuRoute(
      path: '/online-games',
      builder: (c, s) => const OnlineGamesScreen(),
    ),
    _menuRoute(
      path: '/challenge/:id',
      builder: (c, s) => ChallengeScreen(inviteId: s.pathParameters['id']),
    ),
    _menuRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
    _menuRoute(path: '/account', builder: (c, s) => const AccountScreen()),
    _menuRoute(
      path: '/school-feedback',
      builder: (c, s) => const SchoolFeedbackScreen(),
    ),
    _menuRoute(
      path: '/registration',
      builder: (c, s) => CommunityRegistrationScreen(
        initialKind: CommunityKind.values
            .where((k) => k.name == s.uri.queryParameters['edit'])
            .firstOrNull,
      ),
    ),
    _menuRoute(path: '/history', builder: (c, s) => const GameHistoryScreen()),
    _menuRoute(
      path: '/history/:gameId',
      builder: (c, s) => GameReplayScreen(gameId: s.pathParameters['gameId']!),
    ),
    _menuRoute(path: '/safety', builder: (c, s) => const SafetyScreen()),
    _menuRoute(
      path: '/not-found',
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          leading: const MenuBackButton(),
          title: const Text('Bağlantı bulunamadı'),
        ),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Ana sayfaya dön'),
          ),
        ),
      ),
    ),
  ],
  // Keep an actual route match for back handling after an invalid deep link.
  onException: (context, state, router) => router.go('/not-found'),
);

GoRoute _menuRoute({
  required String path,
  required Widget Function(BuildContext, GoRouterState) builder,
}) => GoRoute(
  parentNavigatorKey: rootNavigatorKey,
  path: path,
  builder: (context, state) => MenuBackScope(child: builder(context, state)),
);

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;
  @override
  Widget build(BuildContext context) {
    final langService = AppScope.of(context).language;

    return ListenableBuilder(
      listenable: langService,
      builder: (context, _) {
        final langCode = langService.current.code;

        final titles = [
          AppStrings.get('nav_home', langCode),
          AppStrings.get('nav_play', langCode),
          AppStrings.get('nav_leaderboard', langCode),
          AppStrings.get('nav_social', langCode),
          AppStrings.get('nav_profile', langCode),
        ];

        return PopScope<Object?>(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && shell.currentIndex != 0) shell.goBranch(0);
          },
          child: Scaffold(
            appBar: shell.currentIndex == 0
                ? null
                : AppBar(
                    toolbarHeight: 40,
                    leading: const MenuBackButton(),
                    title: Text(
                      titles[shell.currentIndex],
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
            body: shell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: (index) =>
                  shell.goBranch(index, initialLocation: index == shell.currentIndex),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home_rounded),
                  label: titles[0],
                ),
                NavigationDestination(
                  icon: const Icon(Icons.sports_esports_outlined),
                  selectedIcon: const Icon(Icons.sports_esports),
                  label: titles[1],
                ),
                NavigationDestination(
                  icon: const Icon(Icons.emoji_events_outlined),
                  selectedIcon: const Icon(Icons.emoji_events),
                  label: titles[2],
                ),
                NavigationDestination(
                  icon: const Icon(Icons.people_outline),
                  selectedIcon: const Icon(Icons.people),
                  label: titles[3],
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: const Icon(Icons.person),
                  label: titles[4],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
