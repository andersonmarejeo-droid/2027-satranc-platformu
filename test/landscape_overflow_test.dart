import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_platform/app/chess_app.dart';
import 'widget_test.dart' show services;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Farklı telefon yatay (landscape) ekran boyutları
  final landscapeSizes = [
    const Size(844, 390), // Modern iPhone / Android yatay
    const Size(800, 360), // Standart Android telefon yatay
    const Size(740, 320), // Kompakt/dar ekran Android yatay
    const Size(915, 412), // Büyük ekran telefon yatay
  ];

  final routes = [
    '/',
    '/play',
    '/challenges',
    '/history',
    '/leaderboard',
    '/social',
    '/profile',
    '/settings',
    '/account',
    '/safety',
    '/online-games',
    '/school-feedback',
    '/game?minutes=5&increment=2',
    '/game',
  ];

  for (final size in landscapeSizes) {
    group('Landscape layout tests at $size', () {
      for (final route in routes) {
        testWidgets('Route "$route" renders without overflow in landscape at $size', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final errors = <FlutterErrorDetails>[];
          final oldHandler = FlutterError.onError;
          FlutterError.onError = (details) {
            errors.add(details);
          };

          try {
            final appServices = services();
            await tester.pumpWidget(
              ChessApp(
                services: appServices,
                initialLocation: route,
              ),
            );
            await tester.pumpAndSettle();

            // Taşma (overflow) hatası kontrolü
            final overflowErrors = errors.where((e) {
              final msg = e.toString();
              return msg.contains('A RenderFlex overflowed') || msg.contains('overflowed by');
            }).toList();

            expect(
              overflowErrors,
              isEmpty,
              reason: 'Route "$route" produced overflow errors in landscape ($size): ${overflowErrors.map((e) => e.toString()).join('\n')}',
            );
          } finally {
            FlutterError.onError = oldHandler;
          }
        });
      }
    });
  }
}
