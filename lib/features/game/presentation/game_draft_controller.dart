import 'package:flutter/foundation.dart';

import '../domain/game_draft.dart';
import '../domain/game_draft_repository.dart';

class GameDraftController extends ChangeNotifier {
  GameDraftController(this.repository, {GameDraft? initialDraft})
    : _draft = initialDraft;
  final GameDraftRepository repository;
  GameDraft? _draft;
  GameDraft? get draft => _draft;
  bool isLoading = false;
  bool isSaving = false;
  bool hasError = false;
  int _revision = 0;

  Future<void> load() async {
    final revision = _revision;
    isLoading = true;
    notifyListeners();
    try {
      final value = await repository.load();
      if (revision == _revision) {
        _draft = value;
        hasError = false;
      }
    } catch (_) {
      if (revision == _revision) hasError = true;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> save(GameDraft draft) =>
      _update(draft, () => repository.save(draft));
  Future<void> clear() => _update(null, repository.clear);

  Future<void> _update(GameDraft? value, Future<void> Function() action) async {
    final previous = _draft;
    final revision = ++_revision;
    _draft = value;
    isSaving = true;
    notifyListeners();
    try {
      await action();
      if (revision == _revision) hasError = false;
    } catch (_) {
      if (revision == _revision) {
        hasError = true;
        if (value == null) _draft = previous;
      }
      rethrow;
    } finally {
      if (revision == _revision) isSaving = false;
      notifyListeners();
    }
  }
}
