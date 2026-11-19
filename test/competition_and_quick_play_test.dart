import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:chess_platform/features/game/presentation/quick_play_controller.dart';
import 'package:chess_platform/features/game/domain/computer_difficulty.dart';
import 'package:chess_platform/features/game/domain/time_control.dart';
import 'package:chess_platform/features/game/data/game_review.dart';
import 'package:chess_platform/features/game/data/local_chess_rules.dart';
import 'package:chess_platform/features/leaderboard/domain/competition_score.dart';

void main() {
  test(
    'quick play persists mode, simple time and difficulty across restart',
    () async {
      String? value;
      QuickPlayController store() => QuickPlayController(
        read: () async => value,
        write: (v) async => value = v,
      );
      final first = store();
      await first.save(
        const QuickPlayChoice(
          mode: QuickPlayMode.computer,
          time: TimeControl(10, 5),
          clockEnabled: true,
          difficulty: ComputerDifficulty.hard,
        ),
      );
      final restored = store();
      await restored.load();
      expect(restored.value.difficulty, ComputerDifficulty.hard);
      expect(restored.value.route, contains('minutes=10&increment=5'));
      expect(restored.value.route, contains('opponent=computer'));
      first.dispose();
      restored.dispose();
    },
  );
  test(
    'corrupt quick play falls back; online can never be unlimited',
    () async {
      final store = QuickPlayController(
        read: () async => 'broken',
        write: (_) async {},
      );
      await store.load();
      expect(store.value.mode, QuickPlayMode.computer);
      final online = QuickPlayChoice.fromJson({
        'mode': 'online',
        'minutes': 3,
        'increment': 2,
        'clock': false,
        'difficulty': 'easy',
      });
      expect(online.clockEnabled, isTrue);
      expect(online.route, startsWith('/matchmaking'));
      expect(
        () => QuickPlayChoice.fromJson({...online.toJson(), 'minutes': 0}),
        throwsFormatException,
      );
      store.dispose();
    },
  );
  test('failed preference write preserves previously selected game', () async {
    final store = QuickPlayController(
      read: () async => null,
      write: (_) async => throw StateError('disk'),
    );
    await expectLater(
      store.save(const QuickPlayChoice(mode: QuickPlayMode.online)),
      throwsStateError,
    );
    expect(store.value.mode, QuickPlayMode.computer);
    store.dispose();
  });
  test(
    'weekly cup changes Monday midnight in Turkey; month uses Turkey time',
    () {
      final sunday = DateTime.parse('2026-10-04T20:59:59Z'),
          monday = DateTime.parse('2026-10-04T21:00:00Z');
      expect(competitionWeek(sunday), isNot(competitionWeek(monday)));
      expect(
        competitionWeek(monday),
        competitionWeek(DateTime.parse('2026-10-11T20:59:59Z')),
      );
      expect(
        competitionMonth(DateTime.parse('2026-09-30T21:00:00Z')),
        'm202610',
      );
    },
  );
  test('community points distinguish a win, draw and loss without Elo', () {
    expect(competitionPoints('white', true), 3);
    expect(competitionPoints('white', false), 0);
    expect(competitionPoints('draw', false), 1);
  });
  test(
    'post-game review identifies mate and preserves immutable move list',
    () {
      final moves = ['f3', 'e5', 'g4', 'Qh4#'], original = jsonEncode(moves);
      final review = reviewGame(LocalChessRules().fen, moves)!;
      expect(review.ply, 4);
      expect(review.title, 'Matı getiren hamle');
      expect(LocalChessRules(fen: review.afterFen).isOver, isTrue);
      expect(jsonEncode(moves), original);
    },
  );
  test(
    'material review describes a queen capture without claiming a blunder',
    () {
      final review = reviewGame('7k/8/8/8/8/8/q7/R6K w - - 0 1', ['Rxa2'])!;
      expect(review.title, 'Vezir alışı');
      expect(review.explanation, contains('vezir'));
      expect(reviewGame(LocalChessRules().fen, []), isNull);
      expect(
        () => reviewGame(LocalChessRules().fen, ['e5']),
        throwsFormatException,
      );
    },
  );
}
