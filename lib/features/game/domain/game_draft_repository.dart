import 'game_draft.dart';

abstract interface class GameDraftRepository {
  Future<GameDraft?> load();
  Future<void> save(GameDraft draft);
  Future<void> clear();
}
