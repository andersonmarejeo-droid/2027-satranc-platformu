import '../domain/game_result.dart';
import 'local_chess_rules.dart';

/// Every client reconstructs the board from immutable UCI history. Never trust
/// an opponent-supplied FEN or result. Casual games do not update ratings.
class OnlinePosition {
  OnlinePosition(List<String> moves) : rules = LocalChessRules() {
    if (moves.length > 600) throw const FormatException('Too many moves');
    for (final move in moves) {
      if (!RegExp(r'^[a-h][1-8][a-h][1-8][qrbn]?$').hasMatch(move) ||
          rules.isOver ||
          !rules.move(
            move.substring(0, 2),
            move.substring(2, 4),
            promotion: move.length == 5 ? move[4] : 'q',
          )) {
        throw const FormatException('Illegal online move history');
      }
    }
  }
  final LocalChessRules rules;
  GameResult get result => rules.result;
}
