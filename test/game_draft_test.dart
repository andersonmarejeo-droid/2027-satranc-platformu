import 'dart:async';
import 'dart:convert';

import 'package:chess_platform/features/game/data/local_chess_rules.dart';
import 'package:chess_platform/features/game/data/local_game_draft_repository.dart';
import 'package:chess_platform/features/game/domain/clock_state.dart';
import 'package:chess_platform/features/game/domain/game_draft.dart';
import 'package:chess_platform/features/game/domain/game_result.dart';
import 'package:chess_platform/features/game/domain/saved_game.dart';
import 'package:chess_platform/features/game/domain/time_control.dart';
import 'package:chess_platform/features/game/presentation/game_controller.dart';
import 'package:chess_platform/features/game/presentation/game_draft_controller.dart';
import 'package:flutter_test/flutter_test.dart';

GameDraft draftFixture({bool clockEnabled = true, int id = 1}) {
  final controller = GameController(
    LocalChessRules(),
    timeControl: const TimeControl(3, 2),
    clockEnabled: clockEnabled,
  );
  final initialFen = controller.rules.fen;
  for (final move in [('e2', 'e4'), ('e7', 'e5'), ('g1', 'f3')]) {
    controller.selectOrMove(move.$1);
    controller.selectOrMove(move.$2);
  }
  controller.clock.pause();
  controller.flip();
  final draft = capture(
    controller,
    initialFen,
    id: id,
    clockEnabled: clockEnabled,
  );
  controller.dispose();
  return draft;
}

GameDraft capture(
  GameController controller,
  String initialFen, {
  int id = 1,
  bool clockEnabled = true,
}) {
  final clock = controller.clock.exportState();
  final result = clock.flagged
      ? (clock.position.activeWhite
            ? GameResult.blackWins
            : GameResult.whiteWins)
      : controller.rules.result;
  return GameDraft(
    game: SavedGame(
      id: id.toRadixString(16).padLeft(32, '0'),
      savedAt: DateTime(2026, 10, 3, 15, 30),
      initialFen: initialFen,
      moves: controller.rules.history,
      timeControl: const TimeControl(3, 2),
      clockEnabled: clockEnabled,
      result: result,
    ),
    clock: clock,
    flipped: controller.flipped,
    lastFrom: controller.lastFrom,
    lastTo: controller.lastTo,
  );
}

void main() {
  test(
    'draft survives storage recreation with full moves, clocks and orientation',
    () async {
      String? stored;
      LocalGameDraftRepository repository() => LocalGameDraftRepository(
        read: () async => stored,
        write: (value) async {
          stored = value;
        },
        remove: () async {
          stored = null;
        },
      );
      final draft = draftFixture();
      await repository().save(draft);
      final loaded = (await repository().load())!;
      expect(loaded.toJson(), draft.toJson());
      final restored = GameController.restore(loaded);
      addTearDown(restored.dispose);
      expect(restored.rules.history, ['e4', 'e5', 'Nf3']);
      expect(restored.rules.pieceAt('f3')?.type, 'n');
      expect(restored.clock.isPaused, true);
      expect(restored.clock.activeWhite, false);
      expect(restored.flipped, true);
      expect(restored.lastTo, 'f3');
      expect(restored.clock.exportState().toJson(), draft.clock.toJson());
    },
  );

  test('restored takeback restores board and pre-increment clocks and stays paused', () {
    final draft = draftFixture();
    final restored = GameController.restore(draft);
    addTearDown(restored.dispose);
    final previous = draft.clock.undo.last;
    restored.undo();
    expect(restored.rules.history, ['e4', 'e5']);
    expect(restored.rules.pieceAt('g1')?.type, 'n');
    expect(
      restored.clock.whiteRemaining.inMilliseconds,
      previous.whiteMilliseconds,
    );
    expect(
      restored.clock.blackRemaining.inMilliseconds,
      previous.blackMilliseconds,
    );
    expect(restored.clock.isPaused, true);
    expect(restored.clock.activeWhite, true);
    expect(restored.clock.exportState().undo.length, 2);
  });

  test('restoring full history preserves threefold repetition rather than only FEN', () {
    final original = GameController(
      LocalChessRules(),
      timeControl: const TimeControl(3, 2),
      clockEnabled: false,
    );
    addTearDown(original.dispose);
    final fen = original.rules.fen;
    for (var round = 0; round < 2; round++) {
      for (final move in [
        ('g1', 'f3'),
        ('g8', 'f6'),
        ('f3', 'g1'),
        ('f6', 'g8'),
      ]) {
        original.selectOrMove(move.$1);
        expect(original.selectOrMove(move.$2), true);
      }
    }
    expect(original.rules.result, GameResult.draw);
    final restored = GameController.restore(
      capture(original, fen, clockEnabled: false),
    );
    addTearDown(restored.dispose);
    expect(restored.rules.result, GameResult.draw);
    expect(restored.clock.hasEnded, true);
    restored.clock.resume();
    expect(restored.selectOrMove('e2'), false);
  });

  test('expired clock survives restore and cannot restart', () {
    final base = draftFixture();
    final json = base.toJson();
    final game = Map<String, dynamic>.from(base.game.toJson())
      ..['result'] = GameResult.whiteWins.name;
    final clock = Map<String, dynamic>.from(base.clock.toJson())
      ..['flagged'] = true
      ..['position'] = {
        'whiteMilliseconds': base.clock.position.whiteMilliseconds,
        'blackMilliseconds': 0,
        'activeWhite': false,
      };
    json['game'] = game;
    json['clock'] = clock;
    final restored = GameController.restore(GameDraft.fromJson(json));
    addTearDown(restored.dispose);
    expect(restored.clock.whiteWonOnTime, true);
    restored.clock.resume();
    expect(restored.clock.isFlagged, true);
    expect(restored.clock.blackRemaining, Duration.zero);
  });

  test(
    'illegal move, wrong turn and missing clock undo history are rejected',
    () {
      final base = draftFixture();
      final wrongClock = ClockState(
        position: ClockSnapshot(
          whiteMilliseconds: 180000,
          blackMilliseconds: 180000,
          activeWhite: true,
        ),
        flagged: false,
        endedByRules: false,
        undo: base.clock.undo,
      );
      expect(
        () => GameController.restore(
          GameDraft(game: base.game, clock: wrongClock, flipped: false),
        ),
        throwsFormatException,
      );
      final json = base.toJson();
      json['clock'] = {...base.clock.toJson(), 'undo': []};
      expect(() => GameDraft.fromJson(json), throwsFormatException);
      expect(
        () => LocalChessRules.fromHistory(
          initialFen: base.game.initialFen,
          moves: ['e5'],
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'serialized saves and clear cannot let an older write replace a new game',
    () async {
      String? stored;
      final gate = Completer<void>();
      var writes = 0;
      final repository = LocalGameDraftRepository(
        read: () async => stored,
        write: (value) async {
          if (writes++ == 0) await gate.future;
          stored = value;
        },
        remove: () async {
          stored = null;
        },
      );
      final first = repository.save(draftFixture(id: 1));
      final clear = repository.clear();
      final last = repository.save(draftFixture(id: 2));
      gate.complete();
      await Future.wait([first, clear, last]);
      expect((await repository.load())!.game.id, draftFixture(id: 2).game.id);
    },
  );

  test(
    'storage failures keep the in-memory draft and a later retry succeeds',
    () async {
      String? stored;
      var fail = true;
      final store = GameDraftController(
        LocalGameDraftRepository(
          read: () async => stored,
          write: (value) async {
            if (fail) throw StateError('Disk unavailable');
            stored = value;
          },
          remove: () async {
            if (fail) throw StateError('Disk unavailable');
            stored = null;
          },
        ),
      );
      addTearDown(store.dispose);
      final draft = draftFixture();
      await expectLater(store.save(draft), throwsStateError);
      expect(store.draft, draft);
      expect(store.hasError, true);
      await expectLater(store.clear(), throwsStateError);
      expect(store.draft, draft);
      fail = false;
      await store.save(draft);
      expect(store.hasError, false);
      expect(store.isSaving, false);
      await store.clear();
      expect(store.draft, isNull);
      expect(stored, isNull);
    },
  );

  test('corrupt or unsupported persisted drafts expose an error instead of a fresh game', () async {
    String? stored = 'invalid JSON';
    final repository = LocalGameDraftRepository(
      read: () async => stored,
      write: (value) async {
        stored = value;
      },
      remove: () async {
        stored = null;
      },
    );
    final store = GameDraftController(repository);
    addTearDown(store.dispose);
    await store.load();
    expect(store.hasError, true);
    expect(store.draft, isNull);
    stored = jsonEncode({'version': 99, 'draft': {}});
    await expectLater(repository.load(), throwsFormatException);
    await store.clear();
    expect(store.hasError, false);
  });
}
