import 'package:flutter_test/flutter_test.dart';
import 'package:chess_platform/features/game/data/local_chess_rules.dart';
import 'package:chess_platform/features/game/presentation/game_controller.dart';

void main() {
  test('rejects illegal moves and preserves the turn', () {
    final rules = LocalChessRules();
    expect(rules.move('e2', 'e5'), false);
    expect(rules.whiteToMove, true);
    expect(rules.move('e2', 'e4'), true);
    expect(rules.whiteToMove, false);
    expect(rules.move('d2', 'd4'), false);
    expect(rules.history, ['e4']);
    rules.undo();
    expect(rules.pieceAt('e2')?.type, 'p');
    expect(rules.history, isEmpty);
  });
  test('recognizes checkmate and undo restores an active game', () {
    final rules = LocalChessRules();
    for (final move in [
      ['f2', 'f3'],
      ['e7', 'e5'],
      ['g2', 'g4'],
      ['d8', 'h4'],
    ]) {
      expect(rules.move(move[0], move[1]), true);
    }
    expect(rules.isOver, true);
    expect(rules.status, 'Mat · Siyah kazandı');
    rules.undo();
    expect(rules.isOver, false);
  });
  test('castling moves the rook as well as the king', () {
    final rules = LocalChessRules(fen: 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
    expect(rules.move('e1', 'g1'), true);
    expect(rules.pieceAt('f1')?.type, 'r');
    expect(rules.pieceAt('h1'), isNull);
  });
  test('en passant removes the captured pawn', () {
    final rules = LocalChessRules(fen: '4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1');
    expect(rules.move('e5', 'd6'), true);
    expect(rules.pieceAt('d5'), isNull);
  });
  test('underpromotion follows the chosen piece', () {
    final rules = LocalChessRules(fen: '4k3/P7/8/8/8/8/8/4K3 w - - 0 1');
    expect(rules.needsPromotion('a7', 'a8'), true);
    expect(rules.move('a7', 'a8', promotion: 'n'), true);
    expect(rules.pieceAt('a8')?.type, 'n');
  });
  test('controller only selects current player and tracks legal targets', () {
    final controller = GameController(LocalChessRules());
    controller.selectOrMove('e7');
    expect(controller.selected, isNull);
    controller.selectOrMove('e2');
    expect(controller.targets, containsAll(['e3', 'e4']));
    controller.selectOrMove('e4');
    expect(controller.lastTo, 'e4');
    expect(controller.selected, isNull);
    controller.dispose();
  });
}
