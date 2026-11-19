import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/time_control.dart';
import '../domain/clock_state.dart';

class ChessClockController extends ChangeNotifier {
  ChessClockController(
    this.timeControl, {
    required this.enabled,
    ClockState? state,
    bool initiallyPaused = false,
    bool activeWhite = true,
  }) : _initial = Duration(minutes: timeControl.minutes),
       _whiteRemaining = Duration(minutes: timeControl.minutes),
       _blackRemaining = Duration(minutes: timeControl.minutes) {
    _paused = initiallyPaused || state != null;
    _activeWhite = activeWhite;
    if (state != null) {
      _whiteRemaining = Duration(
        milliseconds: state.position.whiteMilliseconds,
      );
      _blackRemaining = Duration(
        milliseconds: state.position.blackMilliseconds,
      );
      _activeWhite = state.position.activeWhite;
      _flagged = state.flagged;
      _flaggedWhite = _activeWhite;
      _endedByRules = state.endedByRules;
      _undo.addAll(state.undo);
    }
    if (enabled && !_paused && !hasEnded) _startTurn();
  }

  final TimeControl timeControl;
  final bool enabled;
  final Duration _initial;
  final Stopwatch _turnWatch = Stopwatch();
  Timer? _ticker;
  Duration _whiteRemaining;
  Duration _blackRemaining;
  bool _activeWhite = true;
  bool _flaggedWhite = false;
  bool _flagged = false;
  bool _endedByRules = false;
  bool _paused = false;
  final List<ClockSnapshot> _undo = [];

  Duration get whiteRemaining => whiteRemainingFor(true);
  Duration get blackRemaining => whiteRemainingFor(false);
  bool get activeWhite => _activeWhite;
  bool get isFlagged => _flagged;
  bool get hasEnded => _flagged || _endedByRules;
  bool get isPaused => _paused;
  bool get whiteWonOnTime => _flagged && !_flaggedWhite;
  bool get blackWonOnTime => _flagged && _flaggedWhite;
  bool get canUndo => !enabled || _undo.isNotEmpty;

  String get status => _flagged
      ? '${_flaggedWhite ? 'Beyaz' : 'Siyah'} süresi doldu · ${_flaggedWhite ? 'Siyah' : 'Beyaz'} kazandı'
      : _endedByRules
      ? 'Oyun tamamlandı'
      : _paused
      ? 'Oyun duraklatıldı'
      : 'Oyun devam ediyor';

  ClockState exportState() {
    final wasFlagged = _flagged;
    _settleActive();
    final state = ClockState(
      position: _snapshot(),
      flagged: _flagged,
      endedByRules: _endedByRules,
      undo: _undo,
    );
    if (wasFlagged != _flagged) notifyListeners();
    return state;
  }

  ClockSnapshot _snapshot() => ClockSnapshot(
    whiteMilliseconds: _whiteRemaining.inMilliseconds,
    blackMilliseconds: _blackRemaining.inMilliseconds,
    activeWhite: _activeWhite,
  );

  void pause() {
    if (_paused) return;
    _settleActive();
    _paused = true;
    _turnWatch.stop();
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
  }

  void resume() {
    if (!_paused || hasEnded) return;
    _paused = false;
    if (enabled) _startTurn();
    notifyListeners();
  }

  String textFor(bool white) => format(whiteRemainingFor(white));

  Duration whiteRemainingFor(bool white) {
    if (enabled && !_flagged && !_endedByRules && _activeWhite == white) {
      _settleActive();
    }
    return white ? _whiteRemaining : _blackRemaining;
  }

  static String format(Duration remaining) {
    final milliseconds = remaining.inMilliseconds.clamp(0, 1 << 62);
    final totalSeconds = (milliseconds / 1000).ceil();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool commitMove({
    required bool movedWhite,
    required bool Function() applyMove,
    required bool Function() gameEnded,
  }) {
    if (_paused) return false;
    if (!enabled) {
      final committed = applyMove();
      if (committed) {
        _activeWhite = !movedWhite;
        _endedByRules = gameEnded();
        notifyListeners();
      }
      return committed;
    }
    _settleActive();
    if (_flagged || _endedByRules || movedWhite != _activeWhite) {
      notifyListeners();
      return false;
    }

    _turnWatch.stop();
    _undo.add(_snapshot());
    final committed = applyMove();
    if (!committed) {
      _undo.removeLast();
      _turnWatch.start();
      return false;
    }

    final increment = Duration(seconds: timeControl.incrementSeconds);
    if (movedWhite) {
      _whiteRemaining += increment;
    } else {
      _blackRemaining += increment;
    }

    _activeWhite = !movedWhite;
    if (gameEnded()) {
      _endedByRules = true;
      _ticker?.cancel();
      _ticker = null;
      _turnWatch.stop();
    } else {
      _startTurn();
    }
    notifyListeners();
    return true;
  }

  void undoMove() {
    if (!enabled) {
      _activeWhite = !_activeWhite;
      _endedByRules = false;
      notifyListeners();
      return;
    }
    if (_undo.isEmpty) return;
    final snapshot = _undo.removeLast();
    _whiteRemaining = Duration(milliseconds: snapshot.whiteMilliseconds);
    _blackRemaining = Duration(milliseconds: snapshot.blackMilliseconds);
    _activeWhite = snapshot.activeWhite;
    _flagged = false;
    _flaggedWhite = false;
    _endedByRules = false;
    _startTurn();
    notifyListeners();
  }

  void reset() {
    _ticker?.cancel();
    _ticker = null;
    _turnWatch
      ..stop()
      ..reset();
    _whiteRemaining = _initial;
    _blackRemaining = _initial;
    _activeWhite = true;
    _flagged = false;
    _flaggedWhite = false;
    _endedByRules = false;
    _paused = false;
    _undo.clear();
    if (enabled) _startTurn();
    notifyListeners();
  }

  bool endByAgreement() {
    _settleActive();
    if (hasEnded) return false;
    _endedByRules = true;
    _turnWatch.stop();
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
    return true;
  }

  void _startTurn() {
    if (!enabled || _paused || hasEnded) return;
    _turnWatch
      ..reset()
      ..start();
    _ticker ??= Timer.periodic(const Duration(milliseconds: 100), _tick);
  }

  void _tick(Timer timer) {
    final whiteText = format(_whiteRemaining);
    final blackText = format(_blackRemaining);
    _settleActive();
    if (whiteText != format(_whiteRemaining) ||
        blackText != format(_blackRemaining) ||
        _flagged) {
      notifyListeners();
    }
  }

  void _settleActive() {
    if (!enabled ||
        _paused ||
        _flagged ||
        _endedByRules ||
        !_turnWatch.isRunning) {
      return;
    }
    final elapsed = _turnWatch.elapsed;
    if (elapsed <= Duration.zero) return;
    final current = _activeWhite ? _whiteRemaining : _blackRemaining;
    final next = current - elapsed;
    _turnWatch.reset();
    if (next <= Duration.zero) {
      if (_activeWhite) {
        _whiteRemaining = Duration.zero;
      } else {
        _blackRemaining = Duration.zero;
      }
      _flaggedWhite = _activeWhite;
      _flagged = true;
      _turnWatch.stop();
      _ticker?.cancel();
      _ticker = null;
      return;
    }
    if (_activeWhite) {
      _whiteRemaining = next;
    } else {
      _blackRemaining = next;
    }
    _turnWatch.start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _turnWatch.stop();
    super.dispose();
  }
}
