import 'dart:math' as math;

import 'package:chess/chess.dart' as chess;
import 'package:flutter/foundation.dart' show compute;

import '../domain/computer_difficulty.dart';

Future<Map<String, String>?> requestComputerMove(
  String fen, [
  ComputerDifficulty difficulty = ComputerDifficulty.medium,
]) => compute(_chooseRequest, (fen, difficulty));

Map<String, String>? _chooseRequest((String, ComputerDifficulty) request) =>
    chooseComputerMove(request.$1, difficulty: request.$2);

/// Bounded offline alpha-beta search, run away from the Android UI isolate.
/// Levels have different horizons and budgets, without a claimed Elo rating.
Map<String, String>? chooseComputerMove(
  String fen, {
  ComputerDifficulty difficulty = ComputerDifficulty.medium,
  int? nodeLimit,
}) => _ComputerSearch(fen, difficulty, nodeLimit).run();

class _SearchLimit implements Exception {
  const _SearchLimit();
}

class _ComputerSearch {
  _ComputerSearch(String fen, this.difficulty, int? nodeLimit)
    : board = chess.Chess.fromFEN(fen),
      limit = math.max(
        1,
        math.min(nodeLimit ?? difficulty.nodeBudget, difficulty.nodeBudget),
      );
  final chess.Chess board;
  final ComputerDifficulty difficulty;
  final int limit;
  final watch = Stopwatch();
  int nodes = 0;
  static const values = {
    'p': 100,
    'n': 320,
    'b': 335,
    'r': 500,
    'q': 900,
    'k': 0,
  };

  Map<String, String>? run() {
    if (board.game_over) return null;
    final options = board.generate_moves();
    if (options.isEmpty) return null;
    _order(options);
    var chosen = options.first;
    final white = board.turn == chess.Color.WHITE;
    watch.start();
    try {
      // Keep the last fully searched iteration if the budget expires.
      for (var depth = 1; depth <= difficulty.searchDepth; depth++) {
        final ordered = [chosen, ...options.where((move) => move != chosen)];
        var best = white ? double.negativeInfinity : double.infinity;
        var candidate = chosen;
        var alpha = double.negativeInfinity, beta = double.infinity;
        for (final move in ordered) {
          board.make_move(move);
          late double score;
          try {
            score = _search(depth - 1, difficulty.captureDepth, alpha, beta, 1);
          } finally {
            board.undo_move();
          }
          if (white ? score > best : score < best) {
            best = score;
            candidate = move;
          }
          if (white) {
            alpha = math.max(alpha, best);
          } else {
            beta = math.min(beta, best);
          }
        }
        chosen = candidate;
        if (best.abs() > 99000) break;
      }
    } on _SearchLimit {
      // The initial legal fallback also covers an interrupted first iteration.
    } finally {
      watch.stop();
    }
    return {
      'from': chosen.fromAlgebraic,
      'to': chosen.toAlgebraic,
      'promotion': chosen.promotion?.name ?? 'q',
    };
  }

  void _visit() {
    nodes++;
    if (nodes > limit || watch.elapsedMilliseconds >= difficulty.milliseconds) {
      throw const _SearchLimit();
    }
  }

  void _order(List<chess.Move> moves) => moves.sort((a, b) {
    int priority(chess.Move move) =>
        (values[move.captured?.name] ?? 0) * 10 +
        (values[move.promotion?.name] ?? 0);
    return priority(b).compareTo(priority(a));
  });

  double _search(
    int depth,
    int capturesLeft,
    double alpha,
    double beta,
    int ply,
  ) {
    _visit();
    final options = board.generate_moves();
    final white = board.turn == chess.Color.WHITE;
    if (options.isEmpty) {
      return board.in_check ? (white ? -100000.0 + ply : 100000.0 - ply) : 0;
    }
    if (board.insufficient_material || board.half_moves >= 100) return 0;
    var best = white ? double.negativeInfinity : double.infinity;
    if (depth == 0) {
      final standing = _evaluate();
      if (capturesLeft == 0) return standing;
      // Stronger levels resolve exchanges and evade check before evaluating.
      if (!board.in_check) {
        best = standing;
        if (white) {
          if (best >= beta) return best;
          alpha = math.max(alpha, best);
        } else {
          if (best <= alpha) return best;
          beta = math.min(beta, best);
        }
        options.removeWhere(
          (move) => move.captured == null && move.promotion == null,
        );
        if (options.isEmpty) return best;
      }
    }
    _order(options);
    for (final move in options) {
      board.make_move(move);
      late double score;
      try {
        score = _search(
          depth > 0 ? depth - 1 : 0,
          depth > 0 ? capturesLeft : capturesLeft - 1,
          alpha,
          beta,
          ply + 1,
        );
      } finally {
        board.undo_move();
      }
      best = white ? math.max(best, score) : math.min(best, score);
      if (white) {
        alpha = math.max(alpha, best);
      } else {
        beta = math.min(beta, best);
      }
      if (beta <= alpha) break;
    }
    return best;
  }

  double _evaluate() {
    var score = 0.0;
    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        final piece = board.get('${String.fromCharCode(97 + col)}${8 - row}');
        if (piece == null) continue;
        final white = piece.color == chess.Color.WHITE, type = piece.type.name;
        final center = 7 - (col - 3.5).abs() - (row - 3.5).abs();
        final advance = white ? 6 - row : row - 1;
        final bonus = switch (type) {
          'p' => center * 4 + advance * 7,
          'n' => center * 10,
          'b' => center * 5,
          _ => 0.0,
        };
        score += (white ? 1 : -1) * (values[type]! + bonus);
      }
    }
    return score;
  }
}
