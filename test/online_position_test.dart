import 'package:flutter_test/flutter_test.dart';
import 'package:chess_platform/features/game/data/online_position.dart';
import 'package:chess_platform/features/game/domain/game_result.dart';

void main() {
  test('both players reconstruct a legal game and checkmate', () {
    final game = OnlinePosition(['f2f3', 'e7e5', 'g2g4', 'd8h4']);
    expect(game.result, GameResult.blackWins);
    expect(game.rules.history.last, contains('#'));
  });
  test('reject illegal turn, history injection and moves after mate', () {
    for (final moves in [
      ['e7e5'],
      ['e2e5'],
      ['garbage'],
      ['f2f3', 'e7e5', 'g2g4', 'd8h4', 'a2a3'],
    ]) {
      expect(() => OnlinePosition(moves), throwsFormatException);
    }
  });
  test('castling history remains reproducible', () {
    final moves = ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', 'g8f6', 'e1g1'];
    final a = OnlinePosition(moves), b = OnlinePosition(moves);
    expect(a.rules.fen, b.rules.fen);
    expect(a.rules.pieceAt('g1')!.type, 'k');
    expect(a.rules.pieceAt('f1')!.type, 'r');
  });
}
