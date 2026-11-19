import 'package:chess/chess.dart' as chess;
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_platform/features/game/data/local_computer_player.dart';
import 'package:chess_platform/features/game/domain/saved_game.dart';
import 'package:chess_platform/features/game/domain/computer_difficulty.dart';

import 'widget_test.dart' show previewGame;

void main() {
  test('every difficulty returns legal moves and finds an immediate mate', () {
    for (final level in ComputerDifficulty.values) {
      final board = chess.Chess()..move('e4');
      final fen = board.fen;
      expect(
        board.move(chooseComputerMove(fen, difficulty: level)),
        isTrue,
        reason: level.label,
      );
      final mate = chess.Chess.fromFEN('6k1/5ppp/8/8/8/8/5PPP/3R2K1 w - - 0 1');
      expect(
        mate.move(chooseComputerMove(mate.fen, difficulty: level)),
        isTrue,
      );
      expect(mate.in_checkmate, isTrue, reason: level.label);
    }
  });
  test('medium sees the recapture that easy overlooks', () {
    const fen = '3q2k1/8/8/8/8/8/3r4/3Q2K1 w - - 0 1';
    final easy = chooseComputerMove(fen, difficulty: ComputerDifficulty.easy)!;
    final medium = chooseComputerMove(
      fen,
      difficulty: ComputerDifficulty.medium,
    )!;
    expect(easy['to'], 'd2');
    expect(medium['to'], isNot('d2'));
    expect(chess.Chess.fromFEN(fen).move(medium), isTrue);
  });
  test('interrupted search still returns a legal fallback', () {
    final board = chess.Chess()..move('e4');
    final reply = chooseComputerMove(
      board.fen,
      difficulty: ComputerDifficulty.master,
      nodeLimit: 1,
    );
    expect(board.move(reply), isTrue);
  });
  test(
    'saved difficulty round-trips and legacy games keep their old level',
    () {
      final json = previewGame().toJson()
        ..remove('difficulty')
        ..['opponent'] = 'computer';
      expect(SavedGame.fromJson(json).difficulty, ComputerDifficulty.medium);
      json['difficulty'] = 'master';
      final saved = SavedGame.fromJson(json);
      expect(
        SavedGame.fromJson(saved.toJson()).difficulty,
        ComputerDifficulty.master,
      );
      json['difficulty'] = 'unknown';
      expect(() => SavedGame.fromJson(json), throwsFormatException);
    },
  );
  test('offline opponent chooses a legal reply and a forced mate', () {
    final board = chess.Chess()..move('e4');
    final reply = chooseComputerMove(board.fen);
    expect(reply, isNotNull);
    expect(board.move(reply), isTrue);
    final mate = chess.Chess.fromFEN('6k1/5ppp/8/8/8/8/5PPP/3R2K1 w - - 0 1');
    expect(mate.move(chooseComputerMove(mate.fen)), isTrue);
    expect(mate.in_checkmate, isTrue);
    expect(chooseComputerMove(mate.fen), isNull);
  });
  test(
    'computer promotions are legal and old saved games default to two players',
    () {
      final board = chess.Chess.fromFEN('7k/8/8/8/8/8/p7/7K b - - 0 1');
      final move = chooseComputerMove(board.fen);
      expect(move!['promotion'], isNotEmpty);
      expect(board.move(move), isTrue);
      expect(board.get('a1')!.type.name, 'q');
      final old = previewGame().toJson()..remove('opponent');
      expect(SavedGame.fromJson(old).opponent, GameOpponent.twoPlayers);
      old['opponent'] = 'computer';
      expect(SavedGame.fromJson(old).opponent, GameOpponent.computer);
      old['opponent'] = 'bad';
      expect(() => SavedGame.fromJson(old), throwsFormatException);
    },
  );
}
