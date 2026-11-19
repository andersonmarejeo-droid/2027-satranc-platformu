import 'package:flutter/material.dart';

import '../data/game_review.dart';
import '../data/local_chess_rules.dart';
import '../domain/game_rules.dart';
import 'board_view_state.dart';
import 'widgets/chess_board.dart';
import '../../settings/domain/board_appearance.dart';
import '../../../app/app_services.dart';

class _ReviewBoard implements BoardViewState {
  _ReviewBoard(String fen) : rules = LocalChessRules(fen: fen);
  @override
  final GameRules rules;
  @override
  bool get flipped => false;
  @override
  String? get selected => null;
  @override
  String? get lastFrom => null;
  @override
  String? get lastTo => null;
  @override
  List<String> get targets => const [];
}

Future<void> showGameReview(
  BuildContext context, {
  required String initialFen,
  required List<String> moves,
}) async {
  GameReviewInsight? insight;
  try {
    insight = reviewGame(initialFen, moves);
  } catch (_) {}
  final appearance = AppScope.of(context).boardAppearance.value
      .copyWith(view: BoardViewMode.flat, showLegalMoves: false);
  var after = true;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (c) => StatefulBuilder(
      builder: (c, update) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bu maçtan ne öğrenebilirim?',
                    style: Theme.of(c).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (insight == null)
                    const Text('İncelenecek hamle bulunamadı.')
                  else ...[
                    Text(
                      insight.title,
                      style: Theme.of(c).textTheme.titleMedium,
                    ),
                    Text('${(insight.ply + 1) ~/ 2}. hamle · ${insight.move}'),
                    const SizedBox(height: 8),
                    ChessBoard(
                      controller: _ReviewBoard(
                        after ? insight.afterFen : insight.beforeFen,
                      ),
                      appearance: appearance,
                      allowMoveHints: false,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Önce')),
                        ButtonSegment(value: true, label: Text('Sonra')),
                      ],
                      selected: {after},
                      onSelectionChanged: (s) => update(() => after = s.first),
                    ),
                    const SizedBox(height: 12),
                    Text(insight.explanation),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'Temel inceleme · İnternetsiz\nTaş alışları, rok, terfi ve şah/mat olaylarını gösterir. Tam motor analizi değildir.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
