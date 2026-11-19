import 'package:chess/chess.dart' as chess;

import '../../../core/constants/app_config.dart';

import '../domain/saved_game.dart';

class LocalGamePlayback {
  LocalGamePlayback(SavedGame game) {
    if (chess.Chess.validate_fen(game.initialFen)['valid'] != true) {
      throw const FormatException('Invalid initial position');
    }
    final board = chess.Chess.fromFEN(game.initialFen);
    final positions = <String>[board.fen];
    for (final move in game.moves) {
      if (!board.move(move)) throw const FormatException('Invalid saved move');
      positions.add(board.fen);
    }
    frames = List.unmodifiable(positions);
    final date = game.savedAt.toLocal();
    board.set_header([
      'Event',
      'Local practice',
      'Site',
      AppConfig.name,
      'Date',
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}',
      'Round',
      '-',
      'White',
      'White',
      'Black',
      'Black',
      'Result',
      game.result.pgn,
      'TimeControl',
      game.clockEnabled
          ? '${game.timeControl.minutes * 60}+${game.timeControl.incrementSeconds}'
          : '-',
    ]);
    pgn = board.pgn({'max_width': 80});
  }

  static String formatOnlinePgn({
    required List<String> sanMoves,
    required DateTime playedAt,
    required String whiteName,
    required String blackName,
    required String resultPgn,
  }) {
    final board = chess.Chess();
    for (final move in sanMoves) {
      if (!board.move(move)) break;
    }
    final date = playedAt.toLocal();
    board.set_header([
      'Event',
      'Online match',
      'Site',
      AppConfig.name,
      'Date',
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}',
      'Round',
      '-',
      'White',
      whiteName,
      'Black',
      blackName,
      'Result',
      resultPgn,
    ]);
    return board.pgn({'max_width': 80});
  }

  late final List<String> frames;
  late final String pgn;
}
