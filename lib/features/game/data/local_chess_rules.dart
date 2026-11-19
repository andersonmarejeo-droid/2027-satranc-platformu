import 'package:chess/chess.dart' as chess;

import '../domain/game_rules.dart';
import '../domain/game_result.dart';

class LocalChessRules implements GameRules {
  LocalChessRules({String? fen})
    : _board = fen == null ? chess.Chess() : chess.Chess.fromFEN(fen);
  final chess.Chess _board;
  bool _agreedDraw = false;
  bool? _resignedWhite;
  @override
  bool get agreedDraw => _agreedDraw;
  @override
  bool get resigned => _resignedWhite != null;
  @override
  void agreeDraw() {
    if (!isOver) _agreedDraw = true;
  }

  @override
  void resign({bool? white}) {
    if (!isOver) _resignedWhite = white ?? whiteToMove;
  }

  factory LocalChessRules.fromHistory({
    required String initialFen,
    required List<String> moves,
  }) {
    if (chess.Chess.validate_fen(initialFen)['valid'] != true) {
      throw const FormatException('Invalid initial position');
    }
    final rules = LocalChessRules(fen: initialFen);
    for (final move in moves) {
      if (rules.isOver || !rules._board.move(move)) {
        throw const FormatException('Invalid move history');
      }
    }
    return rules;
  }
  @override
  BoardPiece? pieceAt(String square) {
    final piece = _board.get(square);
    return piece == null
        ? null
        : BoardPiece(piece.type.name, piece.color == chess.Color.WHITE);
  }

  @override
  bool get whiteToMove => _board.turn == chess.Color.WHITE;
  @override
  bool get isOver => _agreedDraw || _resignedWhite != null || _board.game_over;
  @override
  String get fen => _board.fen;
  @override
  GameResult get result => _agreedDraw
      ? GameResult.draw
      : _resignedWhite != null
      ? (_resignedWhite! ? GameResult.blackWins : GameResult.whiteWins)
      : _board.in_checkmate
      ? (whiteToMove ? GameResult.blackWins : GameResult.whiteWins)
      : _board.in_draw
      ? GameResult.draw
      : GameResult.unfinished;
  @override
  String get status {
    if (_agreedDraw) return 'Anlaşmayla berabere';
    if (_resignedWhite != null) {
      return _resignedWhite!
          ? 'Beyaz oyunu terk etti · Siyah kazandı'
          : 'Siyah oyunu terk etti · Beyaz kazandı';
    }
    if (_board.in_checkmate) {
      return whiteToMove ? 'Mat · Siyah kazandı' : 'Mat · Beyaz kazandı';
    }
    if (_board.in_draw) return 'Oyun berabere';
    if (_board.in_check) {
      return whiteToMove
          ? 'Beyaz şah tehdit altında'
          : 'Siyah şah tehdit altında';
    }
    return whiteToMove ? 'Beyazın sırası' : 'Siyahın sırası';
  }

  @override
  List<String> get history => _board.getHistory().cast<String>();
  @override
  List<String> destinations(String square) => _board
      .generate_moves({'square': square})
      .map((move) => move.toAlgebraic)
      .toSet()
      .toList();
  @override
  bool needsPromotion(String from, String to) => _board
      .generate_moves({'square': from})
      .any((move) => move.toAlgebraic == to && move.promotion != null);
  @override
  bool move(String from, String to, {String promotion = 'q'}) =>
      !isOver && _board.move({'from': from, 'to': to, 'promotion': promotion});
  @override
  void undo() {
    _agreedDraw = false;
    _resignedWhite = null;
    _board.undo();
  }

  @override
  void reset() {
    _agreedDraw = false;
    _resignedWhite = null;
    _board.reset();
  }
}
