import 'game_result.dart';

class BoardPiece {
  const BoardPiece(this.type, this.isWhite);
  final String type;
  final bool isWhite;
}

abstract interface class GameRules {
  BoardPiece? pieceAt(String square);
  bool get whiteToMove;
  bool get isOver;
  bool get agreedDraw;
  bool get resigned;
  void agreeDraw();
  void resign({bool? white});
  String get fen;
  GameResult get result;
  String get status;
  List<String> get history;
  List<String> destinations(String square);
  bool needsPromotion(String from, String to);
  bool move(String from, String to, {String promotion = 'q'});
  void undo();
  void reset();
}
