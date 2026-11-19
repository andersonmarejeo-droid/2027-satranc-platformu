import 'package:flutter/foundation.dart';

import '../data/local_chess_rules.dart';
import '../data/local_game_playback.dart';
import '../domain/game_rules.dart';
import 'board_view_state.dart';

class GameReplayController extends ChangeNotifier implements BoardViewState {
  GameReplayController(this.playback)
    : _rules = LocalChessRules(fen: playback.frames.first);

  final LocalGamePlayback playback;
  GameRules _rules;
  int index = 0;
  @override
  bool flipped = false;
  @override
  GameRules get rules => _rules;
  @override
  String? get selected => null;
  @override
  String? get lastFrom => null;
  @override
  String? get lastTo => null;
  @override
  List<String> get targets => const [];

  void seek(int value) {
    final next = value.clamp(0, playback.frames.length - 1);
    if (next == index) return;
    index = next;
    _rules = LocalChessRules(fen: playback.frames[index]);
    notifyListeners();
  }

  void flip() {
    flipped = !flipped;
    notifyListeners();
  }
}
