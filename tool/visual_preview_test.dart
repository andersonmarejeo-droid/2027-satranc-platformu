import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_platform/app/chess_app.dart';
import 'package:chess_platform/app/brand_intro_gate.dart';
import 'package:chess_platform/features/settings/domain/board_appearance.dart';
import 'package:chess_platform/features/game/presentation/widgets/board_materials.dart';
import 'package:chess_platform/features/game/presentation/widgets/chess_board.dart';
import 'package:chess_platform/features/game/presentation/game_controller.dart';
import 'package:chess_platform/features/game/data/local_chess_rules.dart';
import 'package:chess_platform/features/game/presentation/widgets/carved_chess_mesh.dart';

import '../test/widget_test.dart'
    show services, memoryHistory, previewGame, memoryDraftRepository;
import '../test/game_draft_test.dart' show draftFixture;
import '../test/match_actions_test.dart' show SocialMatches;

import 'package:chess_platform/features/game/domain/match_interactions.dart';
import 'package:chess_platform/features/schools/data/school_catalog_repository.dart';
import 'package:chess_platform/features/profile/domain/community_membership.dart';

import 'test_assets.dart';

import 'package:chess_platform/features/game/presentation/game_draft_controller.dart';

void main() {
  testWidgets('export mobile UI previews', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      if (const String.fromEnvironment('CHESS_PREVIEWS').contains('catalog-')) {
        await const SchoolCatalogRepository().load(bundle: SourceAssetBundle());
      }
      await CarvedChessMeshes.load(bundle: SourceAssetBundle());
      for (final path
          in BoardMaterial.all.values
              .map((m) => m.texture)
              .whereType<String>()
              .toSet()) {
        await BoardTextures.load(path, bundle: SourceAssetBundle());
      }
      for (final entry in {
        'Ahem': 'assets/fonts/roboto-regular.ttf',
        'MaterialIcons': 'C:/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        'Roboto': 'assets/fonts/roboto-regular.ttf',
        'serif': 'C:/Windows/Fonts/georgia.ttf',
      }.entries) {
        final font = File(entry.value);
        if (await font.exists()) {
          final loader = FontLoader(entry.key)
            ..addFont(
              Future.value(ByteData.sublistView(await font.readAsBytes())),
            );
          await loader.load();
        }
      }
    });
    for (final entry in {
      'home-light': '/',
      'home-fresh': '/',
      'home-fresh-dark': '/',
      'game-black-white': '/game?clock=off',
      'game-black-white-3d': '/game?clock=off',
      'theme-fresh-settings': '/settings',
      'online-draw-offer': '/online-match/fixture',
      'online-end-actions': '/online-match/fixture',
      'game-light': '/game',
      'leaderboard-light': '/leaderboard',
      'leaderboard-classes': '/leaderboard',
      'leaderboard-classes-dark': '/leaderboard',
      'leaderboard-class-players': '/leaderboard',
      'game-hints-on': '/game?clock=off',
      'game-hints-off': '/game?clock=off',
      'game-options': '/game?clock=off',
      'game-fullscreen': '/game?clock=off',
      'game-fullscreen-dark': '/game?minutes=5&increment=2',
      'home-dark': '/',
      'history-light': '/history',
      'replay-light': '/history/0123456789abcdef0123456789abcdef',
      'replay-dark': '/history/0123456789abcdef0123456789abcdef',
      'play-resume-light': '/play',
      'play-resume-dark': '/play',
      'game-paused-light': '/game?resume=1',
      'game-paused-dark': '/game?resume=1',
      'game-walnut-3d': '/game',
      'game-artisan-3d': '/game?clock=off&opponent=computer',
      'game-cream-3d': '/game?clock=off',
      'play-simple': '/play',
      'play-long-durations': '/play',
      'game-computer-master':
          '/game?clock=off&opponent=computer&difficulty=master',
      'game-computer-master-dark':
          '/game?clock=off&opponent=computer&difficulty=master',
      'profile-compact': '/profile',
      'social-compact': '/social',
      'registration': '/registration',
      'catalog-registration': '/registration',
      'catalog-city-search': '/registration',
      'catalog-school-search': '/registration',
      'catalog-class-choice': '/registration',
      'game-marble-3d': '/game',
      'game-candy-3d': '/game',
      'game-walnut-3d-dark': '/game',
      'game-candy-3d-dark': '/game',
      'game-candy-flat': '/game',
      'game-marble-overhead': '/game',
      'appearance-3d': '/settings',
    }.entries) {
      const selectedPreviews = String.fromEnvironment('CHESS_PREVIEWS');
      if (selectedPreviews.isNotEmpty &&
          !selectedPreviews.split(',').contains(entry.key)) {
        continue;
      }
      final history = memoryHistory();
      await history.save(previewGame());
      final draftStore = GameDraftController(
        memoryDraftRepository(),
        initialDraft:
            entry.key.contains('resume') || entry.key.contains('paused')
            ? draftFixture()
            : null,
      );
      final social = SocialMatches();
      if (entry.key == 'online-draw-offer') {
        social.interactions = const MatchInteractions(
          drawOfferedBy: 'black',
          drawOfferPly: 0,
        );
      }
      if (entry.key == 'online-end-actions') {
        social.completed = true;
        social.interactions = MatchInteractions(
          messages: [
            MatchQuickMessage(
              senderId: 'black',
              code: QuickMessageCode.wellPlayed,
              sentAt: DateTime.now(),
            ),
          ],
        );
      }
      final dependencies = services(
        matches: entry.key.startsWith('online-') ? social : null,
        gameHistory: history,
        gameDraft: draftStore,
      );
      if (entry.key.startsWith('catalog-')) {
        await dependencies.membership.save(
          CommunityMembership()
              .select(CommunityKind.country, 'tr')
              .select(CommunityKind.city, 'giresun')
              .select(CommunityKind.school, 'gfl')
              .select(CommunityKind.classroom, 'gfl-9a'),
        );
      }
      await dependencies.theme.setMode(
        entry.key.endsWith('dark') ? ThemeMode.dark : ThemeMode.light,
      );
      if (entry.key.contains('-3d') ||
          entry.key.endsWith('flat') ||
          entry.key.endsWith('overhead')) {
        final style = entry.key.contains('black-white')
            ? BoardStyle.blackWhite
            : entry.key.contains('artisan')
            ? BoardStyle.artisanWalnut
            : entry.key.contains('cream')
            ? BoardStyle.creamMarble
            : entry.key.contains('candy')
            ? BoardStyle.candy
            : entry.key.contains('marble')
            ? BoardStyle.marble
            : BoardStyle.walnut;
        await dependencies.boardAppearance.update(
          view: entry.key.contains('-3d')
              ? BoardViewMode.table3d
              : entry.key.endsWith('flat')
              ? BoardViewMode.flat
              : BoardViewMode.overhead,
          board: style,
          pieces: BoardMaterial.of(style).recommendedPieces,
          shape: entry.key.contains('artisan') || entry.key.contains('cream')
              ? PieceShape.carved
              : PieceShape.classic,
        );
      }
      if (entry.key == 'game-black-white') {
        await dependencies.boardAppearance.update(
          board: BoardStyle.blackWhite,
          pieces: PieceStyle.blackWhite,
        );
      }
      if (entry.key == 'game-hints-on') {
        await dependencies.boardAppearance.update(showLegalMoves: true);
      }
      if (entry.key == 'game-hints-off') {
        await dependencies.boardAppearance.update(showLegalMoves: false);
      }
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: ChessApp(
            key: ValueKey('preview-${entry.key}'),
            services: dependencies,
            initialLocation: entry.value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (entry.key.startsWith('catalog-') &&
          entry.key != 'catalog-registration') {
        final target = find.byKey(
          ValueKey(switch (entry.key) {
            'catalog-city-search' => 'join-city-tr-giresun',
            'catalog-school-search' => 'join-school-giresun-gfl',
            _ => 'join-classroom-gfl-gfl-9a',
          }),
        );
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
        if (entry.key != 'catalog-class-choice') {
          await tester.enterText(
            find.byKey(const ValueKey('community-search')),
            entry.key == 'catalog-city-search' ? 'Gir' : 'fen',
          );
          await tester.pumpAndSettle();
        }
      }
      if (entry.key.startsWith('leaderboard-class')) {
        for (final key in [
          'ranking-school',
          'ranking-community-gfl',
          'ranking-school-classes',
          if (entry.key == 'leaderboard-class-players') 'ranking-class-gfl-9a',
        ]) {
          final target = find.byKey(ValueKey(key));
          await tester.ensureVisible(target);
          await tester.tap(target);
          await tester.pumpAndSettle();
        }
      }
      if (entry.key.startsWith('game-hints')) {
        final board = tester.widget<ChessBoard>(find.byType(ChessBoard));
        (board.controller as GameController).selectOrMove('e2');
        await tester.pumpAndSettle();
      }
      if (entry.key == 'play-long-durations') {
        final target = find.byKey(const ValueKey('more-time-controls'));
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const ValueKey('time-90-30')));
        await tester.pumpAndSettle();
      }
      if (entry.key == 'game-options') {
        await tester.ensureVisible(
          find.byKey(const ValueKey('show-legal-moves')),
        );
        await tester.pumpAndSettle();
      }
      if (entry.key.startsWith('online-')) {
        await tester.ensureVisible(
          find
              .byKey(
                ValueKey(
                  entry.key == 'online-end-actions'
                      ? 'request-rematch'
                      : 'accept-draw',
                ),
              )
              .first,
        );
        await tester.pumpAndSettle();
      }
      if (entry.key.startsWith('game-fullscreen')) {
        final target = find.byKey(const ValueKey('game-fullscreen'));
        await tester.tap(target);
        await tester.pumpAndSettle();
      }
      if (entry.key.contains('paused')) {
        final pause = find.byKey(const ValueKey('pause-local-game'));
        await tester.ensureVisible(pause);
        await tester.tap(pause);
        await tester.pumpAndSettle();
      }
      await tester.runAsync(() async {
        await precacheImage(
          const AssetImage('assets/images/chess_hero.png'),
          tester.element(find.byType(ChessApp)),
        );
      });
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('previews').create(recursive: true);
        await File('previews/${entry.key}.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await social.events.close();
    }
    for (final progress in [0.25, 0.5, 0.75]) {
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: BrandIntroScene(progress: progress, reduceMotion: false),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('previews/brand-intro-${(progress * 100).round()}.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('export appearance collection without launching a device', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1840);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await CarvedChessMeshes.load(bundle: SourceAssetBundle());
      for (final path
          in BoardMaterial.all.values
              .map((m) => m.texture)
              .whereType<String>()
              .toSet()) {
        await BoardTextures.load(path, bundle: SourceAssetBundle());
      }
    });
    final rules = LocalChessRules();
    for (final move in [
      ('e2', 'e4'),
      ('e7', 'e5'),
      ('g1', 'f3'),
      ('b8', 'c6'),
      ('f1', 'c4'),
      ('f8', 'c5'),
    ]) {
      rules.move(move.$1, move.$2);
    }
    final game = GameController(rules);
    final configs = {
      'Sade 2D · Ceviz': const BoardAppearance(view: BoardViewMode.flat),
      'Üstten gerçekçi · Ceviz': const BoardAppearance(),
      '3D masa · Ceviz': const BoardAppearance(view: BoardViewMode.table3d),
      for (final style in [
        BoardStyle.artisanWalnut,
        BoardStyle.creamMarble,
        BoardStyle.candy,
      ])
        'Oyma Staunton · ${BoardMaterial.of(style).name}': BoardAppearance(
          view: BoardViewMode.table3d,
          board: style,
          pieces: BoardMaterial.of(style).recommendedPieces,
          shape: PieceShape.carved,
        ),
      for (final style in [
        BoardStyle.marble,
        BoardStyle.slate,
        BoardStyle.candy,
        BoardStyle.meadow,
        BoardStyle.ocean,
        BoardStyle.lavender,
      ])
        '3D masa · ${BoardMaterial.of(style).name}': BoardAppearance(
          view: BoardViewMode.table3d,
          board: style,
          pieces: BoardMaterial.of(style).recommendedPieces,
        ),
    };
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: const Color(0xFFF4F1EA),
            body: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tahta koleksiyonu',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF244C3E),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 24,
                    runSpacing: 28,
                    children: [
                      for (final entry in configs.entries)
                        SizedBox(
                          width: 360,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ChessBoard(
                                controller: game,
                                appearance: entry.value,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF394B43),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('previews/board-collection.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    game.dispose();
  });
}
