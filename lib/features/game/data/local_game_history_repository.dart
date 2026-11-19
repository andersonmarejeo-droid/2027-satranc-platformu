import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/game_history_repository.dart';
import '../domain/saved_game.dart';

/// A single versioned value avoids partial writes across multiple preference keys.
class LocalGameHistoryRepository implements GameHistoryRepository {
  LocalGameHistoryRepository({required this.read, required this.write});

  factory LocalGameHistoryRepository.preferences(
    SharedPreferencesAsync prefs,
  ) => LocalGameHistoryRepository(
    read: () => prefs.getString(_key),
    write: (value) => prefs.setString(_key, value),
  );

  static const _key = 'game.history.v1';
  static const maxGames = 100;
  final Future<String?> Function() read;
  final Future<void> Function(String value) write;
  Future<void> _pending = Future.value();

  @override
  Future<List<SavedGame>> list() async {
    final value = await read();
    if (value == null) return [];
    try {
      final json = jsonDecode(value) as Map<String, dynamic>;
      if (json['version'] != 1) return [];
      final games = <SavedGame>[];
      final ids = <String>{};
      for (final entry in (json['games'] as List).take(maxGames)) {
        try {
          final game = SavedGame.fromJson(entry as Map<String, dynamic>);
          if (ids.add(game.id)) games.add(game);
        } on FormatException {
          continue;
        } on TypeError {
          continue;
        }
      }
      games.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return games;
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  @override
  Future<void> save(SavedGame game) {
    SavedGame.fromJson(game.toJson());
    final operation = _pending.then((_) async {
      final games = await list();
      games.removeWhere((existing) => existing.id == game.id);
      games.insert(0, game);
      await write(
        jsonEncode({
          'version': 1,
          'games': games.take(maxGames).map((game) => game.toJson()).toList(),
        }),
      );
    });
    // A failed write is surfaced to its caller, but does not block the next save.
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }
}
