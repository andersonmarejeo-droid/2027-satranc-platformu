// Headless previews of the production widgets. Ranking and auth identities below
// are explicitly preview fixtures; no real account or device is contacted.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chess_platform/app/app_services.dart';
import 'package:chess_platform/app/chess_app.dart';
import 'package:chess_platform/features/auth/presentation/account_controller.dart';
import 'package:chess_platform/features/game/data/local_chess_rules.dart';
import 'package:chess_platform/features/game/presentation/game_review_sheet.dart';
import 'package:chess_platform/features/game/presentation/widgets/chess_board.dart';
import 'package:chess_platform/features/leaderboard/domain/competition_score.dart';
import 'package:chess_platform/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:chess_platform/features/profile/domain/community_membership.dart';

import '../test/widget_test.dart' show services;

class _PreviewAuth implements FirebaseAuth {
  @override
  User? get currentUser => null;
  @override
  Stream<User?> idTokenChanges() => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Preview only');
}

class _PreviewDatabase implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Preview only');
}

class _PreviewStandings implements CommunityStandingsRepository {
  @override
  bool get isDemo => false;
  @override
  String? get currentPlayerId => 'preview-you';
  @override
  List<RankingEntry> entries(RankingScope scope, {String? id}) => const [];
  @override
  Future<CompetitionStandings> load(
    RankingScope scope,
    String id,
    String period,
  ) async => const CompetitionStandings(
    [
      CompetitionScore(
        uid: 'preview-leader',
        alias: 'Kale',
        points: 3,
        games: 1,
        wins: 1,
        draws: 0,
        losses: 0,
      ),
      CompetitionScore(
        uid: 'preview-you',
        alias: 'Satranççı',
        points: 1,
        games: 1,
        wins: 0,
        draws: 1,
        losses: 0,
      ),
    ],
    CompetitionScore(
      uid: 'preview-you',
      alias: 'Satranççı',
      points: 1,
      games: 1,
      wins: 0,
      draws: 1,
      losses: 0,
    ),
    2,
    false,
  );
}

void main() {
  testWidgets('export improved screens without launching a device', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      for (final entry in {
        'Ahem': 'assets/fonts/roboto-regular.ttf',
        'Roboto': 'assets/fonts/roboto-regular.ttf',
        'MaterialIcons': 'C:/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        'serif': 'C:/Windows/Fonts/georgia.ttf',
      }.entries) {
        final loader = FontLoader(entry.key)
          ..addFont(
            Future.value(
              ByteData.sublistView(await File(entry.value).readAsBytes()),
            ),
          );
        await loader.load();
      }
    });
    for (final entry in {
      '080-home': '/',
      '080-profile': '/profile',
      '080-weekly-cup-fixture': '/leaderboard',
      '080-account': '/account',
      '080-review': '/game?clock=off',
    }.entries) {
      final base = services(leaderboard: _PreviewStandings());
      await base.membership.save(
        CommunityMembership()
            .select(CommunityKind.country, 'tr')
            .select(CommunityKind.city, 'giresun')
            .select(CommunityKind.school, 'gfl')
            .select(CommunityKind.classroom, 'gfl-9a'),
      );
      await base.profile.saveDisplayName('Satranççı');
      final account = AccountController(
        _PreviewAuth(),
        _PreviewDatabase(),
        base.profile,
        base.membership,
      );
      final deps = AppServices(
        theme: base.theme,
        boardAppearance: base.boardAppearance,
        challenges: base.challenges,
        whatsApp: base.whatsApp,
        profile: base.profile,
        membership: base.membership,
        safetyPreferences: base.safetyPreferences,
        gameHistory: base.gameHistory,
        gameDraft: base.gameDraft,
        leaderboard: base.leaderboard,
        account: account,
      );
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: ChessApp(
            key: ValueKey(entry.key),
            services: deps,
            initialLocation: entry.value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (entry.key == '080-review') {
        showGameReview(
          tester.element(find.byType(ChessBoard)),
          initialFen: LocalChessRules().fen,
          moves: const ['f3', 'e5', 'g4', 'Qh4#'],
        );
        await tester.pumpAndSettle();
      }
      if (entry.key == '080-home') {
        await tester.runAsync(
          () => precacheImage(
            const AssetImage('assets/images/chess_hero.png'),
            tester.element(find.byType(ChessApp)),
          ),
        );
        await tester.pumpAndSettle();
      }
      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('previews').create(recursive: true);
        await File('previews/${entry.key}.png')
            .writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      account.dispose();
    }
  });
}
