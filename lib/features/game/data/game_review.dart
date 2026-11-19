import 'package:chess/chess.dart' as chess;

class GameReviewInsight {
  const GameReviewInsight({
    required this.ply,
    required this.move,
    required this.title,
    required this.explanation,
    required this.beforeFen,
    required this.afterFen,
  });
  final int ply;
  final String move, title, explanation, beforeFen, afterFen;
}

int _material(chess.Chess board) {
  const values = {'p': 100, 'n': 320, 'b': 330, 'r': 500, 'q': 900, 'k': 0};
  var result = 0;
  for (var rank = 1; rank <= 8; rank++) {
    for (var file = 0; file < 8; file++) {
      final piece = board.get('${String.fromCharCode(97 + file)}$rank');
      if (piece != null) {
        result +=
            (values[piece.type.name] ?? 0) *
            (piece.color == chess.Color.WHITE ? 1 : -1);
      }
    }
  }
  return result;
}

/// Concrete board events only. Does not label sacrifices as blunders or claim Elo.
GameReviewInsight? reviewGame(String initialFen, List<String> moves) {
  if (moves.isEmpty || moves.length > 2048) return null;
  final board = chess.Chess.fromFEN(initialFen);
  GameReviewInsight? selected;
  var priority = -1;
  for (final (index, move) in moves.indexed) {
    final before = board.fen, material = _material(board);
    if (board.game_over || !board.move(move)) {
      throw const FormatException('Invalid review history');
    }
    final delta = (_material(board) - material).abs();
    final (score, title, explanation) = board.in_checkmate
        ? (
            100000,
            'Matı getiren hamle',
            'Bu hamleden sonra şahın güvenli karesi veya tehdidi engelleyen yasal hamle kalmadı. Şahın kaçış karelerini önceki konumla karşılaştır.',
          )
        : move.contains('=')
        ? (
            2000,
            'Piyonun terfisi',
            'Piyon son sıraya ulaştı ve daha güçlü bir taşa dönüştü. Geçer piyonu desteklemek oyun sonunda fark yaratır.',
          )
        : delta >= 900
        ? (
            1500,
            'Vezir alışı',
            'Bu hamlede vezir alındı. Taşın koruyucularını ve hamleden sonra oluşan tehditleri önceki konumla karşılaştır.',
          )
        : delta > 0
        ? (
            100 + delta,
            'Taş dengesi değişti',
            'Bu taş alışı tahtadaki maddi dengeyi değiştirdi. Alınan taşın korunup korunmadığına ve bir sonraki hamlede geri alınabilecek taşlara bak.',
          )
        : move.startsWith('O-O')
        ? (
            80,
            'Şah güvenliğe geçti',
            'Rok şahı kanada taşır ve kaleyi oyuna sokar. Önceki ve sonraki konumda şahın çevresindeki kareleri karşılaştır.',
          )
        : board.in_check
        ? (
            60,
            'Şah tehdidi',
            'Bu hamle şahı tehdit etti. Rakibin şahını kaçırarak, taşı alarak veya araya taş koyarak tehdidi nasıl karşıladığına bak.',
          )
        : (
            0,
            'Taşların gelişimi',
            'Açılışta taşları oyuna sokmak, merkezi kontrol etmek ve şahı güvene almak iyi bir başlangıçtır. Bu hamlenin hangi kareleri kontrol ettiğine bak.',
          );
    if (score > priority) {
      priority = score;
      selected = GameReviewInsight(
        ply: index + 1,
        move: move,
        title: title,
        explanation: explanation,
        beforeFen: before,
        afterFen: board.fen,
      );
    }
  }
  return selected;
}
