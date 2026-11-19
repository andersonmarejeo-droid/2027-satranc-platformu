import 'package:flutter/foundation.dart';

import '../domain/time_control.dart';
import '../domain/game_rules.dart';
import '../domain/clock_state.dart';
import '../domain/game_draft.dart';
import '../domain/game_result.dart';
import '../data/local_chess_rules.dart';
import 'board_view_state.dart';
import 'chess_clock_controller.dart';

class GameController extends ChangeNotifier implements BoardViewState {
  GameController(
    this.rules, {
    TimeControl timeControl = const TimeControl(10, 0),
    bool clockEnabled = false,
    ClockState? clockState,
    bool initiallyPaused = false,
  }) : clock = ChessClockController(
         timeControl,
         enabled: clockEnabled,
         state: clockState,
         initiallyPaused: initiallyPaused,
         activeWhite: rules.whiteToMove,
       ) {
    clock.addListener(_clockChanged);
  }

  factory GameController.restore(GameDraft draft) {
    GameDraft.fromJson(draft.toJson());
    final rules = LocalChessRules.fromHistory(
      initialFen: draft.game.initialFen,
      moves: draft.game.moves,
    );
    final initialWhite = LocalChessRules(fen: draft.game.initialFen)
        .whiteToMove;
    if (draft.game.agreedDraw) {
      if (rules.isOver) throw const FormatException('Invalid agreed draw');
      rules.agreeDraw();
    } else if (draft.game.resigned) {
      if (rules.isOver) throw const FormatException('Invalid resigned game');
      rules.resign(white: draft.game.result == GameResult.blackWins);
    }
    for (var i = 0; i < draft.clock.undo.length; i++) {
      if (draft.clock.undo[i].activeWhite !=
          (i.isEven ? initialWhite : !initialWhite)) {
        throw const FormatException('Invalid clock turn history');
      }
    }
    final result = draft.clock.flagged
        ? (draft.clock.position.activeWhite
              ? GameResult.blackWins
              : GameResult.whiteWins)
        : rules.result;
    if (draft.clock.position.activeWhite != rules.whiteToMove ||
        draft.clock.endedByRules != rules.isOver ||
        result != draft.game.result) {
      throw const FormatException('Draft position and clock disagree');
    }
    return GameController(
        rules,
        timeControl: draft.game.timeControl,
        clockEnabled: draft.game.clockEnabled,
        clockState: draft.clock,
      )
      ..flipped = draft.flipped
      ..lastFrom = draft.lastFrom
      ..lastTo = draft.lastTo;
  }

  @override
  final GameRules rules;
  final ChessClockController clock;
  @override
  String? selected;
  @override
  String? lastFrom, lastTo;
  @override
  bool flipped = false;
  bool _updatingPosition = false;
  @override
  List<String> get targets =>
      selected == null ? [] : rules.destinations(selected!);
  bool get canUndo => rules.history.isNotEmpty && clock.canUndo;

  String get status => clock.isFlagged || (!rules.isOver && clock.isPaused)
      ? clock.status
      : rules.status;

  bool selectOrMove(String square, {String promotion = 'q'}) {
    if (rules.isOver || clock.isFlagged || clock.isPaused) return false;
    if (selected != null && targets.contains(square)) {
      return playMove(selected!, square, promotion: promotion);
    }
    final piece = rules.pieceAt(square);
    selected =
        piece != null &&
            piece.isWhite == rules.whiteToMove &&
            selected != square
        ? square
        : null;
    notifyListeners();
    return false;
  }

  /// Publish the position, last move and clock together, without a transient
  /// selection or a half-updated frame between turns.
  bool playMove(String from, String to, {String promotion = 'q'}) {
    if (rules.isOver ||
        clock.isFlagged ||
        clock.isPaused ||
        !rules.destinations(from).contains(to)) {
      return false;
    }
    _updatingPosition = true;
    try {
      final committed = clock.commitMove(
        movedWhite: rules.whiteToMove,
        applyMove: () => rules.move(from, to, promotion: promotion),
        gameEnded: () => rules.isOver,
      );
      if (committed) {
        lastFrom = from;
        lastTo = to;
        selected = null;
      } else if (clock.hasEnded) {
        selected = null;
      }
      return committed;
    } finally {
      _updatingPosition = false;
      notifyListeners();
    }
  }

  void undo() {
    if (!canUndo) return;
    _updatingPosition = true;
    try {
      rules.undo();
      clock.undoMove();
      selected = null;
      lastFrom = lastTo = null;
    } finally {
      _updatingPosition = false;
      notifyListeners();
    }
  }

  bool agreeDraw() {
    if (rules.isOver || clock.hasEnded) return false;
    _updatingPosition = true;
    try {
      if (!clock.endByAgreement()) return false;
      rules.agreeDraw();
      selected = null;
      return true;
    } finally {
      _updatingPosition = false;
      notifyListeners();
    }
  }

  bool resign({bool? white}) {
    if (rules.isOver || clock.hasEnded) return false;
    _updatingPosition = true;
    try {
      if (!clock.endByAgreement()) return false;
      rules.resign(white: white);
      selected = null;
      return true;
    } finally {
      _updatingPosition = false;
      notifyListeners();
    }
  }

  void reset() {
    _updatingPosition = true;
    try {
      rules.reset();
      clock.reset();
      selected = null;
      lastFrom = lastTo = null;
    } finally {
      _updatingPosition = false;
      notifyListeners();
    }
  }

  void flip() {
    flipped = !flipped;
    notifyListeners();
  }

  void _clockChanged() {
    if (_updatingPosition) return;
    if (clock.isPaused) selected = null;
    notifyListeners();
  }

  @override
  void dispose() {
    clock.removeListener(_clockChanged);
    clock.dispose();
    super.dispose();
  }
}
