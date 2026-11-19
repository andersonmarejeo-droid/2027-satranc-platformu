import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_platform/app/chess_app.dart';
import 'package:chess_platform/features/leaderboard/domain/competition_score.dart';
import 'package:chess_platform/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:chess_platform/features/profile/domain/community_membership.dart';
import 'package:chess_platform/features/game/data/local_chess_rules.dart';
import 'package:chess_platform/features/game/presentation/game_review_sheet.dart';
import 'package:chess_platform/app/app_services.dart';

import 'widget_test.dart' show services;
import 'game_presentation_test.dart' show TestMatches;

import 'package:chess_platform/features/game/presentation/online_game_controller.dart';
import 'package:chess_platform/features/game/domain/match_snapshot.dart';
import 'package:chess_platform/features/game/domain/match_connection_repository.dart';

class FlakyMatchFixture extends TestMatches {
  int failures = 1, loads = 0;
  @override
  Future<MatchSnapshot> fetch(String id) async {
    loads++;
    if (failures > 0) {
      failures--;
      throw StateError('offline fixture');
    }
    return snapshot;
  }
}

class ConnectionFixture extends TestMatches
    implements MatchConnectionRepository {
  final connection = StreamController<MatchConnection>.broadcast();
  @override
  Stream<MatchConnection> watchConnection(String id) => connection.stream;
}

const fixtureScore = CompetitionScore(
  uid: 'player',
  alias: 'Takma ad',
  points: 6,
  games: 3,
  wins: 2,
  draws: 0,
  losses: 1,
);

class StandingsFixture implements CommunityStandingsRepository {
  Future<CompetitionStandings> Function(RankingScope, String, String)? fetch;
  final calls = <(RankingScope, String, String)>[];
  @override
  bool get isDemo => false;
  @override
  String? get currentPlayerId => 'player';
  @override
  List<RankingEntry> entries(RankingScope scope, {String? id}) => const [];
  @override
  Future<CompetitionStandings> load(
    RankingScope scope,
    String id,
    String period,
  ) {
    calls.add((scope, id, period));
    return fetch?.call(scope, id, period) ??
        Future.value(
          const CompetitionStandings([fixtureScore], fixtureScore, 176, true),
        );
  }
}

void main() {
  testWidgets('failed connection retries and restores the existing board', (
    tester,
  ) async {
    final repo = FlakyMatchFixture(),
        controller = OnlineGameController(repo, 'fixture');
    await controller.load();
    expect(controller.connected, isFalse);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(repo.loads, 2);
    expect(controller.connected, isTrue);
    expect(controller.snapshot, isNotNull);
    controller.dispose();
    await tester.pump(const Duration(seconds: 31));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'offline connection blocks a stale move and recovers the same board',
    (tester) async {
      final repo = ConnectionFixture(),
          controller = OnlineGameController(repo, 'fixture');
      await controller.load();
      repo.connection.add(const MatchConnection(connected: false));
      await tester.pump();
      controller.select('e2');
      await controller.submitMove('e2', 'e4');
      expect(controller.selected, isNull);
      expect(controller.snapshot!.ply, 0);
      repo.connection.add(
        MatchConnection(connected: true, opponentSeenAt: DateTime.now()),
      );
      await tester.pump();
      expect(controller.connected, isTrue);
      expect(controller.connectionLabel, contains('Rakip oyun ekranında'));
      controller.dispose();
      await repo.connection.close();
    },
  );
  testWidgets(
    'my rank uses saved class and shows exact rank outside first 100 on small phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = StandingsFixture(), deps = services(leaderboard: repo);
      await deps.membership.save(
        CommunityMembership()
            .select(CommunityKind.country, 'tr')
            .select(CommunityKind.city, 'giresun')
            .select(CommunityKind.school, 'gfl')
            .select(CommunityKind.classroom, 'gfl-9a'),
      );
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: ChessApp(services: deps, initialLocation: '/leaderboard'),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.calls.first.$1, RankingScope.classroom);
      expect(repo.calls.first.$2, 'gfl-9a');
      await tester.ensureVisible(find.textContaining('176. sıradasın'));
      expect(find.textContaining('176. sıradasın'), findsOneWidget);
      expect(find.textContaining('örnek'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'ranking discards a slower response from a previously selected scope',
    (tester) async {
      final old = Completer<CompetitionStandings>(), repo = StandingsFixture();
      repo.fetch = (scope, id, period) => scope == RankingScope.country
          ? old.future
          : Future.value(const CompetitionStandings([], null, null, false));
      final deps = services(leaderboard: repo);
      await deps.membership.save(
        CommunityMembership()
            .select(CommunityKind.country, 'tr')
            .select(CommunityKind.city, 'giresun'),
      );
      await tester.pumpWidget(
        ChessApp(services: deps, initialLocation: '/leaderboard'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Türkiye').first);
      await tester.pump();
      await tester.tap(find.text('Şehrim'));
      await tester.pumpAndSettle();
      old.complete(
        const CompetitionStandings([fixtureScore], fixtureScore, 1, false),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('1. sıradasın'), findsNothing);
      expect(find.text('Bu seçimde henüz puanın yok.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'finished-game learning sheet switches before and after without an interactive board',
    (tester) async {
      final deps = services();
      await tester.pumpWidget(
        AppScope(
          services: deps,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: FilledButton(
                  onPressed: () => showGameReview(
                    context,
                    initialFen: LocalChessRules().fen,
                    moves: ['f3', 'e5', 'g4', 'Qh4#'],
                  ),
                  child: const Text('İncele'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('İncele'));
      await tester.pumpAndSettle();
      expect(find.text('Matı getiren hamle'), findsOneWidget);
      await tester.ensureVisible(find.text('Önce'));
      await tester.tap(find.text('Önce'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
