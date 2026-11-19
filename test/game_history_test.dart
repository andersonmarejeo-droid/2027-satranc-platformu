import 'dart:convert';

import 'package:chess/chess.dart' as chess;
import 'package:chess_platform/features/game/data/local_chess_rules.dart';
import 'package:chess_platform/features/game/data/local_game_history_repository.dart';
import 'package:chess_platform/features/game/data/local_game_playback.dart';
import 'package:chess_platform/features/game/domain/game_result.dart';
import 'package:chess_platform/features/game/domain/saved_game.dart';
import 'package:chess_platform/features/game/domain/time_control.dart';
import 'package:chess_platform/features/game/presentation/game_replay_controller.dart';
import 'package:flutter_test/flutter_test.dart';

SavedGame record({
  int id = 1,
  List<String> moves = const ['e4'],
  String? fen,
  GameResult result = GameResult.unfinished,
}) => SavedGame(
  id: id.toRadixString(16).padLeft(32, '0'),
  savedAt: DateTime.utc(2026, 10, 3).add(Duration(minutes: id)),
  initialFen: fen ?? LocalChessRules().fen,
  moves: moves,
  timeControl: const TimeControl(3, 2),
  clockEnabled: true,
  result: result,
);

void main() {
  test(
    'records persist across repository recreation and save updates one game',
    () async {
      String? stored;
      LocalGameHistoryRepository repository() => LocalGameHistoryRepository(
        read: () async => stored,
        write: (value) async {
          stored = value;
        },
      );
      await repository().save(record());
      final reopened = repository();
      expect((await reopened.list()).single.moves, ['e4']);
      await reopened.save(record(moves: ['e4', 'e5']));
      expect((await repository().list()).single.moves, ['e4', 'e5']);
    },
  );

  test(
    'concurrent saves retain both games and storage keeps the latest 100',
    () async {
      String? stored;
      final repository = LocalGameHistoryRepository(
        read: () async => stored,
        write: (value) async {
          stored = value;
        },
      );
      await Future.wait([
        repository.save(record(id: 1)),
        repository.save(record(id: 2)),
      ]);
      expect((await repository.list()).length, 2);
      for (var id = 3; id <= 101; id++) {
        await repository.save(record(id: id));
      }
      final saved = await repository.list();
      expect(saved.length, 100);
      expect(saved.first.id, record(id: 101).id);
      expect(saved.any((game) => game.id == record(id: 1).id), false);
    },
  );

  test('a failed storage write surfaces and a later retry succeeds', () async {
    String? stored;
    var fail = true;
    final repository = LocalGameHistoryRepository(
      read: () async => stored,
      write: (value) async {
        if (fail) throw StateError('Storage unavailable');
        stored = value;
      },
    );
    await expectLater(repository.save(record()), throwsStateError);
    expect(await repository.list(), isEmpty);
    fail = false;
    await repository.save(record());
    expect((await repository.list()).single.id, record().id);
  });

  test(
    'malformed records do not hide valid history or crash the app',
    () async {
      String? stored = jsonEncode({
        'version': 1,
        'games': [
          {'id': 'bad'},
          record().toJson(),
          record().toJson(),
        ],
      });
      final repository = LocalGameHistoryRepository(
        read: () async => stored,
        write: (value) async {
          stored = value;
        },
      );
      expect((await repository.list()).length, 1);
      stored = 'broken JSON';
      expect(await repository.list(), isEmpty);
      stored = jsonEncode({'version': 42, 'games': []});
      expect(await repository.list(), isEmpty);
    },
  );

  test('playback seeks exact positions without changing the saved moves', () {
    final game = record(moves: ['e4', 'e5', 'Nf3']);
    final controller = GameReplayController(LocalGamePlayback(game));
    addTearDown(controller.dispose);
    expect(controller.rules.pieceAt('e2')?.type, 'p');
    controller.seek(1);
    expect(controller.rules.pieceAt('e2'), isNull);
    expect(controller.rules.pieceAt('e4')?.isWhite, true);
    controller.seek(99);
    expect(controller.index, 3);
    expect(controller.rules.pieceAt('f3')?.type, 'n');
    controller.seek(-1);
    expect(controller.index, 0);
    expect(controller.rules.pieceAt('g1')?.type, 'n');
    controller.flip();
    expect(controller.flipped, true);
    expect(game.moves, ['e4', 'e5', 'Nf3']);
  });

  test('castling, en passant and underpromotion replay from custom FEN', () {
    for (final fixture in [
      ('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1', 'e1', 'g1', 'q'),
      ('4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1', 'e5', 'd6', 'q'),
      ('4k3/P7/8/8/8/8/8/4K3 w - - 0 1', 'a7', 'a8', 'n'),
    ]) {
      final rules = LocalChessRules(fen: fixture.$1);
      expect(rules.move(fixture.$2, fixture.$3, promotion: fixture.$4), true);
      final replay = LocalGamePlayback(
        record(fen: fixture.$1, moves: rules.history),
      );
      expect(replay.frames.last, rules.fen);
      final imported = chess.Chess();
      expect(imported.load_pgn(replay.pgn), true);
      expect(imported.fen, rules.fen);
    }
  });

  test(
    'PGN includes clock and recorded result and imports the same final board',
    () {
      final game = record(
        moves: ['f3', 'e5', 'g4', 'Qh4#'],
        result: GameResult.blackWins,
      );
      final replay = LocalGamePlayback(game);
      expect(replay.pgn, contains('[Result "0-1"]'));
      expect(replay.pgn, contains('[TimeControl "180+2"]'));
      expect(replay.pgn.trim(), endsWith('0-1'));
      final imported = chess.Chess();
      expect(imported.load_pgn(replay.pgn), true);
      expect(imported.fen, replay.frames.last);
      expect(
        LocalChessRules(fen: replay.frames.last).result,
        GameResult.blackWins,
      );
    },
  );

  test(
    'invalid FEN and illegal saved moves fail with a readable screen path',
    () {
      expect(
        () => LocalGamePlayback(record(fen: 'invalid')),
        throwsFormatException,
      );
      expect(
        () => LocalGamePlayback(record(moves: ['e5'])),
        throwsFormatException,
      );
    },
  );
}
