import 'dart:math';

enum MatchTimeoutReason { clock, inactivity }

/// Both limits start from the server's last accepted move, never from presence
/// or screen activity. An expired game freezes at its first deadline.
class OnlineMatchTiming {
  OnlineMatchTiming({
    required this.whiteMilliseconds,
    required this.blackMilliseconds,
    required this.whiteToMove,
    required DateTime lastMoveAt,
    required DateTime now,
    this.turnLimitSeconds = 0,
    this.boardFinished = false,
  }) : elapsedMilliseconds = max(0, now.difference(lastMoveAt).inMilliseconds);

  static const defaultTurnLimitSeconds = 180;
  static const ruleDescription =
      'Sırası gelen oyuncu 3 dakika hamle yapmazsa rakibi kazanır. '
      'Hamle yapılınca sayaç yenilenir; toplam oyun saati ayrıca işler.';
  final int whiteMilliseconds, blackMilliseconds;
  final bool whiteToMove, boardFinished;
  final int turnLimitSeconds, elapsedMilliseconds;
  int get _activeClock => whiteToMove ? whiteMilliseconds : blackMilliseconds;
  bool get hasTurnLimit => turnLimitSeconds == defaultTurnLimitSeconds;
  int get _deadline =>
      hasTurnLimit ? min(_activeClock, turnLimitSeconds * 1000) : _activeClock;
  int get _charged =>
      boardFinished ? 0 : min(elapsedMilliseconds, max(0, _deadline));
  int get whiteRemaining =>
      max(0, whiteMilliseconds - (whiteToMove ? _charged : 0));
  int get blackRemaining =>
      max(0, blackMilliseconds - (!whiteToMove ? _charged : 0));
  int? get turnRemainingMilliseconds => !hasTurnLimit || boardFinished
      ? null
      : max(0, _deadline - elapsedMilliseconds);
  MatchTimeoutReason? get timeoutReason {
    if (boardFinished || elapsedMilliseconds < _deadline) return null;
    return hasTurnLimit && turnLimitSeconds * 1000 < _activeClock
        ? MatchTimeoutReason.inactivity
        : MatchTimeoutReason.clock;
  }
}
