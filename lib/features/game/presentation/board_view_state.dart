import '../domain/game_rules.dart';

/// Read-only state consumed by the board renderer, whether local or remote.
abstract interface class BoardViewState {
  GameRules get rules;
  String? get selected;
  String? get lastFrom;
  String? get lastTo;
  bool get flipped;
  List<String> get targets;
}
