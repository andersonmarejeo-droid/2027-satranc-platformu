import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chess_platform/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android navigation, legal move, persisted invite and theme', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oyna'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('start-game')));
    await tester.tap(find.byKey(const ValueKey('start-game')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('square-e2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('square-e4')));
    await tester.pumpAndSettle();
    expect(find.text('Siyahın sırası'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Liderlik'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ranking-school')));
    await tester.pumpAndSettle();
    expect(find.text('Giresun Fen Lisesi'), findsOneWidget);
    await tester.tap(find.text('Sosyal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Meydan oku'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create-invite')));
    await tester.pumpAndSettle();
    expect(find.text('WhatsApp ile paylaş'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('copy-invite')));
    await tester.pumpAndSettle();
    expect(find.text('Davet bağlantısı kopyalandı.'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Görünüm ve tema'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('theme-dark')));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Koyu'))).brightness,
      Brightness.dark,
    );
    await tester.tap(find.byKey(const ValueKey('theme-light')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
