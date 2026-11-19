import 'game_result.dart';
import 'time_control.dart';
import 'computer_difficulty.dart';

enum GameOpponent { twoPlayers, computer }

enum PlayerSideChoice {
  white('Beyaz'),
  black('Siyah'),
  random('Rastgele');

  const PlayerSideChoice(this.label);
  final String label;
}

class SavedGame {
  SavedGame({
    required this.id,
    required this.savedAt,
    required this.initialFen,
    required List<String> moves,
    required this.timeControl,
    required this.clockEnabled,
    required this.result,
    this.opponent = GameOpponent.twoPlayers,
    this.difficulty = ComputerDifficulty.medium,
    this.agreedDraw = false,
    this.resigned = false,
    this.humanPlaysWhite = true,
  }) : moves = List.unmodifiable(moves);

  final String id;
  final DateTime savedAt;
  final String initialFen;
  final List<String> moves;
  final TimeControl timeControl;
  final bool clockEnabled;
  final GameResult result;
  final GameOpponent opponent;
  final ComputerDifficulty difficulty;
  final bool agreedDraw;
  final bool resigned;
  final bool humanPlaysWhite;

  Map<String, Object> toJson() => {
    'id': id,
    'savedAt': savedAt.toUtc().toIso8601String(),
    'initialFen': initialFen,
    'moves': moves,
    'minutes': timeControl.minutes,
    'incrementSeconds': timeControl.incrementSeconds,
    'clockEnabled': clockEnabled,
    'result': result.name,
    'opponent': opponent.name,
    'difficulty': difficulty.name,
    'agreedDraw': agreedDraw,
    if (resigned) 'resigned': true,
    if (!humanPlaysWhite) 'humanPlaysWhite': false,
  };

  factory SavedGame.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final fen = json['initialFen'] as String;
    final moves = (json['moves'] as List).cast<String>();
    final minutes = json['minutes'] as int;
    final increment = json['incrementSeconds'] as int;
    if (!RegExp(r'^[a-f0-9]{32}$').hasMatch(id) ||
        fen.length > 150 ||
        moves.isEmpty ||
        moves.length > 2048 ||
        moves.any((move) => move.isEmpty || move.length > 16) ||
        minutes < 1 ||
        minutes > TimeControl.maxMinutes ||
        increment < 0 ||
        increment > 60) {
      throw const FormatException('Invalid saved game');
    }
    final result = GameResult.values
        .where((value) => value.name == json['result'])
        .firstOrNull;
    if (result == null) throw const FormatException('Invalid game result');
    final agreedDraw = json['agreedDraw'] ?? false;
    if (agreedDraw is! bool || (agreedDraw && result != GameResult.draw)) {
      throw const FormatException('Invalid agreed draw');
    }
    final resigned = json['resigned'] ?? false;
    if (resigned is! bool ||
        (resigned &&
            (agreedDraw ||
                (result != GameResult.whiteWins &&
                    result != GameResult.blackWins)))) {
      throw const FormatException('Invalid resigned game');
    }
    final humanPlaysWhite = json['humanPlaysWhite'] ?? true;
    if (humanPlaysWhite is! bool) {
      throw const FormatException('Invalid player side');
    }
    final opponent = json['opponent'] == null
        ? GameOpponent.twoPlayers
        : GameOpponent.values
              .where((value) => value.name == json['opponent'])
              .firstOrNull;
    if (opponent == null) throw const FormatException('Invalid opponent');
    final difficulty = json['difficulty'] == null
        ? ComputerDifficulty.medium
        : ComputerDifficulty.values
              .where((level) => level.name == json['difficulty'])
              .firstOrNull;
    if (difficulty == null) throw const FormatException('Invalid difficulty');
    return SavedGame(
      id: id,
      savedAt: DateTime.parse(json['savedAt'] as String),
      initialFen: fen,
      moves: moves,
      timeControl: TimeControl(minutes, increment),
      clockEnabled: json['clockEnabled'] as bool,
      result: result,
      opponent: opponent,
      difficulty: difficulty,
      agreedDraw: agreedDraw,
      resigned: resigned,
      humanPlaysWhite: humanPlaysWhite,
    );
  }
}
