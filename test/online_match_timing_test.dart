import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:chess_platform/features/game/domain/online_match_timing.dart';
import 'package:chess_platform/features/game/domain/time_control.dart';
import 'package:chess_platform/features/game/presentation/quick_play_controller.dart';
import 'package:chess_platform/features/challenges/domain/challenge_invite.dart';

void main() {
  final start = DateTime.utc(2026, 10, 5);
  OnlineMatchTiming timing(
    int elapsed, {
    int white = 600000,
    int black = 600000,
    bool whiteToMove = true,
    int limit = 180,
    bool finished = false,
  }) => OnlineMatchTiming(
    whiteMilliseconds: white,
    blackMilliseconds: black,
    whiteToMove: whiteToMove,
    lastMoveAt: start,
    now: start.add(Duration(milliseconds: elapsed)),
    turnLimitSeconds: limit,
    boardFinished: finished,
  );

  test('three-minute turn expires exactly at deadline and freezes clocks', () {
    expect(timing(179999).timeoutReason, isNull);
    expect(timing(179999).turnRemainingMilliseconds, 1);
    final end = timing(180000);
    expect(end.timeoutReason, MatchTimeoutReason.inactivity);
    expect(end.whiteRemaining, 420000);
    expect(end.blackRemaining, 600000);
    expect(end.turnRemainingMilliseconds, 0);
    expect(timing(600000).timeoutReason, MatchTimeoutReason.inactivity);
    expect(timing(600000).whiteRemaining, 420000);
  });
  test('black inactivity loses black, and a new move grants a fresh turn', () {
    final end = timing(180000, whiteToMove: false);
    expect(end.blackRemaining, 420000);
    expect(end.whiteRemaining, 600000);
    final next = OnlineMatchTiming(
      whiteMilliseconds: 480000,
      blackMilliseconds: 600000,
      whiteToMove: false,
      lastMoveAt: start.add(const Duration(minutes: 2)),
      now: start.add(const Duration(minutes: 2)),
      turnLimitSeconds: 180,
    );
    expect(next.turnRemainingMilliseconds, 180000);
    expect(next.timeoutReason, isNull);
  });
  test('total clock may expire earlier; backward local time never grants extra time', () {
    expect(timing(60000, white: 60000).timeoutReason, MatchTimeoutReason.clock);
    expect(
      timing(180000, white: 180000).timeoutReason,
      MatchTimeoutReason.clock,
    );
    expect(timing(-10000).turnRemainingMilliseconds, 180000);
    expect(timing(-10000).whiteRemaining, 600000);
  });
  test('completed board and legacy matches retain their established rules', () {
    expect(timing(300000, finished: true).timeoutReason, isNull);
    expect(timing(300000, finished: true).whiteRemaining, 600000);
    expect(timing(300000, limit: 0).timeoutReason, isNull);
    expect(timing(300000, limit: 0).turnRemainingMilliseconds, isNull);
    expect(timing(600000, limit: 0).timeoutReason, MatchTimeoutReason.clock);
  });
  test(
    'long choices are primary; new and migrated games start at ten minutes',
    () async {
      expect(TimeControl.presets.map((v) => v.minutes), [10, 15, 30, 60]);
      expect(const QuickPlayChoice().time.minutes, 10);
      String? stored = jsonEncode({
        'mode': 'online',
        'minutes': 3,
        'increment': 2,
        'clock': true,
        'difficulty': 'easy',
      });
      final choices = QuickPlayController(
        read: () async => stored,
        write: (v) async => stored = v,
      );
      await choices.load();
      expect(choices.value.time.minutes, 10);
      await choices.save(
        const QuickPlayChoice(
          mode: QuickPlayMode.online,
          time: TimeControl(3, 2),
        ),
      );
      await choices.load();
      expect(choices.value.time.minutes, 3);
      expect(choices.value.time.incrementSeconds, 2);
      choices.dispose();
    },
  );
  test(
    'WhatsApp shares the custom rule; legacy invite does not invent one',
    () {
      final invite = ChallengeInvite(
        id: 'a' * 40,
        timeControl: const TimeControl(10, 0),
        expiresAt: start.add(const Duration(days: 1)),
        publicUrl: Uri.parse(
          'https://satranc-platformu.web.app/challenge/${'a' * 40}',
        ),
        turnLimitSeconds: 180,
      );
      final restored = ChallengeInvite.fromJson(invite.toJson());
      expect(restored.turnLimitSeconds, 180);
      expect(restored.shareText, contains('3 dakika hamle yapmazsa'));
      final legacy = ChallengeInvite.fromJson(
        {...invite.toJson()}..remove('turnLimitSeconds'),
      );
      expect(legacy.shareText, isNot(contains('3 dakika hamle yapmazsa')));
    },
  );
}
