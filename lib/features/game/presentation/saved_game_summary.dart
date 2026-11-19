import '../domain/saved_game.dart';

String savedGameDate(SavedGame game) {
  final date = game.savedAt.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year} · ${two(date.hour)}:${two(date.minute)}';
}

String savedGameSummary(SavedGame game) =>
    '${game.opponent == GameOpponent.computer ? 'Bilgisayar · ${game.difficulty.label} · ' : ''}${game.clockEnabled ? game.timeControl.plainLabel : 'Süresiz'} · ${game.moves.length} yarım hamle';
