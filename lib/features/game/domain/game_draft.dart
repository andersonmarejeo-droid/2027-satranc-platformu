import 'clock_state.dart';
import 'saved_game.dart';

class GameDraft {
  const GameDraft({
    required this.game,
    required this.clock,
    required this.flipped,
    this.lastFrom,
    this.lastTo,
  });
  final SavedGame game;
  final ClockState clock;
  final bool flipped;
  final String? lastFrom, lastTo;

  Map<String, Object?> toJson() => {
    'game': game.toJson(),
    'clock': clock.toJson(),
    'flipped': flipped,
    'lastFrom': lastFrom,
    'lastTo': lastTo,
  };

  factory GameDraft.fromJson(Map<String, dynamic> json) {
    final game = SavedGame.fromJson(json['game'] as Map<String, dynamic>);
    final clock = ClockState.fromJson(json['clock'] as Map<String, dynamic>);
    final from = json['lastFrom'] as String?;
    final to = json['lastTo'] as String?;
    if (clock.undo.length != (game.clockEnabled ? game.moves.length : 0) ||
        (!game.clockEnabled && clock.flagged) ||
        (from != null && !RegExp(r'^[a-h][1-8]$').hasMatch(from)) ||
        (to != null && !RegExp(r'^[a-h][1-8]$').hasMatch(to))) {
      throw const FormatException('Invalid game draft');
    }
    return GameDraft(
      game: game,
      clock: clock,
      flipped: json['flipped'] as bool,
      lastFrom: from,
      lastTo: to,
    );
  }
}
