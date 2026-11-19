import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:chess_platform/app/chess_app.dart';
import 'package:chess_platform/app/brand_intro_gate.dart';
import 'package:chess_platform/core/routing/menu_back.dart';
import 'package:chess_platform/features/game/domain/saved_game.dart';
import 'package:chess_platform/features/game/domain/time_control.dart';
import 'package:chess_platform/features/settings/domain/board_appearance.dart';

import 'widget_test.dart' show services, previewGame;

Future<void> tapKey(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  for (final path in ['/play', '/leaderboard', '/social', '/profile']) {
    testWidgets('Android back from $path goes home and home stays open', (
      tester,
    ) async {
      final platformCalls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          platformCalls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        ChessApp(services: services(), initialLocation: path),
      );
      await tester.pumpAndSettle();
      await systemBack(tester);
      expect(find.text('Hamle sırası sende.'), findsOneWidget);
      await systemBack(tester);
      expect(find.text('Hamle sırası sende.'), findsOneWidget);
      expect(platformCalls, isNot(contains('SystemNavigator.pop')));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  for (final entry in {
    '/settings': '/profile',
    '/safety': '/profile',
    '/registration': '/profile',
    '/history': '/profile',
    '/history/missing': '/history',
    '/challenges': '/social',
    '/challenge/missing': '/challenges',
    '/matchmaking': '/play',
    '/online-match/missing': '/play',
    '/unknown-page': '/',
  }.entries) {
    testWidgets('direct ${entry.key} goes to its parent on Android back', (
      tester,
    ) async {
      await tester.pumpWidget(
        ChessApp(services: services(), initialLocation: entry.key),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(Scaffold).last));
      expect(find.byType(MenuBackButton), findsWidgets);
      await systemBack(tester);
      expect(router.routeInformationProvider.value.uri.path, entry.value);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('toolbar uses previous page; dialog closes before its page', (
    tester,
  ) async {
    await tester.pumpWidget(ChessApp(services: services()));
    await tester.pumpAndSettle();
    final router = GoRouter.of(
      tester.element(find.text('Hamle sırası sende.')),
    );
    router.push('/settings');
    await tester.pumpAndSettle();
    final settingsContext = tester.element(find.text('Görünüm, dil, hesap ve yasal bilgileri buradan yönetebilirsin.'));
    showDialog<void>(
      context: settingsContext,
      builder: (_) => const AlertDialog(title: Text('Açık pencere')),
    );
    await tester.pumpAndSettle();
    await systemBack(tester);
    expect(find.text('Açık pencere'), findsNothing);
    expect(find.text('Görünüm, dil, hesap ve yasal bilgileri buradan yönetebilirsin.'), findsOneWidget);
    expect(router.canPop(), isTrue);
    await tester.tap(find.byType(MenuBackButton));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/');
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('ranking back climbs class, school and menu one step at a time', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChessApp(services: services(), initialLocation: '/leaderboard'),
    );
    await tester.pumpAndSettle();
    for (final key in [
      'ranking-school',
      'ranking-community-gfl',
      'ranking-school-classes',
      'ranking-class-gfl-9a',
    ]) {
      await tapKey(tester, key);
    }
    await systemBack(tester);
    expect(find.byKey(const ValueKey('ranking-class-gfl-9a')), findsOneWidget);
    await tester.tap(find.byType(MenuBackButton));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('ranking-school-classes')),
      findsOneWidget,
    );
    expect(find.text('Deniz K.'), findsOneWidget);
    await systemBack(tester);
    expect(find.byKey(const ValueKey('ranking-community-gfl')), findsOneWidget);
    await systemBack(tester);
    expect(find.text('Hamle sırası sende.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('game back keeps moves and first closes the appearance sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dependencies = services();
    await dependencies.boardAppearance.update(view: BoardViewMode.flat);
    await tester.pumpWidget(
      ChessApp(services: dependencies, initialLocation: '/game'),
    );
    await tester.pumpAndSettle();
    for (final square in ['e2', 'e4']) {
      await tapKey(tester, 'square-$square');
    }
    await tapKey(tester, 'board-appearance');
    await systemBack(tester);
    expect(find.text('İki kişilik oyun'), findsOneWidget);
    await systemBack(tester);
    expect(find.byKey(const ValueKey('resume-local-game')), findsOneWidget);
    expect(dependencies.gameDraft.draft!.game.moves, ['e4']);
    await systemBack(tester);
    expect(find.text('Hamle sırası sende.'), findsOneWidget);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Oyna'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'resume-local-game');
    expect(dependencies.gameDraft.draft!.game.moves, ['e4']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('simple durations and long tournament choice fit a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ChessApp(services: services(), initialLocation: '/play'),
    );
    await tester.pumpAndSettle();
    for (final key in [
      'time-unlimited',
      'time-10-0',
      'time-15-0',
      'time-30-0',
      'time-60-0',
    ]) {
      await tapKey(tester, key);
      expect(
        tester.widget<ChoiceChip>(find.byKey(ValueKey(key))).selected,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    }
    await tapKey(tester, 'more-time-controls');
    for (final key in ['time-1-0', 'time-2-0', 'time-3-0', 'time-5-0']) {
      await tapKey(tester, key);
      expect(
        tester.widget<ChoiceChip>(find.byKey(ValueKey(key))).selected,
        isTrue,
      );
    }
    await tapKey(tester, 'time-90-30');
    await tapKey(tester, 'start-game');
    expect(find.text('90 dakika'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  test('long tournament duration survives query parsing and storage', () {
    expect(
      TimeControl.fromQuery({'minutes': '90', 'increment': '30'}).label,
      '90 + 30',
    );
    final json = previewGame().toJson()
      ..['minutes'] = 90
      ..['incrementSeconds'] = 30;
    final restored = SavedGame.fromJson(json);
    expect(restored.timeControl.minutes, 90);
    expect(restored.timeControl.incrementSeconds, 30);
    expect(const TimeControl(10, 0).category, 'Blitz');
    expect(const TimeControl(15, 10).category, 'Rapid');
    expect(const TimeControl(90, 30).category, 'Classical');
  });
  testWidgets('opening rain ends once and shows the new name and publisher', (
    tester,
  ) async {
    await tester.pumpWidget(ChessApp(services: services(), showIntro: true));
    await tester.pump();
    expect(find.byKey(const ValueKey('brand-intro')), findsOneWidget);
    expect(find.text('Satranç Platformu'), findsOneWidget);
    expect(find.byKey(const ValueKey('intro-publisher')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('brand-intro')), findsNothing);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Oyna'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('brand-intro')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('reduced motion shows a short static brand scene', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: BrandIntroGate(child: Center(child: Text('Hazır'))),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester.widget<BrandIntroScene>(find.byType(BrandIntroScene)).reduceMotion,
      isTrue,
    );
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('brand-intro')), findsNothing);
    expect(find.text('Hazır'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
