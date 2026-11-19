import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/game_rules.dart';

String? checkedKingSquare(GameRules rules) {
  if (!rules.status.contains('şah tehdit altında')) return null;
  final whiteChecked = rules.whiteToMove;
  for (var row = 0; row < 8; row++) {
    for (var col = 0; col < 8; col++) {
      final square = '${String.fromCharCode(97 + col)}${8 - row}';
      final piece = rules.pieceAt(square);
      if (piece != null && piece.type == 'k' && piece.isWhite == whiteChecked) {
        return square;
      }
    }
  }
  return null;
}

class MaterialBalance {
  const MaterialBalance({
    required this.capturedByWhite,
    required this.capturedByBlack,
    required this.whiteAdvantage,
  });

  factory MaterialBalance.fromRules(GameRules rules) {
    const initialCounts = {'q': 1, 'r': 2, 'b': 2, 'n': 2, 'p': 8};
    const values = {'q': 9, 'r': 5, 'b': 3, 'n': 3, 'p': 1, 'k': 0};
    final whiteCounts = <String, int>{};
    final blackCounts = <String, int>{};
    var whiteScore = 0;
    var blackScore = 0;
    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        final piece = rules.pieceAt(
          '${String.fromCharCode(97 + col)}${8 - row}',
        );
        if (piece == null) continue;
        final pts = values[piece.type] ?? 0;
        if (piece.isWhite) {
          whiteCounts[piece.type] = (whiteCounts[piece.type] ?? 0) + 1;
          whiteScore += pts;
        } else {
          blackCounts[piece.type] = (blackCounts[piece.type] ?? 0) + 1;
          blackScore += pts;
        }
      }
    }
    final capturedByWhite = <String>[];
    final capturedByBlack = <String>[];
    for (final entry in initialCounts.entries) {
      final missingBlack = math.max(
        0,
        entry.value - (blackCounts[entry.key] ?? 0),
      );
      for (var i = 0; i < missingBlack; i++) {
        capturedByWhite.add(entry.key);
      }
      final missingWhite = math.max(
        0,
        entry.value - (whiteCounts[entry.key] ?? 0),
      );
      for (var i = 0; i < missingWhite; i++) {
        capturedByBlack.add(entry.key);
      }
    }
    return MaterialBalance(
      capturedByWhite: capturedByWhite,
      capturedByBlack: capturedByBlack,
      whiteAdvantage: whiteScore - blackScore,
    );
  }

  final List<String> capturedByWhite;
  final List<String> capturedByBlack;
  final int whiteAdvantage;

  static const _glyphs = {
    'q': '♛',
    'r': '♜',
    'b': '♝',
    'n': '♞',
    'p': '♟',
  };

  String summaryFor({required bool white}) {
    final captured = white ? capturedByWhite : capturedByBlack;
    final advantage = white ? whiteAdvantage : -whiteAdvantage;
    final symbols = captured.map((t) => _glyphs[t] ?? '').join();
    if (symbols.isEmpty && advantage <= 0) return '';
    if (advantage > 0 && symbols.isNotEmpty) return '$symbols +$advantage';
    if (advantage > 0) return '+$advantage';
    return symbols;
  }
}

class CapturedPiecesStrip extends StatelessWidget {
  const CapturedPiecesStrip({
    super.key,
    required this.rules,
    required this.forWhite,
  });

  final GameRules rules;
  final bool forWhite;

  @override
  Widget build(BuildContext context) {
    final text = MaterialBalance.fromRules(rules).summaryFor(white: forWhite);
    if (text.isEmpty) return const SizedBox.shrink();
    return Text(
      text,
      key: ValueKey('captured-${forWhite ? 'white' : 'black'}'),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
