import 'saved_game.dart';

abstract interface class GameHistoryRepository {
  Future<List<SavedGame>> list();
  Future<void> save(SavedGame game);
}
