import 'package:flutter/foundation.dart';

import '../domain/board_appearance.dart';

class BoardAppearanceController extends ChangeNotifier {
  BoardAppearanceController(this.repository, {BoardAppearance? initialValue})
      : value = initialValue ?? const BoardAppearance();
  final BoardAppearanceRepository repository;
  BoardAppearance value;
  Future<void> _pending = Future.value();
  Future<void> load() async {
    value = await repository.load();
  }

  // Apply patches inside the queue so rapid choices preserve one another.
  Future<void> update({
    BoardViewMode? view,
    BoardStyle? board,
    PieceStyle? pieces,
    BoardCamera? camera,
    PieceShape? shape,
    bool? showLegalMoves,
  }) {
    final operation = _pending.then((_) async {
      final next = value.copyWith(
        view: view,
        board: board,
        pieces: pieces,
        camera: camera,
        shape: shape,
        showLegalMoves: showLegalMoves,
      );
      if (next == value) return;
      await repository.save(next);
      value = next;
      notifyListeners();
    });
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }
}
