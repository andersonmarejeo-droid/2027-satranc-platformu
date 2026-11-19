import 'package:flutter_test/flutter_test.dart';
import 'package:chess_platform/features/game/domain/time_control.dart';
import 'package:chess_platform/features/game/presentation/chess_clock_controller.dart';

void main() {
  test('an expired clock checkpoint notifies once and preserves the flag', () {
    final clock = ChessClockController(const TimeControl(0, 0), enabled: true);
    addTearDown(clock.dispose);
    var notifications = 0;
    clock.addListener(() => notifications++);
    final state = clock.exportState();
    expect(state.flagged, true);
    expect(notifications, 1);
    clock.exportState();
    expect(notifications, 1);
  });
  test(
    'pause freezes time and restore resumes only after an explicit action',
    () async {
      final original = ChessClockController(
        const TimeControl(3, 2),
        enabled: true,
      );
      addTearDown(original.dispose);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      original.pause();
      final remaining = original.whiteRemaining;
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(original.whiteRemaining, remaining);
      expect(
        original.commitMove(
          movedWhite: true,
          applyMove: () => true,
          gameEnded: () => false,
        ),
        false,
      );
      final restored = ChessClockController(
        const TimeControl(3, 2),
        enabled: true,
        state: original.exportState(),
      );
      addTearDown(restored.dispose);
      final stored = restored.whiteRemaining;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(restored.whiteRemaining, stored);
      restored.resume();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(restored.whiteRemaining, lessThan(stored));
      expect(restored.activeWhite, true);
    },
  );
  test(
    'clock counts time, grants increment, and restores a takeback',
    () async {
      final clock = ChessClockController(
        const TimeControl(1, 2),
        enabled: true,
      );
      addTearDown(clock.dispose);

      await Future<void>.delayed(const Duration(milliseconds: 1100));
      final whiteBeforeMove = clock.whiteRemaining;
      expect(whiteBeforeMove, lessThan(const Duration(minutes: 1)));

      expect(
        clock.commitMove(
          movedWhite: true,
          applyMove: () => true,
          gameEnded: () => false,
        ),
        isTrue,
      );
      final whiteAfterMove = clock.whiteRemaining;
      expect(
        whiteAfterMove,
        greaterThan(whiteBeforeMove + const Duration(milliseconds: 1500)),
      );
      expect(clock.activeWhite, isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 300));
      final blackBeforeMove = clock.blackRemaining;
      expect(blackBeforeMove, lessThan(const Duration(minutes: 1)));
      expect(
        clock.commitMove(
          movedWhite: false,
          applyMove: () => true,
          gameEnded: () => false,
        ),
        isTrue,
      );
      expect(
        clock.blackRemaining,
        greaterThan(blackBeforeMove + const Duration(milliseconds: 1500)),
      );

      clock.undoMove();
      expect(clock.activeWhite, isFalse);
      expect(clock.blackRemaining, lessThan(const Duration(minutes: 1)));
      expect(clock.isFlagged, isFalse);
    },
  );

  test('disabled practice clock stays unchanged and awards no increment', () {
    final clock = ChessClockController(const TimeControl(3, 2), enabled: false);
    addTearDown(clock.dispose);
    expect(clock.textFor(true), '03:00');
    expect(
      clock.commitMove(
        movedWhite: true,
        applyMove: () => true,
        gameEnded: () => false,
      ),
      isTrue,
    );
    expect(clock.whiteRemaining, const Duration(minutes: 3));
    expect(clock.textFor(false), '03:00');
  });

  test('flags the active side when its time runs out', () async {
    final clock = ChessClockController(const TimeControl(0, 0), enabled: true);
    addTearDown(clock.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(clock.isFlagged, isTrue);
    expect(clock.whiteRemaining, Duration.zero);
    expect(clock.blackWonOnTime, isTrue);
    expect(clock.status, contains('Siyah kazandı'));
  });
}
