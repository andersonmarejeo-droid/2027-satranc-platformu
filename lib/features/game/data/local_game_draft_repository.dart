import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/game_draft.dart';
import '../domain/game_draft_repository.dart';

class LocalGameDraftRepository implements GameDraftRepository {
  LocalGameDraftRepository({
    required this.read,
    required this.write,
    required this.remove,
  });
  factory LocalGameDraftRepository.preferences(SharedPreferencesAsync prefs) =>
      LocalGameDraftRepository(
        read: () => prefs.getString(_key),
        write: (value) => prefs.setString(_key, value),
        remove: () => prefs.remove(_key),
      );
  static const _key = 'game.active.v1';
  final Future<String?> Function() read;
  final Future<void> Function(String) write;
  final Future<void> Function() remove;
  Future<void> _pending = Future.value();

  @override
  Future<GameDraft?> load() async {
    await _pending;
    final stored = await read();
    if (stored == null) return null;
    try {
      final json = jsonDecode(stored) as Map<String, dynamic>;
      if (json['version'] != 1) {
        throw const FormatException('Unsupported draft');
      }
      return GameDraft.fromJson(json['draft'] as Map<String, dynamic>);
    } on TypeError {
      throw const FormatException('Invalid game draft');
    }
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final operation = _pending.then((_) => action());
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  @override
  Future<void> save(GameDraft draft) {
    GameDraft.fromJson(draft.toJson());
    final value = jsonEncode({'version': 1, 'draft': draft.toJson()});
    return _enqueue(() => write(value));
  }

  @override
  Future<void> clear() => _enqueue(remove);
}
